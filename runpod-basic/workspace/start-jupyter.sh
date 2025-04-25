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

log "Activating Jupyter venv..."
source /opt/venv/jupyter/bin/activate

log "Ensuring Jupyter directories exist..."
mkdir -p /root/.jupyter

# Configuración del tema oscuro
log "Setting JupyterLab dark theme..."
mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension
cat > /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings << EOL
{
   "theme": "JupyterLab Dark"
}
EOL

# Generate config only if it doesn't exist
if [ ! -f /root/.jupyter/jupyter_server_config.py ]; then
    log "Generating Jupyter server config..."
    jupyter lab --generate-config

    if [ -n "${JUPYTER_PASSWORD}" ]; then
        log "Setting Jupyter password..."
        PASSWD_HASH=$(python -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD}'))")
        cat > /root/.jupyter/jupyter_server_config.py << EOL
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_root = True
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = '${PASSWD_HASH}'
c.ServerApp.base_url = '/'
c.ServerApp.root_dir = '/'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.use_redirect_file = False
c.ServerApp.allow_headers = ['*']
c.ServerApp.allow_methods = ['*']
EOL
    else
        log_warning "JUPYTER_PASSWORD not set. Configuring Jupyter without password."
        cat > /root/.jupyter/jupyter_server_config.py << EOL
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_root = True
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.base_url = '/'
c.ServerApp.root_dir = '/'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.use_redirect_file = False
c.ServerApp.allow_headers = ['*']
c.ServerApp.allow_methods = ['*']
EOL
    fi
else
    log "Jupyter config file already exists."
fi

log "Changing directory to / ..."
cd /

log "Starting JupyterLab on port 8888..."
# Use exec to replace the current shell process
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*' --NotebookApp.allow_credentials=True