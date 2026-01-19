#!/bin/bash

# ==============================================================================
# RunPod ComfyUI Auto-Installer: WanVideo & Utility Nodes
# ==============================================================================

# 1. BASE CONFIGURATION
BASE_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="${BASE_DIR}/custom_nodes"
MODELS_DIR="${BASE_DIR}/models"

# 2. DEFINE SUB-DIRECTORIES
# Mapping user categories to standard ComfyUI folders
DIFFUSION_MODELS_DIR="${MODELS_DIR}/diffusion_models"
LORA_DIR="${MODELS_DIR}/loras"
VAE_DIR="${MODELS_DIR}/vae"
CLIP_VISION_DIR="${MODELS_DIR}/clip_vision"
TEXT_ENCODER_DIR="${MODELS_DIR}/text_encoders"

# Ensure directories exist
mkdir -p "$DIFFUSION_MODELS_DIR" "$LORA_DIR" "$VAE_DIR" "$CLIP_VISION_DIR" "$TEXT_ENCODER_DIR"

echo "✅ Environment checked. Installing to: $BASE_DIR"

# ==============================================================================
# FUNCTION 1: INSTALL CUSTOM NODES
# ==============================================================================
install_node() {
    local url="$1"
    local dirname=$(basename "$url" .git)
    local target_dir="${CUSTOM_NODES_DIR}/${dirname}"

    echo "----------------------------------------------------------------"
    if [ -d "$target_dir" ]; then
        echo "⚠️  Node exists: $dirname. Updating..."
        cd "$target_dir" && git pull && cd ..
    else
        echo "⬇️  Cloning: $dirname..."
        git clone "$url" "$target_dir"
    fi

    # Auto-install requirements
    if [ -f "$target_dir/requirements.txt" ]; then
        echo "📦 Installing requirements for $dirname..."
        pip install -r "$target_dir/requirements.txt"
    fi
}

# ==============================================================================
# FUNCTION 2: DOWNLOAD MODELS
# ==============================================================================
download_model() {
    local url="$1"
    local dest_dir="$2"
    local filename="$3"
    local filepath="${dest_dir}/${filename}"

    if [ -f "$filepath" ]; then
        echo "⚠️  File exists: $filename (Skipping)"
    else
        echo "⬇️  Downloading: $filename..."
        # Using wget with quiet mode but showing progress bar
        wget -q --show-progress "$url" -O "$filepath"
        
        if [ $? -eq 0 ]; then
            echo "✅ Saved to: $dest_dir"
        else
            echo "❌ Failed to download: $filename"
        fi
    fi
}

# ==============================================================================
# STEP 3: EXECUTE INSTALLATION
# ==============================================================================

echo "🚀 --- INSTALLING CUSTOM NODES ---"

# 1. Segment Anything 2 (Kijai)
install_node "https://github.com/kijai/ComfyUI-segment-anything-2"

# 2. KJNodes (Essential utilities)
install_node "https://github.com/kijai/ComfyUI-KJNodes"

# 3. ControlNet Aux (Preprocessors)
install_node "https://github.com/Fannovel16/comfyui_controlnet_aux"


echo "🚀 --- DOWNLOADING MODELS ---"

# --- DIFFUSION MODELS (Wan2.1) ---
# Destination: models/diffusion_models
download_model \
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
    "$DIFFUSION_MODELS_DIR" \
    "Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

# --- LORAS ---
# Destination: models/loras
# 1. Lightx2v (Image to Video)
download_model \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
    "$LORA_DIR" \
    "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

# 2. Relight (WanAnimate)
download_model \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" \
    "$LORA_DIR" \
    "WanAnimate_relight_lora_fp16.safetensors"

# --- CLIP VISION ---
# Destination: models/clip_vision
download_model \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
    "$CLIP_VISION_DIR" \
    "clip_vision_h.safetensors"

# --- VAE ---
# Destination: models/vae
download_model \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "$VAE_DIR" \
    "wan_2.1_vae.safetensors"

# --- TEXT ENCODERS (T5) ---
# Destination: models/text_encoders
# Note: T5 XXL is large (~10GB+ sometimes), downloading to text_encoders is correct for Wan setups
download_model \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODER_DIR" \
    "umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# ==============================================================================
echo "🎉 Installation Complete! Please RESTART your ComfyUI session."
