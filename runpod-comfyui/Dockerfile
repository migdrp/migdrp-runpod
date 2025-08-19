# --- PASO 1: Usar la imagen base oficial de NVIDIA con CUDA 12.8 ---
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

USER root
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive

# Define el argumento con un valor por defecto para builds locales/contenidos
ARG SRC_PATH=.

# --- PASO 2: Instalar dependencias del sistema ---
# Esta capa se cacheará eficientemente ya que rara vez cambia.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-venv python3-pip \
    curl wget git build-essential tini vim supervisor procps net-tools lsof \
    libgl1 libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- PASO 3: Crear, configurar y activar el entorno virtual único ---
RUN python3.10 -m venv /opt/comfyui_env
ENV PATH="/opt/comfyui_env/bin:$PATH"

# --- PASO 4: Instalar dependencias de Python (de más estable a más volátil) ---
# Se actualiza pip primero en su propia capa.
RUN pip install --no-cache-dir -U pip setuptools wheel

# Se instala PyTorch, la dependencia más pesada y estable. Esta capa se cacheará casi siempre.
RUN pip install --no-cache-dir --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# Se clona ComfyUI y se instalan sus requisitos.
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI
RUN pip install --no-cache-dir -r /opt/ComfyUI/requirements.txt

# Se pre-instala ComfyUI-Manager para simplificar el uso.
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /opt/ComfyUI/custom_nodes/ComfyUI-Manager

# Se instalan Jupyter y ttyd.
RUN pip install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# --- PASO 5: Configuración final del contenedor ---
# Copiamos los archivos locales al final para no invalidar la caché de los pasos anteriores.
COPY ${SRC_PATH}/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ${SRC_PATH}/workspace/ /workspace_template/

RUN mkdir -p /var/log/supervisor /workspace && \
    chmod -R 755 /var/log/supervisor && \
    chmod -R 777 /workspace && \
    chmod -R +x /workspace_template/

# Limpieza final
RUN rm -rf /root/.cache/pip

VOLUME ["/workspace"]
EXPOSE 8888 7860 8188
WORKDIR /
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/workspace_template/start.sh", "supervisor"]