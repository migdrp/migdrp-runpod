#!/bin/bash

# Function for logging
log() {
    echo "[$(date --iso-8601=seconds)] $1"
}

# Function to download a file if it doesn't exist
download_file() {
    local url="$1"
    local dest_dir="$2"
    local filename=$(basename "$url")
    local dest_path="$dest_dir/$filename"

    mkdir -p "$dest_dir"

    if [ -f "$dest_path" ]; then
        log "Skipping download: $filename already exists in $dest_dir"
    else
        log "Downloading $filename to $dest_dir..."
        wget -q --show-progress -O "$dest_path" "$url"
        if [ $? -eq 0 ]; then
            log "Successfully downloaded $filename."
        else
            log "ERROR: Failed to download $filename from $url."
            # Optionally remove partial download
            # rm -f "$dest_path"
        fi
    fi
}

# --- Configuration ---
# Base directory for models within the workspace
MODELS_BASE_DIR="/workspace/models"

# Define target directories
CHECKPOINTS_DIR="$MODELS_BASE_DIR/checkpoints"
VAE_DIR="$MODELS_BASE_DIR/vae"
CLIP_L_DIR="$MODELS_BASE_DIR/clip_l"
CLIP_G_DIR="$MODELS_BASE_DIR/clip_g"
T5_XXL_DIR="$MODELS_BASE_DIR/t5xxl"

# --- Model URLs (Replace with actual URLs as needed) ---

# Stable Diffusion 3 Medium (Example - Use official links when available)
# Replace with the actual URL for sd3_medium_incl_clips_t5xxlfp16.safetensors or similar
SD3_MEDIUM_URL="https://huggingface.co/stabilityai/stable-diffusion-3-medium-diffusers/resolve/main/sd3_medium_incl_clips_t5xxlfp16.safetensors?download=true"

# VAE (Example: SDXL VAE, often works well)
# Replace if a specific SD3 VAE is required/preferred
VAE_URL="https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors?download=true"

# Text Encoders (Usually included in the main SD3 checkpoint, but define if separate files are needed)
# CLIP_L_URL="URL_FOR_CLIP_L_MODEL"
# CLIP_G_URL="URL_FOR_CLIP_G_MODEL"
# T5_XXL_URL="URL_FOR_T5_XXL_MODEL"

# --- Main Download Logic ---

log "Starting model download process..."

# Download Checkpoint
if [ -n "$SD3_MEDIUM_URL" ]; then
    download_file "$SD3_MEDIUM_URL" "$CHECKPOINTS_DIR"
else
    log "WARN: SD3_MEDIUM_URL is not set. Skipping checkpoint download."
fi

# Download VAE
if [ -n "$VAE_URL" ]; then
    download_file "$VAE_URL" "$VAE_DIR"
else
    log "WARN: VAE_URL is not set. Skipping VAE download."
fi

# Download Text Encoders (Uncomment and set URLs if needed separately)
# if [ -n "$CLIP_L_URL" ]; then
#     download_file "$CLIP_L_URL" "$CLIP_L_DIR"
# else
#     log "INFO: CLIP_L_URL not set or not needed separately."
# fi
#
# if [ -n "$CLIP_G_URL" ]; then
#     download_file "$CLIP_G_URL" "$CLIP_G_DIR"
# else
#     log "INFO: CLIP_G_URL not set or not needed separately."
# fi
#
# if [ -n "$T5_XXL_URL" ]; then
#     download_file "$T5_XXL_URL" "$T5_XXL_DIR"
# else
#     log "INFO: T5_XXL_URL not set or not needed separately."
# fi

log "Model download process finished."
echo "-----------------------------------------------------"
echo " Ensure model paths are correctly configured in FluxGym UI or config files."
echo " Checkpoint expected in: $CHECKPOINTS_DIR"
echo " VAE expected in: $VAE_DIR"
echo "-----------------------------------------------------"