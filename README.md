# Migdrp Runpod Images

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod?sort=semver)](https://hub.docker.com/r/migdrp/runpod)

Este repositorio contiene las definiciones de imágenes Docker optimizadas para [Runpod](https://runpod.io/), publicadas bajo el repositorio `migdrp/runpod` en Docker Hub.

## Estructura del Repositorio

Cada carpeta principal dentro de este repositorio corresponde a una **etiqueta (tag)** específica de la imagen `migdrp/runpod` en Docker Hub.

*   **`runpod-fluxgym/`**: Contiene los archivos para construir la imagen `migdrp/runpod:fluxgym`, optimizada para [FluxGym](https://github.com/cocktailpeanut/fluxgym). ([Ver runpod-fluxgym.md](./runpod-fluxgym/runpod-fluxgym.md))
*   **`runpod-comfyui/`**: Contiene los archivos para construir la imagen `migdrp/runpod:comfyui`, optimizada para [ComfyUI](https://github.com/comfyanonymous/ComfyUI). ([Ver runpod-comfyui.md](./runpod-comfyui/runpod-comfyui.md))
*   **`runpod-basic/`**: Contiene los archivos para construir la imagen `migdrp/runpod:basic`, una imagen mínima con JupyterLab y Terminal Web (ttyd), gestionada por Supervisor. No incluye herramientas de IA específicas. ([Ver runpod-basic.md](./runpod-basic/runpod-basic.md))
*   **`envs/`**: Contiene los archivos de variables de entorno (`.env`) para cada tag. Se recomienda usar estos archivos centralizados al ejecutar los contenedores desde la raíz de este repositorio.

## Propósito

El objetivo es proporcionar imágenes preconfiguradas y optimizadas para diferentes cargas de trabajo de IA/ML en plataformas como Runpod, facilitando el despliegue y uso de herramientas populares.

## Uso General

1.  **Clonar el Repositorio**:
    ```bash
    git clone <URL_DEL_REPOSITORIO>
    cd migdrp-runpod
    ```

2.  **Configurar Entornos**:
    *   Navega a la carpeta `envs/`.
    *   Copia los archivos `.env.example` a `.env` (ej. `cp runpod-fluxgym.env.example envs/runpod-fluxgym.env`).
    *   Edita los archivos `.env` correspondientes con tus credenciales (ej. `JUPYTER_PASSWORD`, `HUGGINGFACE_TOKEN`).

3.  **Construir una Imagen (desde la raíz)**:
    Reemplaza `<tag>` con la etiqueta deseada (ej. `fluxgym`, `comfyui`, `basic`).
    ```bash
    docker build -t migdrp/runpod:<tag> -f runpod-<tag>/Dockerfile .
    ```
    *Ejemplo para FluxGym:*
    ```bash
    docker build -t migdrp/runpod:fluxgym -f runpod-fluxgym/Dockerfile .
    ```

4.  **Ejecutar un Contenedor (desde la raíz)**:
    Reemplaza `<tag>` y ajusta los puertos/volúmenes según la documentación específica de cada tag. **Se recomienda usar volúmenes nombrados específicos por tag** (ej. `fluxgym_workspace`, `comfyui_workspace`, `basic_workspace`).
    ```bash
    # Ejemplo genérico (ver docs de cada tag para detalles)
    docker run -it --rm --name migdrp-runpod-<tag> --gpus all `# Opcional, no necesario para 'basic'` --env-file envs/runpod-<tag>.env -p <puertos> -v <tag>_workspace:/workspace -v ./runpod-<tag>/workspace:/workspace_template:ro migdrp/runpod:<tag>
    ```
    *Ejemplo para FluxGym:*
    ```bash
    docker run -it --rm --name migdrp-runpod-fluxgym --gpus all --env-file envs/runpod-fluxgym.env -p 8888:8888 -p 7860:7860 -p 7862:7862 -v fluxgym_workspace:/workspace -v ./runpod-fluxgym/workspace:/workspace_template:ro migdrp/runpod:fluxgym
    ```

5.  **Consultar Documentación Específica**:
    Cada carpeta de tag (ej. `runpod-fluxgym/`) contiene su propio archivo de documentación principal (ej. `runpod-fluxgym.md`) y una carpeta `docs/` (si aplica) con instrucciones detalladas sobre su uso, configuración y scripts específicos.

## Licencia

Este proyecto se distribuye bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.