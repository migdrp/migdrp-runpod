#!/bin/bash
set -e

# --- Códigos de Color ANSI ---
RESET='\033[0m'
BOLD='\033[1m'
# Colores de Texto
CYAN='\033[0;36m'
YELLOW='\033[0;33m' # Para advertencias
RED='\033[0;31m'    # Para errores
GREEN='\033[0;32m'  # Para éxito (opcional)

# Función de logging con colores
log() {
    echo -e "${CYAN}[$(date --iso-8601=seconds)]${RESET} $1"
}
# Funciones específicas para niveles (opcional, pero útil)
log_warn() {
    echo -e "${YELLOW}[$(date --iso-8601=seconds)] WARN: $1${RESET}"
}
log_error() {
    echo -e "${RED}[$(date --iso-8601=seconds)] ERROR: $1${RESET}"
}
log_success() {
    echo -e "${GREEN}[$(date --iso-8601=seconds)] SUCCESS: $1${RESET}"
}


# Limpieza de procesos y archivos de bloqueo antiguos
cleanup_stale_processes() {
    log "Limpiando procesos antiguos..."
    
    # Limpiar archivos de socket y pid antiguos de supervisor
    rm -f /var/run/supervisor.sock
    rm -f /var/run/supervisord.pid
    
    # Verificar y liberar puertos si están en uso
    for port in 8888 7860 7861; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
            log "Liberando puerto $port..."
            lsof -ti :$port | xargs kill -9 2>/dev/null || true
        fi
    done
    
    # Limpiar archivos temporales de Python
    find /workspace -name "*.pyc" -delete
    find /workspace -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    log "Limpieza completada."
}

# Verificar y reparar permisos
fix_permissions() {
    log "Verificando permisos (inicio)..."

    # Asegurar que los directorios existen
    log "Asegurando directorios base..."
    mkdir -p /var/log/supervisor
    mkdir -p /workspace
    mkdir -p /workspace/models
    mkdir -p /workspace/datasets
    mkdir -p /root/.jupyter
    log "Directorios base asegurados."

    # Establecer permisos correctos
    log "Estableciendo permisos para /var/log/supervisor..."
    chmod 755 /var/log/supervisor
    log "Estableciendo permisos para /opt/venv/jupyter..."
    chmod -R 755 /opt/venv/jupyter 2>/dev/null || true # Re-added error suppression
    log "Estableciendo permisos para /workspace (esto puede tardar)..."
    chmod -R 777 /workspace
    log "Permisos verificados/corregidos (fin)."
}

# Verificar y restaurar archivos de workspace
setup_workspace() {
    log "Configurando workspace..."
    
    if [ -d "/workspace_template" ]; then
        log "Verificando archivos nuevos para copiar..."
        for file in /workspace_template/*; do
            basename=$(basename "$file")
            if [ ! -e "/workspace/$basename" ]; then
                log "Copiando archivo nuevo: $basename"
                cp -r "$file" "/workspace/"
                chmod -R 777 "/workspace/$basename"
            fi
        done
        
        log "Eliminando carpeta template..."
        # rm -rf /workspace_template # Comentado: No eliminar la carpeta montada como read-only
    fi
    log "Configuración de workspace completada."
}

# Verificar estado de entornos virtuales
check_venvs() {
    log "Verificando entornos virtuales..."
    
    # Verificar venv de Jupyter
    if [ ! -f "/opt/venv/jupyter/bin/activate" ]; then
        log "Recreando entorno virtual de Jupyter..."
        python -m venv /opt/venv/jupyter
        source /opt/venv/jupyter/bin/activate
        pip install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor
        deactivate
    fi
    log "Verificación de entornos virtuales completada."
}

main() {
    log "Iniciando sistema..."
    
    # Ejecutar funciones de preparación
    cleanup_stale_processes
    fix_permissions
    setup_workspace
    check_venvs

    log "Preparación inicial completada."

    case "$1" in
        "supervisor")
            log "Lanzando Supervisor. Los siguientes logs provendrán de Supervisor y los servicios gestionados (ttyd, jupyter, fluxgym)..."
            # Nota: Logs después de este punto vendrán de supervisord y sus procesos gestionados
            exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
            ;;
        *)
            log "Iniciando bash..."
            exec bash
            ;;
    esac
}

# Ejecutar script principal
main "$@"
