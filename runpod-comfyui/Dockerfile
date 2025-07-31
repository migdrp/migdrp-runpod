FROM python:3.10-slim

USER root
ENV HOME=/root
# JUPYTER_PASSWORD and HUGGINGFACE_TOKEN are set at runtime via --env-file or Runpod secrets
# ENV JUPYTER_PASSWORD=""
# ENV HUGGINGFACE_TOKEN=""

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    tini \
    vim \
    supervisor \
    python3-venv \
    procps \
    net-tools \
    lsof \
    && pip install supervisor-stdout \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Create JupyterLab virtual environment
RUN python -m venv /opt/venv/jupyter && \
    chmod -R 755 /opt/venv/jupyter && \
    /opt/venv/jupyter/bin/pip install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor

# --- Inicio: Pre-instalación de ComfyUI Venv ---
# Crear directorio para el venv pre-construido
RUN mkdir -p /opt/comfyui_env && \
    python -m venv /opt/comfyui_env/venv && \
    chmod -R 755 /opt/comfyui_env

# Activar venv y instalar PyTorch específico para CUDA 12.1
RUN /bin/bash -c "source /opt/comfyui_env/venv/bin/activate && \
    pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu121"

# Clonar ComfyUI temporalmente para obtener requirements.txt
RUN mkdir -p /tmp/build_comfyui && cd /tmp/build_comfyui && \
    git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI

# Instalar dependencias usando requirements.txt y restricciones implícitas
RUN /bin/bash -c "source /opt/comfyui_env/venv/bin/activate && \
    echo 'torch==2.5.1+cu121' > /opt/comfyui_env/constraints.txt && \
    echo 'torchvision==0.20.1+cu121' >> /opt/comfyui_env/constraints.txt && \
    echo 'torchaudio==2.5.1+cu121' >> /opt/comfyui_env/constraints.txt && \
    pip install --no-cache-dir -r /tmp/build_comfyui/ComfyUI/requirements.txt -c /opt/comfyui_env/constraints.txt"

# Limpiar clonación temporal y caché de pip
RUN rm -rf /tmp/build_comfyui && \
    rm -rf /root/.cache/pip
# --- Fin: Pre-instalación de ComfyUI Venv ---


# Create necessary directories
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/run && \
    mkdir -p /opt/scripts && \
    mkdir -p /opt/comfyui_env && \
    mkdir -p /workspace_template && \
    mkdir -p /workspace/models && \
    mkdir -p /workspace/custom_nodes && \
    chmod -R 755 /var/log/supervisor && \
    chmod -R 777 /workspace

# Copy scripts and configurations
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY workspace/* /workspace_template/
COPY workspace/* /opt/scripts/

# Set script permissions
RUN chmod -R +x /workspace_template/*.sh && \
    chmod -R +x /opt/scripts/*.sh && \
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension

VOLUME ["/workspace"]

EXPOSE 8888 7860 8188

WORKDIR /
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/scripts/start.sh", "supervisor"]
