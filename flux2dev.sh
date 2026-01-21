#!/bin/bash

# ==============================================================================
# FLUX 2 INSTALLER
# ==============================================================================

# 1. Install aria2 for speed
apt-get update && apt-get install -y aria2

# 2. Detect Path (Fixes the "wrong folder" issue)
if [ -d "/workspace/runpod-slim/ComfyUI" ]; then
    BASE_DIR="/workspace/runpod-slim/ComfyUI"
elif [ -d "/workspace/ComfyUI" ]; then
    BASE_DIR="/workspace/ComfyUI"
else
    # Fallback to current directory
    BASE_DIR="$(pwd)/ComfyUI"
fi

echo "📍 Using ComfyUI Path: $BASE_DIR"

MODELS_DIR="${BASE_DIR}/models"

# Define Directories
DIFFUSION_MODELS_DIR="${MODELS_DIR}/diffusion_models"
VAE_DIR="${MODELS_DIR}/vae"
TEXT_ENCODER_DIR="${MODELS_DIR}/text_encoders"

# Create directories (Removed LoRA/ClipVision as they weren't in your request)
mkdir -p "$DIFFUSION_MODELS_DIR" "$VAE_DIR" "$TEXT_ENCODER_DIR"

# ------------------------------------------------------------------------------
# 1. FAST DOWNLOAD FUNCTION
# ------------------------------------------------------------------------------
fast_download() {
    local url="$1"
    local dest_dir="$2"
    local filename="$3"
    local filepath="${dest_dir}/${filename}"

    if [ -f "$filepath" ]; then
        echo "⚠️  File exists: $filename (Skipping)"
    else
        echo "⬇️  Downloading: $filename..."
        aria2c --console-log-level=error -c -x 16 -s 16 -k 1M "$url" -d "$dest_dir" -o "$filename"
    fi
}

# ==============================================================================
# EXECUTION
# ==============================================================================

echo "🚀 --- DOWNLOADING FLUX 2 MODELS ---"

# Text Encoder
fast_download "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors" "$TEXT_ENCODER_DIR" "mistral_3_small_flux2_bf16.safetensors"

# Diffusion Model
fast_download "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors" "$DIFFUSION_MODELS_DIR" "flux2_dev_fp8mixed.safetensors"

# VAE
fast_download "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" "$VAE_DIR" "flux2-vae.safetensors"

echo "✅ DONE! Please restart ComfyUI to load the new models."
