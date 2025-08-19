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
    echo -e "${COLOR_CYAN}[${TIMESTAMP}] [ComfyUI-Starter]${COLOR_RESET} $1"
}
log_warning() {
    TIMESTAMP=$(date --iso-8601=seconds)
    echo -e "${COLOR_YELLOW}[${TIMESTAMP}] [ComfyUI-Starter] [WARNING]${COLOR_RESET} $1"
}
log_error() {
    TIMESTAMP=$(date --iso-8601=seconds)
    echo -e "${COLOR_RED}[${TIMESTAMP}] [ComfyUI-Starter] [ERROR]${COLOR_RESET} $1" >&2
}

# --- Configuration ---
VENV_PATH="/opt/venv_comfyui"
COMFYUI_DIR="/workspace/ComfyUI"
COMFYUI_TEMPLATE_DIR="/opt/ComfyUI"
MANAGER_DIR="${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager"
LISTEN_PORT="8188"

# --- Copy ComfyUI Source if Not Present ---
if [ ! -d "$COMFYUI_DIR" ]; then
    log "ComfyUI not found in /workspace. Copying from template..."
    cp -r "$COMFYUI_TEMPLATE_DIR" "$COMFYUI_DIR"
fi

# --- Install ComfyUI-Manager if Not Present ---
if [ ! -d "$MANAGER_DIR" ]; then
    log "ComfyUI-Manager not found. Installing from template..."
    cp -r "${COMFYUI_TEMPLATE_DIR}/custom_nodes/ComfyUI-Manager" "$MANAGER_DIR"
    log "ComfyUI-Manager installed."
else
    log "ComfyUI-Manager already exists. Skipping installation."
fi

# --- Activate Venv ---
log "Activating ComfyUI virtual environment from $VENV_PATH..."
source "$VENV_PATH/bin/activate"

# --- Configure Hugging Face Token ---
if [ -n "${HUGGINGFACE_TOKEN}" ]; then
    log "Configuring Hugging Face token..."
    mkdir -p /root/.huggingface
    echo -n "${HUGGINGFACE_TOKEN}" > /root/.huggingface/token
    log "Hugging Face token configured."
else
    log_warning "HUGGINGFACE_TOKEN not set. Some downloads might fail."
fi

# --- VRAM Mode Configuration ---
VRAM_ARGS=""
EFFECTIVE_VRAM_MODE="${COMFYUI_VRAM_MODE:-NORMAL_VRAM}" 

case "$EFFECTIVE_VRAM_MODE" in
    "HIGH_VRAM") VRAM_ARGS="--highvram";;
    "LOW_VRAM") VRAM_ARGS="--lowvram";;
    "NORMAL_VRAM") VRAM_ARGS="--normalvram";;
    "NO_VRAM" | "CPU") VRAM_ARGS="--cpu";;
    *)
        log_warning "Unrecognized COMFYUI_VRAM_MODE ('$EFFECTIVE_VRAM_MODE'). Defaulting to normalvram."
        VRAM_ARGS="--normalvram"
        ;;
esac
log "VRAM mode selected: $EFFECTIVE_VRAM_MODE"


# --- Check if Port is in Use ---
if lsof -Pi :${LISTEN_PORT} -sTCP:LISTEN -t >/dev/null ; then
    log_warning "Port ${LISTEN_PORT} is already in use. Attempting to kill process..."
    lsof -ti :${LISTEN_PORT} | xargs kill -9 || log_warning "Failed to kill process on port ${LISTEN_PORT}."
    sleep 2
fi

# --- Start ComfyUI ---
log "Starting ComfyUI on port ${LISTEN_PORT}..."
cd "$COMFYUI_DIR"
exec python main.py --listen 0.0.0.0 --port ${LISTEN_PORT} ${VRAM_ARGS}