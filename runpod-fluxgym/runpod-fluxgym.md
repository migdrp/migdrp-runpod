# Imagen Runpod FluxGym (migdrp/runpod:fluxgym)

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod/fluxgym?sort=semver)](https://hub.docker.com/r/migdrp/runpod)
[<- Volver al README principal](../README.md)

Imagen Docker optimizada para ejecutar [FluxGym](https://github.com/cocktailpeanut/fluxgym) (con soporte para SD3) en plataformas GPU como [Runpod](https://runpod.io). Incluye JupyterLab y una terminal web (`ttyd`).

**Características Principales:**

*   **Base**: Python 3.10 slim
*   **Servicios**: FluxGym UI, JupyterLab, Terminal Web (ttyd)
*   **Instalación Dinámica**: FluxGym y dependencias (`sd-scripts`) se instalan/actualizan al inicio dentro del volumen persistente `/workspace`.
*   **Persistencia**: Usa un volumen Docker montado en `/workspace` para modelos, datasets, logs y la propia instalación de FluxGym.
*   **Gestión**: Los servicios son gestionados por Supervisor.

## Documentación Completa

La documentación detallada se ha dividido en varios archivos dentro de la carpeta `docs/`:

*   **[🚀 Inicio Rápido](./docs/quick_start.md)**: Cómo construir y ejecutar la imagen (Local y Runpod).
*   **[🛠️ Uso de Servicios](./docs/usage.md)**: Cómo acceder a FluxGym, Jupyter, Terminal y descargar modelos.
*   **[📜 Scripts (.sh)](./docs/scripts.md)**: Explicación de para qué sirve cada script de automatización.
*   **[🐳 Flujo de Trabajo Docker](./docs/docker_workflow.md)**: Guía simplificada sobre imágenes, contenedores, volúmenes y cómo aplicar actualizaciones.
*   **[⚙️ Gestión con Supervisor](./docs/supervisor.md)**: Comandos útiles para monitorizar y controlar los servicios.
*   **[☁️ Gestión de Docker Hub](./docs/docker_hub.md)**: Comandos para subir y verificar imágenes en Docker Hub.

## Archivos de Configuración

*   `.env.example`: Plantilla para variables de entorno locales (`JUPYTER_PASSWORD`, `HUGGINGFACE_TOKEN`).
*   `Dockerfile`: Define la construcción de la imagen.
*   `supervisord.conf`: Configuración de los servicios para Supervisor.
