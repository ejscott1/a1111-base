#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config (override via env)
# -----------------------------
export WEBUI_DIR="${WEBUI_DIR:-/opt/webui}"
export DATA_DIR="${DATA_DIR:-/workspace/a1111-data}"
export PORT="${PORT:-7860}"
export WEBUI_ARGS="${WEBUI_ARGS:-"--listen --port ${PORT} --api --data-dir ${DATA_DIR}"}"
export WEBUI_COMMIT="${WEBUI_COMMIT:-}"     # optional: pin a specific A1111 commit
export SKIP_GIT_UPDATE="${SKIP_GIT_UPDATE:-0}"

SD15_YAML_NAME="v1-inference.yaml"
SD15_YAML_URL="${SD15_YAML_URL:-https://raw.githubusercontent.com/CompVis/stable-diffusion/main/configs/stable-diffusion/${SD15_YAML_NAME}}"

# -----------------------------
# Persistent structure
# -----------------------------
mkdir -p \
  "${DATA_DIR}/models/Stable-diffusion" \
  "${DATA_DIR}/models/Lora" \
  "${DATA_DIR}/models/VAE" \
  "${DATA_DIR}/outputs" \
  "${DATA_DIR}/embeddings" \
  "${DATA_DIR}/configs" \
  "${DATA_DIR}/cache"

# -----------------------------
# Clone / update AUTOMATIC1111
# (Assumes Dockerfile does NOT pre-create /opt/webui)
# -----------------------------
if [ -d "${WEBUI_DIR}/.git" ]; then
  if [ "${SKIP_GIT_UPDATE}" != "1" ]; then
    echo "[A1111] Updating repo in ${WEBUI_DIR}..."
    git -C "${WEBUI_DIR}" fetch --depth=1 origin
    git -C "${WEBUI_DIR}" reset --hard origin/master
  else
    echo "[A1111] Skipping git update (SKIP_GIT_UPDATE=1)"
  fi
else
  echo "[A1111] Fresh clone into ${WEBUI_DIR}..."
  rm -rf "${WEBUI_DIR}" || true
  git clone --depth=1 https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "${WEBUI_DIR}"
fi

# Optionally pin to a specific commit
if [ -n "${WEBUI_COMMIT}" ]; then
  echo "[A1111] Pinning to commit ${WEBUI_COMMIT}..."
  git -C "${WEBUI_DIR}" fetch --depth=1 origin "${WEBUI_COMMIT}" || true
  git -C "${WEBUI_DIR}" reset --hard "${WEBUI_COMMIT}"
fi

# -----------------------------
# Python deps
# -----------------------------
echo "[Deps] Installing Python requirements..."
pip install -r "${WEBUI_DIR}/requirements_versions.txt" \
  || pip install -r "${WEBUI_DIR}/requirements.txt"

# -----------------------------
# Symlink selected folders to persistent storage
# -----------------------------
for d in embeddings configs; do
  if [ -e "${WEBUI_DIR}/${d}" ] || [ -L "${WEBUI_DIR}/${d}" ]; then
    rm -rf "${WEBUI_DIR:?}/${d}"
  fi
  ln -s "${DATA_DIR}/${d}" "${WEBUI_DIR}/${d}"
done

# -----------------------------
# Ensure SD 1.5 YAML (auto-download)
# -----------------------------
if [ ! -f "${DATA_DIR}/configs/${SD15_YAML_NAME}" ]; then
  echo "[SD1.5] Downloading ${SD15_YAML_NAME} to ${DATA_DIR}/configs/ ..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${SD15_YAML_URL}" -o "${DATA_DIR}/configs/${SD15_YAML_NAME}" || true
  else
    wget -q -O "${DATA_DIR}/configs/${SD15_YAML_NAME}" "${SD15_YAML_URL}" || true
  fi
  if [ ! -s "${DATA_DIR}/configs/${SD15_YAML_NAME}" ]; then
    echo "[SD1.5][WARN] Could not download ${SD15_YAML_NAME}. You can still use SDXL models, or upload the YAML manually."
  fi
else
  echo "[SD1.5] Found existing ${SD15_YAML_NAME} in persistent configs."
fi

# Also place a copy where A1111 expects (local repo configs folder)
mkdir -p "${WEBUI_DIR}/configs" || true
if [ -s "${DATA_DIR}/configs/${SD15_YAML_NAME}" ]; then
  cp -f "${DATA_DIR}/configs/${SD15_YAML_NAME}" "${WEBUI_DIR}/configs/${SD15_YAML_NAME}" || true
fi

# -----------------------------
# Summary
# -----------------------------
cat <<EOF
[Paths]
 - Data dir:           ${DATA_DIR}
 - Checkpoints:        ${DATA_DIR}/models/Stable-diffusion
 - LoRA:               ${DATA_DIR}/models/Lora
 - VAE:                ${DATA_DIR}/models/VAE
 - Outputs:            ${DATA_DIR}/outputs
 - Configs (persist):  ${DATA_DIR}/configs/${SD15_YAML_NAME} $( [ -s "${DATA_DIR}/configs/${SD15_YAML_NAME}" ] && echo "(OK)" || echo "(missing)" )
 - Configs (A1111):    ${WEBUI_DIR}/configs/${SD15_YAML_NAME} $( [ -s "${WEBUI_DIR}/configs/${SD15_YAML_NAME}" ] && echo "(OK)" || echo "(missing)" )

[Launch]
 python launch.py ${WEBUI_ARGS}
EOF

# -----------------------------
# Launch WebUI
# -----------------------------
cd "${WEBUI_DIR}"
exec python launch.py ${WEBUI_ARGS}
