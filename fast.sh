#!/bin/bash

# ==============================================================================
# UPDATED RUNPOD INSTALLER + DWPREPROCESSOR FIX
# ==============================================================================

# 1. Install aria2 for speed
apt-get update && apt-get install -y aria2

# 2. Detect Path (Fixes the "wrong folder" issue)
# checks if we are in runpod-slim and adjusts
if [ -d "/workspace/runpod-slim/ComfyUI" ]; then
    BASE_DIR="/workspace/runpod-slim/ComfyUI"
elif [ -d "/workspace/ComfyUI" ]; then
    BASE_DIR="/workspace/ComfyUI"
else
    # Fallback to current directory
    BASE_DIR="$(pwd)/ComfyUI"
fi

echo "📍 Using ComfyUI Path: $BASE_DIR"

CUSTOM_NODES_DIR="${BASE_DIR}/custom_nodes"
MODELS_DIR="${BASE_DIR}/models"

# Define Directories
DIFFUSION_MODELS_DIR="${MODELS_DIR}/diffusion_models"
LORA_DIR="${MODELS_DIR}/loras"
VAE_DIR="${MODELS_DIR}/vae"
CLIP_VISION_DIR="${MODELS_DIR}/clip_vision"
TEXT_ENCODER_DIR="${MODELS_DIR}/text_encoders"

# Create directories
mkdir -p "$DIFFUSION_MODELS_DIR" "$LORA_DIR" "$VAE_DIR" "$CLIP_VISION_DIR" "$TEXT_ENCODER_DIR"

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

# ------------------------------------------------------------------------------
# 2. NODE INSTALLATION + FIXES
# ------------------------------------------------------------------------------
install_node() {
    local url="$1"
    local dirname=$(basename "$url" .git)
    local target_dir="${CUSTOM_NODES_DIR}/${dirname}"

    if [ -d "$target_dir" ]; then
        echo "🔄 Updating: $dirname..."
        cd "$target_dir" && git pull && cd ..
    else
        echo "⬇️  Cloning: $dirname..."
        git clone "$url" "$target_dir"
    fi

    # STANDARD REQUIREMENTS
    if [ -f "$target_dir/requirements.txt" ]; then
        echo "📦 Installing requirements for $dirname..."
        pip install -r "$target_dir/requirements.txt"
    fi

    # --- SPECIFIC FIX FOR CONTROLNET AUX (DWPREPROCESSOR) ---
    if [ "$dirname" == "comfyui_controlnet_aux" ]; then
        echo "🛠️  Applying FIX for DWPreprocessor (Mediapipe)..."
        pip install mediapipe opencv-python-headless
    fi
}

# ==============================================================================
# EXECUTION
# ==============================================================================

echo "🚀 --- INSTALLING & FIXING NODES ---"
install_node "https://github.com/kijai/ComfyUI-segment-anything-2"
install_node "https://github.com/kijai/ComfyUI-KJNodes"
install_node "https://github.com/Fannovel16/comfyui_controlnet_aux"

echo "🚀 --- CHECKING MODELS ---"
# Wan2.1 Diffusion Model
fast_download "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" "$DIFFUSION_MODELS_DIR" "Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

# LoRAs
fast_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" "$LORA_DIR" "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
fast_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" "$LORA_DIR" "WanAnimate_relight_lora_fp16.safetensors"

# Clip Vision
fast_download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "$CLIP_VISION_DIR" "clip_vision_h.safetensors"

# VAE
fast_download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "$VAE_DIR" "wan_2.1_vae.safetensors"

# Text Encoder
fast_download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$TEXT_ENCODER_DIR" "umt5_xxl_fp8_e4m3fn_scaled.safetensors"

echo "✅ DONE! You MUST restart the Pod (or the ComfyUI process) for the fixes to apply."
