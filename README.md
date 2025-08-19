# Migdrp Runpod Images

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod?sort=semver)](https://hub.docker.com/r/migdrp/runpod)

Este repositorio contiene las definiciones de imágenes Docker optimizadas para [Runpod](https://runpod.io/), publicadas bajo el repositorio `migdrp/runpod` en Docker Hub.

## Estructura del Repositorio

*   **`runpod-basic/`**: Imagen mínima con JupyterLab y Terminal Web. ([Ver Guía](./runpod-basic/runpod-basic.md))
*   **`runpod-comfyui/`**: Imagen optimizada para [ComfyUI](https://github.com/comfyanonymous/ComfyUI). ([Ver Guía](./runpod-comfyui/runpod-comfyui.md))
*   **`runpod-fluxgym/`**: Imagen optimizada para [FluxGym](https://github.com/cocktailpeanut/fluxgym). ([Ver Guía](./runpod-fluxgym/runpod-fluxgym.md))
*   **`envs/`**: Archivos de variables de entorno (`.env`) para cada tag.
*   **`docs/`**: Documentación general y guías de uso detalladas para cada imagen.
    *   **[Flujo de Trabajo Docker](./docs/docker_workflow.md)**
    *   **[Gestión con Supervisor](./docs/supervisor.md)**
    *   **[Guía de Uso: Basic](./docs/usage-basic.md)**
    *   **[Guía de Uso: ComfyUI](./docs/usage-comfyui.md)**
    *   **[Guía de Uso: FluxGym](./docs/usage-fluxgym.md)**

## Uso General

1.  **Clonar y Configurar**: Clona el repo, navega a `envs/`, copia los `.env.example` a `.env` y edítalos con tus credenciales.

2.  **Construir una Imagen (desde la raíz)**:
    Usa `--build-arg` para especificar el contexto. Reemplaza `<tag>` con `basic`, `comfyui`, o `fluxgym`.

    ```bash
    docker build --build-arg SRC_PATH=runpod-<tag> -t migdrp/runpod:<tag> -f runpod-<tag>/Dockerfile .
    
    ```
    *Ejemplo para ComfyUI:*

    ```bash
    docker build --build-arg SRC_PATH=runpod-comfyui -t migdrp/runpod:comfyui -f runpod-comfyui/Dockerfile .
    ```

3.  **Ejecutar un Contenedor (desde la raíz)**:
    Usa volúmenes nombrados específicos por tag (ej. `comfyui_workspace`).
    *Ejemplo para ComfyUI:*
    ```bash
    docker run -it --rm --name migdrp-runpod-comfyui --gpus all --env-file envs/runpod-comfyui.env -p 8188:8188 -p 8888:8888 -p 7860:7860 -v comfyui_workspace:/workspace -v ./runpod-comfyui/workspace:/workspace_template:ro migdrp/runpod:comfyui
    ```

4.  **Consultar Guías de Uso**: Para detalles sobre cómo usar los servicios de cada imagen, consulta las guías en la carpeta `docs/`.

## Licencia

Este proyecto se distribuye bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.