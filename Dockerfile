FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

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
    libgl1 libglib2.0-0 ffmpeg tzdata pciutils && \
    rm -rf /var/lib/apt/lists/*

# Python venv
RUN python3 -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

# PyTorch (CUDA 12.1)
RUN pip install --upgrade pip setuptools wheel && \
    pip install --extra-index-url https://download.pytorch.org/whl/cu121 \
        torch torchvision torchaudio

# Only pre-create persistent data dir (leave /opt/webui for start.sh clone)
RUN mkdir -p $DATA_DIR

EXPOSE 7860

# Healthcheck
HEALTHCHECK --interval=30s --timeout=60s --start-period=60s --retries=10 \
  CMD curl -fsSL "http://localhost:${PORT}/" >/dev/null || exit 1

# Startup
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# Default launch flags
ENV WEBUI_ARGS="--listen --port ${PORT} --api --data-dir ${DATA_DIR}"

CMD ["/opt/start.sh"]
