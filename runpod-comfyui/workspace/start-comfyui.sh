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

# --- Configuration ---
VENV_PATH="/opt/comfyui_env/venv"
COMFYUI_DIR="/workspace/ComfyUI"
COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI.git"
LISTEN_PORT="8188"

# --- Ensure Workspace Dirs Exist ---
# Although Dockerfile creates some, ensure they are writable if volume is reused
mkdir -p /workspace/custom_nodes
mkdir -p /workspace/models/checkpoints
mkdir -p /workspace/models/loras
mkdir -p /workspace/models/controlnet
mkdir -p /workspace/models/embeddings
mkdir -p /workspace/models/upscale_models
chmod -R 777 /workspace || true # Allow errors if root owns some subdirs initially

# --- Check if Venv Exists ---
if [ ! -d "$VENV_PATH" ]; then
    log_error "Pre-installed venv not found at $VENV_PATH. Cannot continue."
    exit 1
fi
log "Using pre-installed venv: $VENV_PATH"

# --- Clone or Update ComfyUI Source Code ---
if [ ! -d "$COMFYUI_DIR/.git" ]; then
    log "Cloning ComfyUI repository to $COMFYUI_DIR..."
    git clone "$COMFYUI_REPO" "$COMFYUI_DIR"
    cd "$COMFYUI_DIR"
else
    log "ComfyUI directory found. Checking for updates..."
    cd "$COMFYUI_DIR"
    git pull
fi

# --- Activate Venv ---
log "Activating venv..."
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

# --- Check if Port is in Use ---
if lsof -Pi :${LISTEN_PORT} -sTCP:LISTEN -t >/dev/null ; then
    log_warning "Port ${LISTEN_PORT} is already in use. Attempting to kill the process..."
    lsof -ti :${LISTEN_PORT} | xargs kill -9 || log_warning "Failed to kill process on port ${LISTEN_PORT}. ComfyUI might fail to start."
    sleep 2
fi

# --- Start ComfyUI ---
log "Starting ComfyUI on port ${LISTEN_PORT}..."
# Use exec to replace the current shell process with python
exec python main.py --listen 0.0.0.0 --port ${LISTEN_PORT}
