#!/usr/bin/env bash
set -euo pipefail

# ========= Config (override via env) =========
export WEBUI_DIR="${WEBUI_DIR:-/opt/webui}"
export DATA_DIR="${DATA_DIR:-/workspace/a1111-data}"
export PORT="${PORT:-7860}"
export WEBUI_ARGS="${WEBUI_ARGS:-"--listen --port ${PORT} --api --data-dir ${DATA_DIR} --enable-insecure-extension-access --xformers"}"

# A1111 repo behavior
export WEBUI_COMMIT="${WEBUI_COMMIT:-}"     # optional commit SHA to pin
export SKIP_GIT_UPDATE="${SKIP_GIT_UPDATE:-0}"

# SD1.5 config
SD15_YAML_NAME="v1-inference.yaml"
SD15_YAML_URL="${SD15_YAML_URL:-https://raw.githubusercontent.com/CompVis/stable-diffusion/main/configs/stable-diffusion/${SD15_YAML_NAME}}"

# ========= Persistent layout =========
mkdir -p \
  "${DATA_DIR}/models/Stable-diffusion" \
  "${DATA_DIR}/models/Lora" \
  "${DATA_DIR}/models/VAE" \
  "${DATA_DIR}/outputs" \
  "${DATA_DIR}/embeddings" \
  "${DATA_DIR}/configs" \
  "${DATA_DIR}/cache" \
  "${DATA_DIR}/logs"

# ========= Clone / update AUTOMATIC1111 =========
if [ -d "${WEBUI_DIR}/.git" ]; then
  if [ "${SKIP_GIT_UPDATE}" != "1" ]; then
    echo "[A1111] Updating repo..."
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

# Optional commit pin
if [ -n "${WEBUI_COMMIT}" ]; then
  echo "[A1111] Pinning to commit ${WEBUI_COMMIT}..."
  git -C "${WEBUI_DIR}" fetch --depth=1 origin "${WEBUI_COMMIT}" || true
  git -C "${WEBUI_DIR}" reset --hard "${WEBUI_COMMIT}"
fi

# ========= Python deps for A1111 =========
echo "[Deps] Installing A1111 requirements..."
pip install -r "${WEBUI_DIR}/requirements_versions.txt" || pip install -r "${WEBUI_DIR}/requirements.txt"

# ========= Ensure symlinks to persistent storage =========
link_safe() {
  local link=$1
  local target=$2
  rm -rf "$link"
  ln -s "$target" "$link"
}
link_safe "$WEBUI_DIR/models/Stable-diffusion" "$DATA_DIR/models/Stable-diffusion"
link_safe "$WEBUI_DIR/models/Lora" "$DATA_DIR/models/Lora"
link_safe "$WEBUI_DIR/models/VAE" "$DATA_DIR/models/VAE"
link_safe "$WEBUI_DIR/outputs" "$DATA_DIR/outputs"
link_safe "$WEBUI_DIR/configs" "$DATA_DIR/configs"
link_safe "$WEBUI_DIR/embeddings" "$DATA_DIR/embeddings"

# ========= SD 1.5 YAML (optional) =========
if [ ! -f "${DATA_DIR}/configs/${SD15_YAML_NAME}" ]; then
  echo "[SD1.5] Fetching ${SD15_YAML_NAME}..."
  (curl -fsSL "${SD15_YAML_URL}" -o "${DATA_DIR}/configs/${SD15_YAML_NAME}" || \
   wget -q -O "${DATA_DIR}/configs/${SD15_YAML_NAME}" "${SD15_YAML_URL}" || true)
  if [ ! -s "${DATA_DIR}/configs/${SD15_YAML_NAME}" ]; then
    echo "[SD1.5][WARN] Could not download ${SD15_YAML_NAME}. You can still use SDXL or add it later."
  fi
else
  echo "[SD1.5] Found existing ${SD15_YAML_NAME} in persistent configs."
fi
mkdir -p "${WEBUI_DIR}/configs"
[ -s "${DATA_DIR}/configs/${SD15_YAML_NAME}" ] && cp -f "${DATA_DIR}/configs/${SD15_YAML_NAME}" "${WEBUI_DIR}/configs/${SD15_YAML_NAME}" || true

# ========= Summary =========
cat <<EOF
[Paths]
 - Data dir:           ${DATA_DIR}
 - Checkpoints:        ${DATA_DIR}/models/Stable-diffusion
 - LoRA:               ${DATA_DIR}/models/Lora
 - VAE:                ${DATA_DIR}/models/VAE
 - Outputs:            ${DATA_DIR}/outputs
 - Configs (persist):  ${DATA_DIR}/configs/${SD15_YAML_NAME} $( [ -s "${DATA_DIR}/configs/${SD15_YAML_NAME}" ] && echo "(OK)" || echo "(missing)" )

[Launch]
 python launch.py ${WEBUI_ARGS}
EOF

# ========= Launch A1111 =========
cd "${WEBUI_DIR}"
exec python launch.py ${WEBUI_ARGS}
