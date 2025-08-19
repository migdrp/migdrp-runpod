# Imagen Runpod FluxGym (migdrp/runpod:fluxgym)

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod/fluxgym?sort=semver)](https://hub.docker.com/r/migdrp/runpod)
[<- Volver al README principal](../README.md)

Imagen Docker para [FluxGym](https://github.com/cocktailpeanut/fluxgym) con CUDA 12.1, JupyterLab y terminal web.

**Para una guía detallada sobre el uso de los servicios, consulta la [Guía de Uso: FluxGym](../docs/usage-fluxgym.md).**

## Construcción de la Imagen

Desde la **raíz del repositorio**:
```bash
docker build --build-arg SRC_PATH=runpod-fluxgym -t migdrp/runpod:fluxgym -f runpod-fluxgym/Dockerfile .
```

## Ejecución Local

Desde la **raíz del repositorio**:
```bash
# Asegúrate de que envs/runpod-fluxgym.env existe y está configurado
docker run -it --rm --name migdrp-runpod-fluxgym --gpus all --env-file envs/runpod-fluxgym.env -p 7862:7862 -p 8888:8888 -p 7860:7860 -v fluxgym_workspace:/workspace -v ./runpod-fluxgym/workspace:/workspace_template:ro migdrp/runpod:fluxgym
```

## Acceso a Servicios (Localmente)

*   **FluxGym UI**: `http://localhost:7862`
*   **JupyterLab**: `http://localhost:8888`
*   **Terminal Web**: `http://localhost:7860`
