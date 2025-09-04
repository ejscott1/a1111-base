FROM nvidia/cuda:12.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VENV_DIR=/opt/venv \
    WEBUI_DIR=/opt/webui \
    DATA_DIR=/workspace/a1111-data \
    PORT=7860

# OS deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip git wget curl ca-certificates \
    libgl1 libglib2.0-0 ffmpeg tzdata pciutils xxd && \
    rm -rf /var/lib/apt/lists/*

# Python venv
RUN python3 -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

# PyTorch (CUDA 12.8) + xFormers (matching cu128 wheels)
RUN pip install --upgrade pip setuptools wheel && \
    pip install --index-url https://download.pytorch.org/whl/cu128 \
        torch torchvision torchaudio && \
    pip install --index-url https://download.pytorch.org/whl/cu128 \
        xformers

# Pre-create persistent data dir (A1111 repo is cloned at runtime)
RUN mkdir -p $DATA_DIR

# Healthcheck for A1111
HEALTHCHECK --interval=30s --timeout=60s --start-period=60s --retries=10 \
  CMD curl -fsSL "http://localhost:${PORT}/" >/dev/null || exit 1

# Startup script
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# Defaults (extensions allowed + xFormers)
ENV WEBUI_ARGS="--listen --port ${PORT} --api --data-dir ${DATA_DIR} --enable-insecure-extension-access --xformers"

EXPOSE 7860
CMD ["/opt/start.sh"]
