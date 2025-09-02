#!/usr/bin/env bash
set -euo pipefail

export WEBUI_DIR=${WEBUI_DIR:-/opt/webui}
export DATA_DIR=${DATA_DIR:-/workspace/a1111-data}
export PORT=${PORT:-7860}
export WEBUI_ARGS=${WEBUI_ARGS:-"--listen --port ${PORT} --api --data-dir ${DATA_DIR}"}

mkdir -p "${DATA_DIR}/models/Stable-diffusion" \
         "${DATA_DIR}/models/Lora" \
         "${DATA_DIR}/models/VAE" \
         "${DATA_DIR}/outputs" \
         "${DATA_DIR}/embeddings" \
         "${DATA_DIR}/configs" \
         "${DATA_DIR}/cache"

if [ ! -d "${WEBUI_DIR}/.git" ]; then
  echo "Cloning AUTOMATIC1111..."
  git clone --depth=1 https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "${WEBUI_DIR}"
else
  echo "Updating AUTOMATIC1111..."
  git -C "${WEBUI_DIR}" fetch --depth=1 origin
  git -C "${WEBUI_DIR}" reset --hard origin/master
fi

echo "Installing Python requirements..."
pip install -r "${WEBUI_DIR}/requirements_versions.txt" || pip install -r "${WEBUI_DIR}/requirements.txt"

for d in embeddings configs; do
  if [ -e "${WEBUI_DIR}/${d}" ]; then rm -rf "${WEBUI_DIR}/${d}"; fi
  ln -s "${DATA_DIR}/${d}" "${WEBUI_DIR}/${d}"
done

cd "${WEBUI_DIR}"
echo "Starting A1111 on 0.0.0.0:${PORT}"
exec python launch.py ${WEBUI_ARGS}
