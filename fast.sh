# 1. Install aria2 (Required for fast downloads)
apt-get update && apt-get install -y aria2

# 2. Create the script with the CORRECT path for your setup
cat << 'EOF' > fast_wan_corrected.sh
#!/bin/bash

# --- PATH CORRECTION FOR YOUR SETUP ---
# We use $(pwd) so it works exactly where you are inside 'runpod-slim'
BASE_DIR="$(pwd)/ComfyUI" 
echo "📍 Detected Install Path: $BASE_DIR"

CUSTOM_NODES_DIR="${BASE_DIR}/custom_nodes"
MODELS_DIR="${BASE_DIR}/models"

# Define Directories
DIFFUSION_MODELS_DIR="${MODELS_DIR}/diffusion_models"
LORA_DIR="${MODELS_DIR}/loras"
VAE_DIR="${MODELS_DIR}/vae"
CLIP_VISION_DIR="${MODELS_DIR}/clip_vision"
TEXT_ENCODER_DIR="${MODELS_DIR}/text_encoders"

# Create directories if they don't exist
mkdir -p "$DIFFUSION_MODELS_DIR" "$LORA_DIR" "$VAE_DIR" "$CLIP_VISION_DIR" "$TEXT_ENCODER_DIR"

# ------------------------------------------------------------------------------
# FAST DOWNLOAD FUNCTION (ARIA2)
# ------------------------------------------------------------------------------
fast_download() {
    local url="$1"
    local dest_dir="$2"
    local filename="$3"
    local filepath="${dest_dir}/${filename}"

    if [ -f "$filepath" ]; then
        echo "⚠️  File exists: $filename (Skipping)"
    else
        echo "⬇️  Downloading (FAST): $filename..."
        # 16 connections per file for max speed
        aria2c --console-log-level=error -c -x 16 -s 16 -k 1M "$url" -d "$dest_dir" -o "$filename"
        
        if [ $? -eq 0 ]; then
            echo "✅ Finished: $filename"
        else
            echo "❌ Failed: $filename"
        fi
    fi
}

install_node() {
    local url="$1"
    local dirname=$(basename "$url" .git)
    local target_dir="${CUSTOM_NODES_DIR}/${dirname}"

    if [ -d "$target_dir" ]; then
        echo "⚠️  Node exists: $dirname. Updating..."
        cd "$target_dir" && git pull && cd ..
    else
        echo "⬇️  Cloning: $dirname..."
        git clone "$url" "$target_dir"
    fi

    if [ -f "$target_dir/requirements.txt" ]; then
        echo "📦 Installing requirements for $dirname..."
        pip install -r "$target_dir/requirements.txt"
    fi
}

# ==============================================================================
# EXECUTION
# ==============================================================================

echo "🚀 --- INSTALLING NODES ---"
install_node "https://github.com/kijai/ComfyUI-segment-anything-2"
install_node "https://github.com/kijai/ComfyUI-KJNodes"
install_node "https://github.com/Fannovel16/comfyui_controlnet_aux"

echo "🚀 --- FAST DOWNLOADING MODELS (70GB+) ---"

# Diffusion Model (~14GB)
fast_download "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" "$DIFFUSION_MODELS_DIR" "Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

# LoRAs
fast_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" "$LORA_DIR" "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
fast_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" "$LORA_DIR" "WanAnimate_relight_lora_fp16.safetensors"

# Clip Vision
fast_download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "$CLIP_VISION_DIR" "clip_vision_h.safetensors"

# VAE
fast_download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "$VAE_DIR" "wan_2.1_vae.safetensors"

# Text Encoder (~10GB)
fast_download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$TEXT_ENCODER_DIR" "umt5_xxl_fp8_e4m3fn_scaled.safetensors"

echo "🎉 Done! Restart ComfyUI."
EOF

# 3. Run it
chmod +x fast_wan_corrected.sh
./fast_wan_corrected.sh
