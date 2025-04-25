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
    # Usamos -e para interpretar las secuencias de escape ANSI
    # Mantenemos el identificador [start-fluxgym.sh]
    echo -e "${CYAN}[$(date --iso-8601=seconds)]${RESET} [start-fluxgym.sh] $1"
}
# Funciones específicas para niveles (opcional, pero útil)
log_warn() {
    echo -e "${YELLOW}[$(date --iso-8601=seconds)]${RESET} [start-fluxgym.sh] ${YELLOW}WARN: $1${RESET}"
}
log_error() {
    echo -e "${RED}[$(date --iso-8601=seconds)]${RESET} [start-fluxgym.sh] ${RED}ERROR: $1${RESET}"
}
log_success() {
    echo -e "${GREEN}[$(date --iso-8601=seconds)]${RESET} [start-fluxgym.sh] ${GREEN}SUCCESS: $1${RESET}"
}

# Verificar variables de entorno relevantes
log "--- Variables de entorno GRADIO ---"
printenv | grep GRADIO || log "No se encontraron variables GRADIO."
log "--- Fin Variables de entorno ---"


# Función para iniciar FluxGym (Asumiendo que todo está preinstalado en /opt/fluxgym_env)
start_fluxgym() {
    log "Iniciando start_fluxgym (usando entorno pre-instalado en /opt/fluxgym_env)..."

    # Directorio del venv pre-construido
    VENV_PATH="/opt/fluxgym_env/venv"
    # Directorio de trabajo para FluxGym (donde clonaremos el código fuente)
    FLUXGYM_WORKSPACE="/workspace/fluxgym"

    log "Verificando existencia del venv pre-instalado en ${VENV_PATH}..."
    if [ ! -f "${VENV_PATH}/bin/activate" ]; then
        log "ERROR: El script de activación del venv pre-instalado (${VENV_PATH}/bin/activate) no se encontró."
        log "       Esto indica un problema con el build de la imagen Docker. Verifica los pasos de pre-instalación en el Dockerfile."
        exit 1
    fi
    log "Venv pre-instalado encontrado."

    log "Asegurando directorio de trabajo ${FLUXGYM_WORKSPACE}..."
    mkdir -p "${FLUXGYM_WORKSPACE}"
    cd "${FLUXGYM_WORKSPACE}"

    # Clonar/Actualizar FluxGym y sd-scripts en el volumen persistente /workspace
    # Esto permite al usuario modificar el código si lo desea, sin afectar el venv pre-construido.
    log "Verificando/Actualizando código fuente de FluxGym..."
    if [ ! -d ".git" ]; then
        log "Clonando repositorio FluxGym en ${FLUXGYM_WORKSPACE}..."
        # Clonar solo el contenido, sin crear subdirectorio fluxgym dentro de fluxgym
        git clone https://github.com/cocktailpeanut/fluxgym.git .
    else
        log "Actualizando repositorio FluxGym..."
        git pull
    fi

    log "Verificando/Actualizando código fuente de sd-scripts..."
    if [ ! -d "sd-scripts/.git" ]; then
        log "Clonando repositorio sd-scripts en ${FLUXGYM_WORKSPACE}/sd-scripts..."
        # Asegurarse de que el directorio exista antes de clonar dentro
        mkdir -p sd-scripts
        git clone -b sd3 https://github.com/kohya-ss/sd-scripts.git sd-scripts
    else
        log "Actualizando repositorio sd-scripts..."
        cd sd-scripts
        git pull
        cd ..
    fi

    log "Activando venv pre-instalado (${VENV_PATH})..."
    source "${VENV_PATH}/bin/activate"
    log "Venv activado. Python: $(which python)"

    # Configurar Hugging Face token si está disponible (esto sí es dinámico)
    log "Verificando HUGGINGFACE_TOKEN..."
    if [ -n "${HUGGINGFACE_TOKEN}" ]; then
        log "Configurando Hugging Face token..."
        # Usar /root como HOME ya que supervisord corre como root por defecto
        HF_DIR="/root/.huggingface"
        mkdir -p "$HF_DIR"
        echo "${HUGGINGFACE_TOKEN}" > "$HF_DIR/token"
        log "Token de Hugging Face configurado en $HF_DIR/token"
    fi

    # Modificar app.py para puerto y share (hacerlo aquí asegura que usemos la última versión del repo)
    log "Verificando/Configurando app.py para acceso externo (puerto 7861, share=True)..."
    if [ -f "app.py" ]; then
        # Verificar si ya está modificado para evitar aplicar sed múltiples veces
        if ! grep -q "server_port=7861" app.py || ! grep -q "share=True" app.py ; then
            log "Modificando app.py para puerto 7861 y share=True..."
            # Estrategia aún más robusta: Buscar línea que empieza con 'demo.launch(' ignorando espacios
            # Patrón: ^[[:space:]]*demo\.launch(
            # ^ : inicio de línea
            # [[:space:]]* : cero o más espacios/tabulaciones
            # demo\.launch( : texto literal (escapando el punto)
            if grep -q "^[[:space:]]*demo\.launch(" app.py; then
                log "Encontrada línea con demo.launch(). Reemplazando..."
                # Usar 'c\' para reemplazar toda la línea encontrada
                # Asegurarse de que la línea de reemplazo tenga la indentación correcta si es necesario
                # INTENTO: Forzar escucha en 0.0.0.0, usar puerto 7862 Y REHABILITAR share=True
                sed -i '/^[[:space:]]*demo\.launch(/c\    demo.launch(server_name="0.0.0.0", server_port=7862, share=True, debug=True, show_error=True, allowed_paths=[cwd])' app.py
            else
                 log "WARN: No se encontró línea que comience con demo.launch() en app.py."
            fi

            # Verificar si se aplicó y mostrar contenido
            log "--- Contenido de app.py después de intentar modificar: ---"
            cat app.py || log "WARN: No se pudo mostrar app.py"
            log "--- Fin contenido app.py ---"
            if grep -q "server_port=7861" app.py; then
                 log "app.py parece modificado correctamente."
            else
                 log "WARN: No se encontró 'server_port=7861' en app.py después de sed. La modificación pudo fallar."
            fi
        else
            log "app.py ya está configurado."
        fi
    else
        log "WARN: app.py no encontrado en ${FLUXGYM_WORKSPACE}. No se puede configurar el puerto/share."
    fi


    # Verificar si el puerto está en uso
    log "Verificando puerto 7862..."
    if lsof -Pi :7862 -sTCP:LISTEN -t >/dev/null ; then
        log "Puerto 7862 en uso. Intentando liberar..."
        # Usar pkill puede ser más efectivo si el proceso es persistente
        pkill -f "app.py" || true # Intenta matar cualquier proceso python ejecutando app.py
        sleep 2
        if lsof -Pi :7862 -sTCP:LISTEN -t >/dev/null ; then
           log "WARN: No se pudo liberar el puerto 7862."
        fi
    fi

    log "Ejecutando FluxGym (python app.py sin exec)..."
    # Los logs siguientes provendrán directamente de FluxGym/Gradio/Flask
    # Quitamos 'exec' para ver si Supervisor maneja mejor el proceso
    python app.py
}

# Función para limpiar al salir (puede ser útil si no usamos exec)
# cleanup() {
#     log "Limpiando..."
# }
# trap cleanup EXIT # No registrar si usamos exec

# Principal
main() {
    log "Iniciando script principal (modo pre-instalado)..."
    # Ya no necesitamos setup_directories o check_installation aquí
    # setup_directories podría moverse a start.sh si es necesario para otros servicios
    start_fluxgym
}

# Ejecutar script
main "$@"
