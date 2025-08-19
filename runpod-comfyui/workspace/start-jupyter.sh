#!/bin/bash
set -e

# Función de logging
log() {
    echo "[$(date --iso-8601=seconds)] $1"
}

# Función para configurar JupyterLab
setup_jupyter() {
    log "Configurando JupyterLab..."
    source /opt/comfyui_env/bin/activate

    mkdir -p /root/.jupyter

    # Configuración del tema oscuro
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension
    cat > /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings << EOL
{
    "theme": "JupyterLab Dark"
}
EOL

    # Generar configuración solo si no existe
    if [ ! -f /root/.jupyter/jupyter_server_config.py ]; then
        jupyter lab --generate-config

        if [ -n "${JUPYTER_PASSWORD}" ]; then
            PASSWD_HASH=$(python -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD}'))")
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
            log "ADVERTENCIA: No se ha establecido JUPYTER_PASSWORD, usando contraseña vacía"
        fi
    fi

    deactivate
}

# Función para iniciar JupyterLab
start_jupyter() {
    log "Iniciando JupyterLab..."
    source /opt/comfyui_env/bin/activate
    
    # Verificar si el puerto está en uso
    if lsof -Pi :8888 -sTCP:LISTEN -t >/dev/null ; then
        log "Puerto 8888 en uso. Intentando liberar..."
        lsof -ti :8888 | xargs kill -9 || true
        sleep 2
    fi

    cd /
    # El servidor usará automáticamente el archivo de configuración que creamos
    exec jupyter lab
}

# Función para limpiar al salir
cleanup() {
    log "Limpiando..."
    deactivate 2>/dev/null || true
}

# Registrar función de limpieza
trap cleanup EXIT

# Principal
main() {
    setup_jupyter
    start_jupyter
}

# Ejecutar script
main "$@"