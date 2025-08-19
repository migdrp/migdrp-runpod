#!/bin/bash
set -e

# --- Configuration ---
VENV_PATH="/opt/venv_jupyter"
JUPYTER_EXECUTABLE="$VENV_PATH/bin/jupyter"
PYTHON_EXECUTABLE="$VENV_PATH/bin/python"

# --- Logging Function ---
log() {
    echo "[$(date --iso-8601=seconds)] [Jupyter-Starter] $1"
}

# --- Setup JupyterLab ---
setup_jupyter() {
    log "Configuring JupyterLab using venv at $VENV_PATH..."
    mkdir -p /root/.jupyter

    # Dark theme configuration
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension
    cat > /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings << EOL
{
    "theme": "JupyterLab Dark"
}
EOL

    # Generate config only if it doesn't exist
    if [ ! -f /root/.jupyter/jupyter_server_config.py ]; then
        log "Generating new Jupyter server config..."
        $JUPYTER_EXECUTABLE lab --generate-config

        if [ -n "${JUPYTER_PASSWORD}" ]; then
            log "Setting JUPYTER_PASSWORD..."
            PASSWD_HASH=$($PYTHON_EXECUTABLE -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD}'))")
            cat > /root/.jupyter/jupyter_server_config.py << EOL
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_root = True
c.ServerApp.open_browser = False
c.IdentityProvider.token = ''
c.PasswordIdentityProvider.hashed_password = '${PASSWD_HASH}'
c.ServerApp.base_url = '/'
c.ServerApp.root_dir = '/'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
EOL
        else
            log "WARNING: JUPYTER_PASSWORD not set, using empty password."
            cat > /root/.jupyter/jupyter_server_config.py << EOL
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_root = True
c.ServerApp.open_browser = False
c.IdentityProvider.token = ''
c.PasswordIdentityProvider.hashed_password = ''
c.ServerApp.base_url = '/'
c.ServerApp.root_dir = '/'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
EOL
        fi
    else
        log "Jupyter server config already exists. Skipping generation."
    fi
}

# --- Start JupyterLab ---
start_jupyter() {
    log "Starting JupyterLab server..."
    
    # Check if port is in use
    if lsof -Pi :8888 -sTCP:LISTEN -t >/dev/null ; then
        log "Port 8888 is in use. Attempting to free it..."
        lsof -ti :8888 | xargs kill -9 || true
        sleep 2
    fi

    cd /
    # The server will automatically use the config file we created
    exec $JUPYTER_EXECUTABLE lab
}

# --- Main Execution ---
main() {
    setup_jupyter
    start_jupyter
}

main "$@"