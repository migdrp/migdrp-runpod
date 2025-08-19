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

# --- Configuration ---
VENV_PATH="/opt/comfyui_env"
COMFYUI_DIR="/workspace/ComfyUI"
COMFYUI_TEMPLATE_DIR="/opt/ComfyUI"
MANAGER_DIR="${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager"
LISTEN_PORT="8188"

# --- Ensure Workspace Dirs Exist ---
mkdir -p /workspace/custom_nodes
mkdir -p /workspace/models

# --- Copy ComfyUI Source if Not Present ---
if [ ! -d "$COMFYUI_DIR" ]; then
    log "ComfyUI no encontrado en /workspace. Copiando desde la plantilla..."
    cp -r "$COMFYUI_TEMPLATE_DIR" "$COMFYUI_DIR"
fi

# --- Install ComfyUI-Manager if Not Present ---
if [ ! -d "$MANAGER_DIR" ]; then
    log "ComfyUI-Manager no encontrado. Instalando..."
    # Clonamos la versión pre-instalada desde la plantilla para evitar dependencias de red
    # y asegurar que sea la misma versión que se probó con la imagen.
    cp -r "${COMFYUI_TEMPLATE_DIR}/custom_nodes/ComfyUI-Manager" "$MANAGER_DIR"
    log "ComfyUI-Manager instalado."
else
    log "ComfyUI-Manager ya existe. Omitiendo instalación."
fi

# --- Activate Venv ---
log "Activando venv desde $VENV_PATH..."
source "$VENV_PATH/bin/activate"

# --- Configure Hugging Face Token ---
if [ -n "${HUGGINGFACE_TOKEN}" ]; then
    log "Configurando Hugging Face token..."
    mkdir -p /root/.huggingface
    echo -n "${HUGGINGFACE_TOKEN}" > /root/.huggingface/token
    log "Hugging Face token configurado."
else
    log_warning "HUGGINGFACE_TOKEN not set. Some downloads might fail."
fi

# --- VRAM Mode Configuration ---
VRAM_ARGS=""
EFFECTIVE_VRAM_MODE="${COMFYUI_VRAM_MODE:-NORMAL_VRAM}" 

case "$EFFECTIVE_VRAM_MODE" in
    "LOW_VRAM") VRAM_ARGS="--lowvram";;
    "NORMAL_VRAM") VRAM_ARGS="--normalvram";;
    "NO_VRAM" | "CPU") VRAM_ARGS="--cpu";;
    *)
        log_warning "Valor de COMFYUI_VRAM_MODE no reconocido ('$EFFECTIVE_VRAM_MODE'). Usando normalvram."
        VRAM_ARGS="--normalvram"
        ;;
esac
log "Modo de VRAM seleccionado: $EFFECTIVE_VRAM_MODE"


# --- Check if Port is in Use ---
if lsof -Pi :${LISTEN_PORT} -sTCP:LISTEN -t >/dev/null ; then
    log_warning "Port ${LISTEN_PORT} is already in use. Intentando matar el proceso..."
    lsof -ti :${LISTEN_PORT} | xargs kill -9 || log_warning "Fallo al matar el proceso en el puerto ${LISTEN_PORT}."
    sleep 2
fi

# --- Start ComfyUI ---
log "Iniciando ComfyUI en el puerto ${LISTEN_PORT}..."
cd "$COMFYUI_DIR"
exec python main.py --listen 0.0.0.0 --port ${LISTEN_PORT} ${VRAM_ARGS}