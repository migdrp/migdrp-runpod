# Entorno de Producción Local para Wan Video 2.2

Este proyecto contiene todo lo necesario para construir y ejecutar un entorno Docker autocontenido para la generación de video con el modelo **Wan Video 2.2 (versión 14B GGUF)** de Alibaba, utilizando ComfyUI como interfaz.

El objetivo es crear una "fábrica" local de contenido de video de alta calidad que pueda ser utilizado posteriormente en proyectos creativos, como performances audiovisuales con TouchDesigner.

## ✨ Características

- **Modelo Principal**: Wan Video 2.2 14B en formato GGUF (Q4_K_M) para un rendimiento optimizado en GPUs de consumidor.
- **Entorno Aislado**: Todo se ejecuta dentro de un contenedor Docker, manteniendo tu sistema local limpio.
- **Interfaz Web**: Se utiliza [ComfyUI](https://github.com/comfyanonymous/ComfyUI) para cargar los flujos de trabajo y generar los videos.
- **Automatización**: Incluye un script para descargar todos los modelos necesarios (Unets, VAE, Text Encoders, LoRAs) con un solo comando.
- **Persistencia de Datos**: Utiliza un volumen de Docker para que tus modelos, nodos personalizados y videos generados se conserven entre sesiones.

## ⚙️ Prerrequisitos

1.  **Docker Desktop**: Instalado y en ejecución en tu sistema Windows.
2.  **GPU NVIDIA**: Una tarjeta gráfica con al menos **16 GB de VRAM** es muy recomendable para un funcionamiento fluido.
3.  **Drivers NVIDIA**: Debes tener los drivers más recientes instalados.

## 📂 Estructura del Proyecto

Crea la siguiente estructura de carpetas y archivos. El contenido de cada archivo se proporciona a continuación.

```
runpod-video-wan/
├── Dockerfile
├── supervisord.conf
└── workspace/
    └── download_models_wan22.sh
```

## 🛠️ Contenido de los Archivos

Copia y pega el siguiente contenido en los archivos correspondientes que creaste en el paso anterior.

---

#### 📄 **`runpod-video-wan/Dockerfile`**

```dockerfile
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
```

---

#### 📄 **`runpod-video-wan/supervisord.conf`**

```ini
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
nodaemon=true
user=root
logfile=/dev/stdout
logfile_maxbytes=0
pidfile=/var/run/supervisord.pid

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[program:ttyd]
command=bash -c "cd / && exec ttyd -p 7860 bash"
autostart=true
autorestart=true
priority=100
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stdout
stderr_logfile_maxbytes=0

[program:jupyter]
command=/opt/scripts/start-jupyter.sh
autostart=true
autorestart=unexpected
priority=200
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stdout
stderr_logfile_maxbytes=0

[program:comfyui]
command=/opt/scripts/start-comfyui.sh
directory=/workspace
autostart=true
autorestart=unexpected
priority=300
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stdout
stderr_logfile_maxbytes=0
```

---

#### 📄 **`envs/runpod-video-wan.env`**

```env
# Contraseña para acceder a JupyterLab
JUPYTER_PASSWORD="tu_contraseña_segura_aqui"

# Token de Hugging Face para descargas (opcional pero recomendado)
HUGGINGFACE_TOKEN="hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

#### 📄 **`runpod-video-wan/workspace/download_models_wan22.sh`**

```bash
#!/bin/bash
set -e
log() { echo "[$(date --iso-8601=seconds)] $1"; }
download_git_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    local repo_name=$(basename "$repo_url" .git)
    if [ ! -d "$dest_dir/$repo_name" ]; then
        log "Clonando $repo_name..."
        git clone "$repo_url" "$dest_dir/$repo_name"
    else
        log "Repositorio $repo_name ya existe. Omitiendo."
    fi
}
download_file() {
    local url="$1"
    local dest_dir="$2"
    local filename=$(basename "$url" | cut -d'?' -f1)
    mkdir -p "$dest_dir"
    if [ ! -f "$dest_dir/$filename" ]; then
        log "Descargando $filename a $dest_dir..."
        wget -c --show-progress -O "$dest_dir/$filename" "$url"
    else
        log "Archivo $filename ya existe. Omitiendo."
    nfi
}

# --- 1. Nodos Personalizados Esenciales ---
CUSTOM_NODES_DIR="/workspace/ComfyUI/custom_nodes"
log "Descargando ComfyUI-Manager..."
download_git_repo https://github.com/ltdrdata/ComfyUI-Manager.git "$CUSTOM_NODES_DIR"

# --- 2. Modelos Wan 2.2 ---
MODELS_DIR="/workspace/models"
log "Descargando Modelos para Wan Video 2.2..."

# --- Modelos Unet (GGUF) ---
DIFFUSION_MODELS_DIR="$MODELS_DIR/diffusion_models"
log "Descargando Unets GGUF (Q4_K_M)..."
# Modelo High Noise (Text-to-Video)
download_file "https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-T2V-A14B-HighNoise-Q4_K_M.gguf" "$DIFFUSION_MODELS_DIR"
# Modelo Low Noise (Text-to-Video)
download_file "https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-T2V-A14B-LowNoise-Q4_K_M.gguf" "$DIFFUSION_MODELS_DIR"

# --- Text Encoder (CLIP) ---
TEXT_ENCODERS_DIR="$MODELS_DIR/text_encoders"
log "Descargando Text Encoder umt5..."
download_file "https://huggingface.co/Comfy-Org/Man_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$TEXT_ENCODERS_DIR"

# --- VAE ---
VAE_DIR="$MODELS_DIR/vae"
log "Descargando VAE..."
download_file "https://huggingface.co/Comfy-Org/Man_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "$VAE_DIR"

# --- LoRA ---
LORA_DIR="$MODELS_DIR/loras"
log "Descargando LoRA lightx2v..."
download_file "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors" "$LORA_DIR"

log "--- DESCARGA DE MODELOS COMPLETADA ---"
log "Ahora, reinicia ComfyUI ('supervisorctl restart comfyui') y carga tu workflow JSON."
log "ComfyUI-Manager te pedirá instalar los nodos que falten (como GGUF Loader y KJNodes)."
```
*(Nota: Los scripts `start.sh`, `start-jupyter.sh` y `start-comfyui.sh` de la plantilla `runpod-comfyui` anterior son compatibles y no necesitan cambios).*

---

## 🚀 Guía de Ejecución

1.  **Construir la Imagen Docker**:
    Abre una terminal en la carpeta raíz del repositorio y ejecuta:
    ```bash
    docker build -t migdrp/runpod:video-wan -f runpod-video-wan/Dockerfile .
    ```

2.  **Ejecutar el Contenedor**:
    Asegúrate de haber configurado tu archivo `.env`. Luego, ejecuta:
    ```bash
    docker run -it --rm --name wan-video-studio --gpus all \
      --env-file envs/runpod-video-wan.env \
      -p 8188:8188 -p 8888:8888 -p 7860:7860 \
      -v wan_video_workspace:/workspace \
      -v ./runpod-video-wan/workspace:/workspace_template:ro \
      migdrp/runpod:video-wan
    ```

3.  **Descargar los Modelos**:
    Una vez que el contenedor esté en marcha, abre un navegador y ve a la terminal web: `http://localhost:7860`.
    Dentro de la terminal, ejecuta el script de descarga:
    ```bash
    bash /workspace/download_models_wan22.sh
    ```

4.  **Instalar Nodos Personalizados y Ejecutar**:
    *   Reinicia ComfyUI desde la terminal: `supervisorctl restart comfyui`.
    *   Abre la interfaz de ComfyUI en: `http://localhost:8188`.
    *   Arrastra tu archivo de workflow `.json` a la interfaz.
    *   El **ComfyUI-Manager** detectará los nodos faltantes. Haz clic en el botón para instalarlos.
    *   Una vez instalados, **reinicia ComfyUI una última vez**.
    *   ¡Listo! El workflow cargará correctamente y podrás empezar a generar videos.

---

Este paquete de archivos y instrucciones te permitirá replicar el entorno de generación de video de Wan 2.2 de manera precisa y eficiente.