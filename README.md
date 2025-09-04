# A1111 Base (RunPod + GHCR)

Minimal, extensions-free image that launches the latest AUTOMATIC1111 Stable Diffusion WebUI.
- Clones/updates A1111 at container start
- Persists all data under `/workspace/a1111-data`
- Auto-downloads `v1-inference.yaml` for SD 1.5
- Supports installing extensions via the WebUI
- Optimized with **xFormers** for faster / lower-VRAM attention

## Image
ghcr.io/ejscott1/a1111-base:latest

> Make the package **Public** in GitHub → Package settings (or provide GHCR creds in RunPod if private).

## Paths (inside container)
- Data dir: /workspace/a1111-data
- Checkpoints: /workspace/a1111-data/models/Stable-diffusion/
- LoRA: /workspace/a1111-data/models/Lora/
- VAE: /workspace/a1111-data/models/VAE/
- Outputs: /workspace/a1111-data/outputs/
- Configs (persist): /workspace/a1111-data/configs/v1-inference.yaml
- Configs (A1111): /opt/webui/configs/v1-inference.yaml

## Run (RunPod)
- Image: ghcr.io/ejscott1/a1111-base:latest
- GPU: A4500/A5000 (solid) or A40/4090 (faster)
- Volume: mount persistent volume at /workspace
- Port: expose 7860
- Env (with extension installs + xFormers enabled):
  WEBUI_ARGS=--listen --port 7860 --api --data-dir /workspace/a1111-data --enable-insecure-extension-access --xformers
- Connect → HTTP once running.

## First use
1. Upload at least one model to:
   /workspace/a1111-data/models/Stable-diffusion/
2. In the WebUI → Settings → Reload UI → pick your model.

## SD 1.5 vs SDXL
- SD 1.5 needs v1-inference.yaml. This script auto-downloads it on first boot.
- SDXL models do not need a YAML.

## Environment variables
- WEBUI_DIR (default /opt/webui)
- DATA_DIR (default /workspace/a1111-data)
- PORT (default 7860)
- WEBUI_ARGS (default includes extension access + xFormers)
- WEBUI_COMMIT — pin A1111 to a specific commit SHA (optional)
- SKIP_GIT_UPDATE=1 — skip pulling latest A1111 on boot

## CI (GitHub Actions → GHCR)
Ensure this file exists:
  .github/workflows/build.yml

Push to main to auto-build & push tags:
- ghcr.io/ejscott1/a1111-base:latest
- ghcr.io/ejscott1/a1111-base:sha-<commit>
