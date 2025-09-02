FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VENV_DIR=/opt/venv \
    WEBUI_DIR=/opt/webui \
    DATA_DIR=/workspace/a1111-data \
    PORT=7860

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip git wget curl ca-certificates \
    libgl1 libglib2.0-0 ffmpeg tzdata pciutils && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

RUN pip install --upgrade pip setuptools wheel && \
    pip install --extra-index-url https://download.pytorch.org/whl/cu121 \
        torch torchvision torchaudio

RUN mkdir -p $WEBUI_DIR $DATA_DIR
EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
  CMD curl -fsSL "http://localhost:${PORT}/" >/dev/null || exit 1

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

ENV WEBUI_ARGS="--listen --port ${PORT} --api --data-dir ${DATA_DIR}"

CMD ["/opt/start.sh"]
