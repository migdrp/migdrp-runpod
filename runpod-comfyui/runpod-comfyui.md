# Imagen Runpod ComfyUI (migdrp/runpod:comfyui)

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod/comfyui?sort=semver)](https://hub.docker.com/r/migdrp/runpod)
[<- Volver al README principal](../README.md)

Imagen Docker optimizada para ejecutar [ComfyUI](https://github.com/comfyanonymous/ComfyUI) con soporte para CUDA 12.1, diseñada para plataformas GPU como [Runpod](https://runpod.io). Incluye JupyterLab y una terminal web (`ttyd`).

**Características Principales:**

*   **Base**: Python 3.10 slim
*   **Servicios**: ComfyUI, JupyterLab, Terminal Web (ttyd)
*   **Entorno Pre-instalado**: El entorno virtual Python con PyTorch 2.5.1+cu121 y las dependencias base de ComfyUI se instalan durante la construcción de la imagen en `/opt/comfyui_env/venv`.
*   **Código Fuente Dinámico**: El código fuente de ComfyUI se clona/actualiza al inicio dentro del volumen persistente `/workspace/ComfyUI`.
*   **Persistencia**: Usa un volumen Docker montado en `/workspace` para el código fuente de ComfyUI, modelos, nodos personalizados, logs, etc.
*   **Gestión**: Los servicios son gestionados por Supervisor.

## Documentación Específica

*   **[🚀 Inicio Rápido](./docs/quick_start.md)**: Cómo construir y ejecutar la imagen (Local y Runpod).
*   **[🛠️ Uso de Servicios](./docs/usage.md)**: Cómo acceder a ComfyUI, Jupyter, Terminal y gestionar modelos/nodos.
*   **[📜 Scripts (.sh)](./docs/scripts.md)**: Explicación de los scripts de automatización.

## Documentación General del Proyecto

Para entender mejor los conceptos generales que aplican a todas las imágenes del proyecto, consulta la [documentación general](../docs/).

## Archivos de Configuración

*   `../envs/runpod-comfyui.env.example`: Plantilla para variables de entorno (ubicada en la carpeta `envs/` del repositorio raíz). Usar para `JUPYTER_PASSWORD`, `HUGGINGFACE_TOKEN`.
*   `Dockerfile`: Define la construcción de la imagen.
*   `supervisord.conf`: Configuración de los servicios para Supervisor.
*   `workspace/`: Contiene los scripts de inicio (`start.sh`, `start-comfyui.sh`, `start-jupyter.sh`).

## Construcción de la Imagen

Puedes construir la imagen desde dos ubicaciones:

**A) Desde la Carpeta Raíz del Repositorio (`migdrp-runpod`) (Recomendado)**:

```bash
docker build -t migdrp/runpod:comfyui -f runpod-comfyui/Dockerfile .
```

**B) Desde la Carpeta Específica (`runpod-comfyui`)**:

```bash
cd runpod-comfyui && docker build -t migdrp/runpod:comfyui . && cd ..
```
*Nota: Usa `--no-cache` si necesitas forzar una reconstrucción completa.*

## Ejecución Local (Para Pruebas)

**A) Ejecutar desde la Carpeta Raíz del Repositorio (`migdrp-runpod`) (Recomendado)**:

1.  **Preparar Archivo de Entorno**:
    *   Asegúrate de que `envs/runpod-comfyui.env` existe y contiene `JUPYTER_PASSWORD`. Puedes copiar `envs/runpod-comfyui.env.example`.

2.  **Ejecutar el Contenedor**:
    ```bash
# Opcional: docker volume create comfyui_workspace
docker run -it --rm --name migdrp-runpod-comfyui --gpus all --env-file envs/runpod-comfyui.env -p 8888:8888 -p 7860:7860 -p 8188:8188 -v comfyui_workspace:/workspace -v ./runpod-comfyui/workspace:/workspace_template:ro migdrp/runpod:comfyui
```
    *   `--env-file envs/runpod-comfyui.env`: Carga variables desde el archivo centralizado.
    *   `-v comfyui_workspace:/workspace`: Monta el volumen nombrado para persistencia.
    *   `-v ./runpod-comfyui/workspace:/workspace_template:ro`: Monta scripts locales como plantilla.

**B) Ejecutar desde la Carpeta Específica (`runpod-comfyui`)**:

1.  **Preparar Archivo de Entorno (`.env`)**:
    *   Dentro de `runpod-comfyui`, crea o copia `.env.example` a `.env` y define `JUPYTER_PASSWORD`.

2.  **Ejecutar el Contenedor**:
    ```bash
# Opcional: docker volume create comfyui_workspace
cd runpod-comfyui && docker run -it --rm --name migdrp-runpod-comfyui --gpus all --env-file .env -p 8888:8888 -p 7860:7860 -p 8188:8188 -v comfyui_workspace:/workspace -v ./workspace:/workspace_template:ro migdrp/runpod:comfyui && cd ..
```

**Parámetros Comunes**:
*   `--rm`: Elimina el contenedor al detenerlo (útil para pruebas). Omítelo para persistencia.
*   `--gpus all`: Habilita GPUs NVIDIA.

## Acceso a Servicios (Localmente)

*   **ComfyUI**: [http://localhost:8188](http://localhost:8188)
*   **JupyterLab**: [http://localhost:8888](http://localhost:8888) (Login con `JUPYTER_PASSWORD`)
*   **Terminal Web**: [http://localhost:7860](http://localhost:7860)

*(En Runpod, usa los enlaces HTTP proporcionados por la plataforma).*

## Gestión de Modelos y Nodos Personalizados

*   Coloca los modelos en las subcarpetas correspondientes dentro de `/workspace/models/` (ej. `/workspace/models/checkpoints/`).
*   Clona o coloca nodos personalizados en `/workspace/ComfyUI/custom_nodes/`.
*   Puedes usar JupyterLab, la Terminal Web, o herramientas como `wget` dentro del contenedor para descargar archivos.
*   **ComfyUI-Manager**: No está preinstalado por defecto en esta versión. Si lo deseas, puedes instalarlo manualmente:
    ```bash
# Dentro de una terminal del contenedor:
cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git && supervisorctl restart comfyui
```

## Despliegue en Docker Hub

```bash
docker login && docker push migdrp/runpod:comfyui
```