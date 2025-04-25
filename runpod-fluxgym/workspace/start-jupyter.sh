#!/bin/bash
set -e

# Función de logging
log() {
    echo "[$(date --iso-8601=seconds)] [start-jupyter.sh] $1"
}

# Función para configurar JupyterLab
setup_jupyter() {
    log "Iniciando setup_jupyter..."
    log "Activando venv /opt/venv/jupyter..."
    source /opt/venv/jupyter/bin/activate
    log "Venv activado."

    log "Asegurando directorio /root/.jupyter..."
    mkdir -p /root/.jupyter

    log "Configurando tema oscuro..."
    # Configuración del tema oscuro
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension
    cat > /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings << EOL
{
    "theme": "JupyterLab Dark"
}
EOL

    # Generar configuración solo si no existe
    log "Verificando archivo de configuración jupyter_server_config.py..."
    if [ ! -f /root/.jupyter/jupyter_server_config.py ]; then
        log "Generando configuración..."
        jupyter lab --generate-config
        log "Configuración generada."

        if [ -n "${JUPYTER_PASSWORD}" ]; then
            log "JUPYTER_PASSWORD detectada. Generando hash..."
            PASSWD_HASH=$(python -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD}'))")
            log "Hash generado. Escribiendo config con contraseña..."
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
            log "JUPYTER_PASSWORD no detectada. Escribiendo config sin contraseña..."
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
            log "ADVERTENCIA: No se ha establecido JUPYTER_PASSWORD, usando contraseña vacía"
        fi
    fi
    log "Archivo de configuración jupyter_server_config.py asegurado."

    log "Desactivando venv..."
    deactivate
    log "setup_jupyter completado."
}

# Función para iniciar JupyterLab
start_jupyter() {
    log "Iniciando start_jupyter..."
    log "Activando venv /opt/venv/jupyter..."
    source /opt/venv/jupyter/bin/activate
    log "Venv activado."

    # Verificar si el puerto está en uso
    log "Verificando puerto 8888..."
    if lsof -Pi :8888 -sTCP:LISTEN -t >/dev/null ; then
        log "Puerto 8888 en uso. Intentando liberar..."
        lsof -ti :8888 | xargs kill -9 || true
        sleep 2
    fi

    log "Cambiando directorio a /..."
    cd /
    log "Ejecutando jupyter lab..."
    # Los logs siguientes provendrán directamente de Jupyter Lab
    exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --NotebookApp.allow_origin='*' \
        --NotebookApp.allow_credentials=True
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
