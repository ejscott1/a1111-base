# A1111 Base (RunPod + GHCR)

Minimal, extensions-free image that launches the latest AUTOMATIC1111 Stable Diffusion WebUI.  
Optimized with **xFormers** for faster / lower-VRAM attention.  
Includes an **auto symlink repair** step so all models, outputs, configs, and embeddings always point into persistent storage (`/workspace/a1111-data`).

## 📦 Image
ghcr.io/ejscott1/a1111-base:latest

## 🚀 Quick Start (RunPod)
- **Image:** ghcr.io/ejscott1/a1111-base:latest  
- **GPU:** A4500 / A5000 (balanced) or A40 / RTX 4090 (fastest for SDXL)  
- **Persistent Volume:** mount at `/workspace` (50–100GB recommended)  
- **Expose Port:** 7860  
- **Environment Variables:**  
  WEBUI_ARGS=--listen --port 7860 --api --data-dir /workspace/a1111-data --enable-insecure-extension-access --xformers

➡️ After launch:  
1. Click **HTTP 7860** → Stable Diffusion WebUI.  
2. Upload at least one checkpoint into: `/workspace/a1111-data/models/Stable-diffusion/`  
3. In A1111 → Settings → Reload UI → select your model.  

## 📂 Paths
- **Checkpoints:** `/workspace/a1111-data/models/Stable-diffusion/`  
- **LoRA:** `/workspace/a1111-data/models/Lora/`  
- **VAE:** `/workspace/a1111-data/models/VAE/`  
- **Outputs:** `/workspace/a1111-data/outputs/`  
- **Configs (SD 1.5):** `/workspace/a1111-data/configs/v1-inference.yaml`  
- **Configs (A1111 runtime):** `/opt/webui/configs/v1-inference.yaml` (auto-synced)  

## 🛠 Features
- Always pulls the latest A1111 code at boot (or pin with `WEBUI_COMMIT`).  
- Auto-downloads `v1-inference.yaml` for SD 1.5 models.  
- Full support for SD 1.5 and SDXL checkpoints.  
- **xFormers enabled by default** for better VRAM use & speed.  
- **Auto symlink fix** at boot → all `/opt/webui/*` paths are linked into `/workspace/a1111-data/*`.  
- Clean logging: fewer CUDA/tokenizer warnings via env settings.  

## ⚙️ Environment Variables
- `WEBUI_DIR` (default `/opt/webui`)  
- `DATA_DIR` (default `/workspace/a1111-data`)  
- `PORT` (default `7860`)  
- `WEBUI_ARGS` (default includes extension access + xFormers)  
- `WEBUI_COMMIT` — pin A1111 to a specific commit SHA (optional)  
- `SKIP_GIT_UPDATE=1` — skip pulling latest A1111 on boot  

## 📝 Notes
- SD 1.5 checkpoints require `v1-inference.yaml` (auto-fetched on first boot).  
- SDXL checkpoints do **not** need a YAML.  
- Outputs, models, configs are safe as long as the same persistent volume is attached.  
- Optional extras (e.g., `realesrgan`, `gfpgan`, `basicsr`) can be preinstalled in the Dockerfile if you want built-in upscalers/face-restorers.
