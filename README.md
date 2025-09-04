# A1111 Base (RunPod + GHCR)

Minimal, extensions-free image that launches the latest AUTOMATIC1111 Stable Diffusion WebUI.  
Optimized with **xFormers** for faster / lower-VRAM attention.  
Includes an **auto symlink repair** step so all models, outputs, configs, and embeddings persist in `/workspace/a1111-data`.

## 📦 Image
ghcr.io/ejscott1/a1111-base:latest

## 🚀 Quick Start (RunPod)
- **Image:** ghcr.io/ejscott1/a1111-base:latest  
- **GPU:** A4500 / A5000 (balanced) or A40 / RTX 4090 (fastest for SDXL)  
- **Persistent Volume:** mount at `/workspace` (50–100GB recommended)  
- **Expose Port:** 7860  
- **Environment Variables:**  
  ```
  WEBUI_ARGS=--listen --port 7860 --api --data-dir /workspace/a1111-data --enable-insecure-extension-access --xformers
  ```

➡️ After launch:  
1. **HTTP 7860** → Stable Diffusion WebUI.  
2. Upload at least one checkpoint into `/workspace/a1111-data/models/Stable-diffusion/`.  
3. In WebUI → Settings → Reload UI → select your model.  

## 📂 Paths
- **Checkpoints:** `/workspace/a1111-data/models/Stable-diffusion/`  
- **LoRA:** `/workspace/a1111-data/models/Lora/`  
- **VAE:** `/workspace/a1111-data/models/VAE/`  
- **Outputs:** `/workspace/a1111-data/outputs/`  
- **Configs (SD 1.5):** `/workspace/a1111-data/configs/v1-inference.yaml`  

## 📝 Notes
- CUDA 12.1 with Torch + xFormers (cu121 wheels).  
- SD 1.5 YAML auto-downloaded on first run; SDXL needs no YAML.  
- Auto symlink repair ensures all A1111 paths point to persistent storage.  

## 👩‍💻 Developer Notes
- `WEBUI_COMMIT` can pin A1111 to a specific commit.  
- `SKIP_GIT_UPDATE=1` skips pulling the latest code at boot.  
- Optional extras (`realesrgan`, `gfpgan`, `basicsr`) can be preinstalled in the Dockerfile if desired.
