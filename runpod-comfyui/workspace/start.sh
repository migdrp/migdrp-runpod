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
    rm -f /var/run/supervisor.sock
    rm -f /var/run/supervisord.pid
    for port in 8888 7860 8188; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
            log_warning "Port $port is in use. Attempting to kill the process..."
            lsof -ti :$port | xargs kill -9 2>/dev/null || log_warning "Failed to kill process on port $port."
        fi
    done
    find /workspace -name "*.pyc" -delete 2>/dev/null || true
    find /workspace -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
}

# --- Fix Permissions (Optimized) ---
fix_permissions() {
    log "Verifying permissions..."
    local flag_file="/workspace/.permissions_ok"
    if [ -f "$flag_file" ]; then
        log "Permisos ya establecidos. Omitiendo."
        return
    fi
    log "Estableciendo permisos por primera vez (puede tardar un momento)..."
    mkdir -p /var/log/supervisor /workspace /workspace/models /workspace/custom_nodes /root/.jupyter
    chmod 755 /var/log/supervisor
    chmod -R 755 /opt/comfyui_env 2>/dev/null || true
    chmod -R 777 /workspace || log_warning "Could not chmod /workspace to 777."
    log "Permisos establecidos. Creando bandera para futuros inicios."
    touch "$flag_file"
}

# --- Setup Workspace (Surgical Overwrite Logic) ---
setup_workspace() {
    log "Setting up workspace and ensuring latest scripts..."
    if [ -d "/workspace_template" ]; then
        # Sobrescribe explícitamente los scripts de control principales.
        log "Overwriting startup scripts with the latest versions from the image..."
        cp /workspace_template/start.sh /workspace/start.sh
        cp /workspace_template/start-comfyui.sh /workspace/start-comfyui.sh
        cp /workspace_template/start-jupyter.sh /workspace/start-jupyter.sh
        
        # Copia la carpeta de model_setups, sobrescribiendo si existe.
        log "Updating model setup scripts..."
        cp -r /workspace_template/model_setups /workspace/

        # Asegura que todos los scripts sean ejecutables.
        chmod +x /workspace/*.sh 2>/dev/null || true
        chmod +x /workspace/model_setups/*.sh 2>/dev/null || true
    else
        log_warning "/workspace_template directory not found. Cannot copy initial scripts."
    fi
}

# --- Main Execution ---
main() {
    log "${COLOR_GREEN}Starting container initialization...${COLOR_RESET}"
    cleanup_stale_processes
    setup_workspace
    fix_permissions
    log "${COLOR_GREEN}Initialization complete.${COLOR_RESET}"
    case "$1" in
        "supervisor")
            log "Handing over control to supervisord..."
            exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
            ;;
        *)
            log "Executing command: $@"
            exec "$@"
            ;;
    esac
}

main "$@"