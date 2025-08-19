# Imagen Runpod ComfyUI (migdrp/runpod:comfyui)

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod/comfyui?sort=semver)](https://hub.docker.com/r/migdrp/runpod)
[<- Volver al README principal](../README.md)

Imagen Docker para [ComfyUI](https://github.com/comfyanonymous/ComfyUI) con CUDA 12.1, JupyterLab y terminal web.

**Para una guía detallada sobre el uso de los servicios, consulta la [Guía de Uso: ComfyUI](../docs/usage-comfyui.md).**

## Construcción de la Imagen

Desde la **raíz del repositorio**:
```bash
docker build --build-arg SRC_PATH=runpod-comfyui -t migdrp/runpod:comfyui -f runpod-comfyui/Dockerfile .
```

## Ejecución Local

Desde la **raíz del repositorio**:
```bash
# Asegúrate de que envs/runpod-comfyui.env existe y está configurado
docker run -it --rm --name migdrp-runpod-comfyui --gpus all --env-file envs/runpod-comfyui.env -p 8188:8188 -p 8888:8888 -p 7860:7860 -v comfyui_workspace:/workspace -v ./runpod-comfyui/workspace:/workspace_template:ro migdrp/runpod:comfyui
```

## Acceso a Servicios (Localmente)

*   **ComfyUI**: `http://localhost:8188`
*   **JupyterLab**: `http://localhost:8888`
*   **Terminal Web**: `http://localhost:7860`