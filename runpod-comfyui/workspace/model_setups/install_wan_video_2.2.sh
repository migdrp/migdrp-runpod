#!/bin/bash
set -e
log() { echo "[$(date --iso-8601=seconds)] [Wan Video 2.2 Installer] $1"; }
download_git_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    local repo_name=$(basename "$repo_url" .git)
    if [ ! -d "$dest_dir/$repo_name" ]; then
        log "Clonando $repo_name..."
        git clone "$repo_url" "$dest_dir/$repo_name"
    else
        log "Repositorio $repo_name ya existe. Omitiendo."
    fi
}
download_file() {
    local url="$1"
    local dest_dir="$2"
    local filename=$(basename "$url" | cut -d'?' -f1)
    mkdir -p "$dest_dir"
    if [ ! -f "$dest_dir/$filename" ]; then
        log "Descargando $filename a $dest_dir..."
        wget -c --show-progress -O "$dest_dir/$filename" "$url"
    else
        log "Archivo $filename ya existe. Omitiendo."
    fi
}

log "--- Iniciando la configuración para Wan Video 2.2 ---"

# --- 1. Nodos Personalizados Esenciales ---
CUSTOM_NODES_DIR="/workspace/ComfyUI/custom_nodes"
log "Descargando ComfyUI-Manager..."
download_git_repo https://github.com/ltdrdata/ComfyUI-Manager.git "$CUSTOM_NODES_DIR"

# --- 2. Modelos Wan 2.2 ---
MODELS_DIR="/workspace/models"
log "Descargando Modelos para Wan Video 2.2..."

# --- Modelos Unet (GGUF) ---
DIFFUSION_MODELS_DIR="$MODELS_DIR/diffusion_models"
log "Descargando Unets GGUF (Q4_K_M)..."
# Modelo High Noise (Text-to-Video)
download_file "https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-T2V-A14B-HighNoise-Q4_K_M.gguf" "$DIFFUSION_MODELS_DIR"
# Modelo Low Noise (Text-to-Video)
download_file "https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-T2V-A14B-LowNoise-Q4_K_M.gguf" "$DIFFUSION_MODELS_DIR"

# --- Text Encoder (CLIP) ---
TEXT_ENCODERS_DIR="$MODELS_DIR/text_encoders"
log "Descargando Text Encoder umt5..."
download_file "https://huggingface.co/Comfy-Org/Man_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$TEXT_ENCODERS_DIR"

# --- VAE ---
VAE_DIR="$MODELS_DIR/vae"
log "Descargando VAE..."
download_file "https://huggingface.co/Comfy-Org/Man_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "$VAE_DIR"

# --- LoRA ---
LORA_DIR="$MODELS_DIR/loras"
log "Descargando LoRA lightx2v..."
download_file "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors" "$LORA_DIR"

log "--- DESCARGA DE MODELOS COMPLETADA ---"
log "Ahora, reinicia ComfyUI ('supervisorctl restart comfyui') y carga tu workflow JSON."
log "ComfyUI-Manager te pedirá instalar los nodos que falten (como GGUF Loader y KJNodes)."