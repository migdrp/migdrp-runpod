# Usa la imagen base de ComfyUI como punto de partida
FROM python:3.10-slim

USER root
ENV HOME=/root

# Instala dependencias del sistema y herramientas esenciales
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git build-essential libgl1-mesa-glx libglib2.0-0 tini vim supervisor python3-venv procps net-tools lsof \
    && pip install supervisor-stdout \
    && rm -rf /var/lib/apt/lists/*

# Instala ttyd (terminal web)
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Crea el entorno virtual para JupyterLab
RUN python -m venv /opt/venv/jupyter && \
    /opt/venv/jupyter/bin/pip install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor

# --- Pre-instalación del Entorno Virtual de ComfyUI ---
RUN mkdir -p /opt/comfyui_env && \
    python -m venv /opt/comfyui_env/venv

# Activa el venv e instala PyTorch para CUDA 12.1 y dependencias clave de video
RUN /bin/bash -c "source /opt/comfyui_env/venv/bin/activate && \
    pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir imageio[ffmpeg] opencv-python-headless"

# Clona ComfyUI temporalmente solo para instalar sus requisitos base
RUN mkdir -p /tmp/build_comfyui && cd /tmp/build_comfyui && git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
RUN /bin/bash -c "source /opt/comfyui_env/venv/bin/activate && \
    pip install --no-cache-dir -r /tmp/build_comfyui/ComfyUI/requirements.txt"

# Limpieza
RUN rm -rf /tmp/build_comfyui && rm -rf /root/.cache/pip

# --- Configuración final del contenedor ---
RUN mkdir -p /var/log/supervisor /var/run /opt/scripts /workspace_template /workspace
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY workspace/* /workspace_template/
COPY workspace/* /opt/scripts/
RUN chmod -R +x /workspace_template/*.sh /opt/scripts/*.sh

VOLUME ["/workspace"]
EXPOSE 8888 7860 8188
WORKDIR /
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/scripts/start.sh", "supervisor"]
