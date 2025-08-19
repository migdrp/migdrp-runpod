# Imagen Runpod Basic (migdrp/runpod:basic)

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod/basic?sort=semver)](https://hub.docker.com/r/migdrp/runpod)
[<- Volver al README principal](../README.md)

Imagen Docker base con JupyterLab y una terminal web (`ttyd`), gestionados por Supervisor. No requiere GPU.

**Para una guía detallada sobre el uso de los servicios, consulta la [Guía de Uso: Basic](../docs/usage-basic.md).**

## Construcción de la Imagen

Desde la **raíz del repositorio**:
```bash
docker build --build-arg SRC_PATH=runpod-basic -t migdrp/runpod:basic -f runpod-basic/Dockerfile .
```

## Ejecución Local

Desde la **raíz del repositorio**:
```bash
# Asegúrate de que envs/runpod-basic.env existe y está configurado
docker run -it --rm --name migdrp-runpod-basic --env-file envs/runpod-basic.env -p 8888:8888 -p 7860:7860 -v basic_workspace:/workspace -v ./runpod-basic/workspace:/workspace_template:ro migdrp/runpod:basic
```

## Acceso a Servicios (Localmente)

*   **JupyterLab**: `http://localhost:8888`
*   **Terminal Web**: `http://localhost:7860`