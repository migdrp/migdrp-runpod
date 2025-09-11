# --- PASO 1: Usar la imagen base oficial de NVIDIA con CUDA 12.8 ---
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

USER root
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive

# Define el argumento con un valor por defecto para builds locales/contenidos
ARG SRC_PATH=.

# --- PASO 2: Instalar dependencias del sistema ---
# Se añade python3.10-dev para tener los headers de Python necesarios para compilar Triton.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-venv python3-pip python3.10-dev \
    curl wget git build-essential tini vim supervisor procps net-tools lsof rsync \
    libgl1 libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- PASO 3: Crear entornos virtuales aislados ---
RUN python3.10 -m venv /opt/venv_comfyui
RUN python3.10 -m venv /opt/venv_jupyter

# --- PASO 4: Instalar dependencias de Python en sus respectivos entornos ---

# --- 4.1: Dependencias de ComfyUI ---
# Se actualiza pip en el venv de ComfyUI.
RUN /opt/venv_comfyui/bin/pip install --no-cache-dir -U pip setuptools wheel
# Se instala PyTorch, la dependencia más pesada.
RUN /opt/venv_comfyui/bin/pip install --no-cache-dir --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
# Se clona ComfyUI y se instalan sus requisitos.
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI
RUN /opt/venv_comfyui/bin/pip install --no-cache-dir -r /opt/ComfyUI/requirements.txt
# Se instalan dependencias adicionales para nodos personalizados, incluyendo sage-attention.
RUN /opt/venv_comfyui/bin/pip install --no-cache-dir uv GitPython gguf sageattention
# Se pre-instala ComfyUI-Manager.
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /opt/ComfyUI/custom_nodes/ComfyUI-Manager

# --- 4.2: Dependencias de JupyterLab ---
# Se actualiza pip en el venv de Jupyter.
RUN /opt/venv_jupyter/bin/pip install --no-cache-dir -U pip setuptools wheel
# Se instalan Jupyter y sus extensiones.
RUN /opt/venv_jupyter/bin/pip install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor

# --- 4.3: Otras herramientas ---
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# --- PASO 5: Configuración final del contenedor ---
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