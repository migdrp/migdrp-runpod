#!/bin/bash
set -e

# --- Colors for Logging ---
COLOR_RESET='\033[0m'
COLOR_CYAN='\033[0;36m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'

# --- Logging Function ---
log() {
    TIMESTAMP=$(date --iso-8601=seconds)
    # Use -e to enable interpretation of backslash escapes (for colors)
    echo -e "${COLOR_CYAN}[${TIMESTAMP}]${COLOR_RESET} $1"
}
log_warning() {
    TIMESTAMP=$(date --iso-8601=seconds)
    echo -e "${COLOR_YELLOW}[${TIMESTAMP}] [WARNING]${COLOR_RESET} $1"
}
log_error() {
    TIMESTAMP=$(date --iso-8601=seconds)
    echo -e "${COLOR_RED}[${TIMESTAMP}] [ERROR]${COLOR_RESET} $1" >&2
}

# --- Cleanup Stale Processes and Locks ---
cleanup_stale_processes() {
    log "Cleaning up stale processes and locks..."

    # Clean up supervisor socket and pid files
    rm -f /var/run/supervisor.sock
    rm -f /var/run/supervisord.pid

    # Check and kill processes on standard ports if they are listening
    for port in 8888 7860 8188; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
            log_warning "Port $port is in use. Attempting to kill the process..."
            lsof -ti :$port | xargs kill -9 2>/dev/null || log_warning "Failed to kill process on port $port."
        fi
    done

    # Clean up Python cache files (optional, can help in some cases)
    find /workspace -name "*.pyc" -delete 2>/dev/null || true
    find /workspace -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
}

# --- Fix Permissions ---
fix_permissions() {
    log "Verifying and setting permissions..."

    # Ensure essential directories exist
    mkdir -p /var/log/supervisor
    mkdir -p /workspace
    mkdir -p /workspace/models # Ensure base models dir exists
    mkdir -p /workspace/custom_nodes # Ensure base custom_nodes dir exists
    mkdir -p /root/.jupyter

    # Set permissions
    chmod 755 /var/log/supervisor
    chmod -R 755 /opt/venv/jupyter 2>/dev/null || true # Jupyter venv
    chmod -R 755 /opt/comfyui_env 2>/dev/null || true # ComfyUI pre-built venv
    chmod -R 777 /workspace || log_warning "Could not chmod /workspace to 777. This might cause issues if volume is mounted with restrictive permissions."
}

# --- Setup Workspace: Copy Initial Scripts if Missing ---
setup_workspace() {
    log "Setting up workspace..."

    if [ -d "/workspace_template" ]; then
        log "Checking for missing scripts in /workspace to copy from /workspace_template..."
        # Copy files from /workspace_template to /workspace only if they don't exist in /workspace
        find /workspace_template -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
            basename=$(basename "$file")
            if [ ! -e "/workspace/$basename" ]; then
                log "Copying initial script: $basename to /workspace/"
                cp "$file" "/workspace/"
                chmod 777 "/workspace/$basename" # Ensure script is executable in volume
            fi
        done
        # Note: We DO NOT remove /workspace_template as it's mounted read-only
    else
        log_warning "/workspace_template directory not found. Cannot copy initial scripts."
    fi
}

# --- Check Jupyter Venv ---
check_jupyter_venv() {
    log "Checking Jupyter virtual environment..."
    JUPYTER_VENV_PATH="/opt/venv/jupyter"

    if [ ! -f "$JUPYTER_VENV_PATH/bin/activate" ]; then
        log_warning "Jupyter venv activation script not found! Recreating venv..."
        rm -rf "$JUPYTER_VENV_PATH"
        python -m venv "$JUPYTER_VENV_PATH"
        chmod -R 755 "$JUPYTER_VENV_PATH"
        log "Installing JupyterLab in new venv..."
        "$JUPYTER_VENV_PATH/bin/pip" install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor
        log "Jupyter venv recreated."
    else
        log "Jupyter venv found."
    fi
}

# --- Main Execution ---
main() {
    log "${COLOR_GREEN}Starting container initialization...${COLOR_RESET}"

    # Run preparation steps
    cleanup_stale_processes
    fix_permissions
    setup_workspace
    check_jupyter_venv

    log "${COLOR_GREEN}Initialization complete.${COLOR_RESET}"

    # Execute the command passed to the script (e.g., "supervisor" or "bash")
    case "$1" in
        "supervisor")
            log "Handing over control to supervisord..."
            # Use exec to replace the shell process with supervisord
            exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
            ;;
        *)
            log "Executing command: $@"
            exec "$@"
            ;;
    esac
}

# --- Run Main Function ---
# Pass all script arguments to the main function
main "$@"
