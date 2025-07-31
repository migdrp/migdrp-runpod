# Imagen Runpod Basic (migdrp/runpod:basic)

[![Docker Hub](https://img.shields.io/docker/v/migdrp/runpod/basic?sort=semver)](https://hub.docker.com/r/migdrp/runpod)
[<- Volver al README principal](../README.md)

Imagen Docker base optimizada para [Runpod](https://runpod.io/), proporcionando un entorno mínimo con JupyterLab y una terminal web (`ttyd`), gestionados por Supervisor. No incluye herramientas de IA preinstaladas.

**Características Principales:**

*   **Base**: Python 3.10 slim
*   **Servicios**: JupyterLab, Terminal Web (ttyd)
*   **Entorno Pre-instalado**: Entorno virtual para JupyterLab en `/opt/venv/jupyter`.
*   **Persistencia**: Usa un volumen Docker montado en `/workspace` para archivos de usuario, notebooks, etc.
*   **Gestión**: Los servicios son gestionados por Supervisor.

## Puertos y Accesos

| Servicio    | Puerto | URL                    | Notas                           |
|-------------|--------|------------------------|----------------------------------|
| JupyterLab  | 8888   | http://localhost:8888  | Entorno de desarrollo principal |
| Terminal Web| 7860   | http://localhost:7860  | Terminal accesible vía web      |

## Archivos de Configuración

*   `../envs/runpod-basic.env.example`: Plantilla para variables de entorno (ubicada en la carpeta `envs/` del repositorio raíz). Usar para `JUPYTER_PASSWORD`.
*   `Dockerfile`: Define la construcción de la imagen.
*   `supervisord.conf`: Configuración de los servicios para Supervisor.
*   `workspace/`: Contiene los scripts de inicio (`start.sh`, `start-jupyter.sh`).

## Construcción de la Imagen

Puedes construir la imagen desde dos ubicaciones:

**A) Desde la Carpeta Raíz del Repositorio (`migdrp-runpod`) (Recomendado)**:

```bash
docker build -t migdrp/runpod:basic -f runpod-basic/Dockerfile .
```

**B) Desde la Carpeta Específica (`runpod-basic`)**:

```bash
cd runpod-basic && docker build -t migdrp/runpod:basic . && cd ..
```
*Nota: Usa `--no-cache` si necesitas forzar una reconstrucción completa.*

## Ejecución Local (Para Pruebas)

**A) Ejecutar desde la Carpeta Raíz del Repositorio (`migdrp-runpod`) (Recomendado)**:

1.  **Preparar Archivo de Entorno**:
    *   Asegúrate de que `envs/runpod-basic.env` existe y contiene `JUPYTER_PASSWORD`. Puedes copiar `envs/runpod-basic.env.example`.

2.  **Ejecutar el Contenedor**:
    ```bash
# Opcional: docker volume create basic_workspace
docker run -it --rm --name migdrp-runpod-basic --env-file envs/runpod-basic.env -p 8888:8888 -p 7860:7860 -v basic_workspace:/workspace -v ./runpod-basic/workspace:/workspace_template:ro migdrp/runpod:basic
```
    *   `--env-file envs/runpod-basic.env`: Carga variables desde el archivo centralizado.
    *   `-v basic_workspace:/workspace`: Monta el volumen nombrado para persistencia.
    *   `-v ./runpod-basic/workspace:/workspace_template:ro`: Monta scripts locales como plantilla.

**B) Ejecutar desde la Carpeta Específica (`runpod-basic`)**:

1.  **Preparar Archivo de Entorno (`.env`)**:
    *   Dentro de `runpod-basic`, crea o copia `.env.example` a `.env` y define `JUPYTER_PASSWORD`.

2.  **Ejecutar el Contenedor**:
    ```bash
# Opcional: docker volume create basic_workspace
cd runpod-basic && docker run -it --rm --name migdrp-runpod-basic --env-file .env -p 8888:8888 -p 7860:7860 -v basic_workspace:/workspace -v ./workspace:/workspace_template:ro migdrp/runpod:basic && cd ..
```

**Parámetros Comunes**:
*   `--rm`: Elimina el contenedor al detenerlo (útil para pruebas). Omítelo para persistencia.

## Acceso a Servicios (Localmente)

*   **JupyterLab**: [http://localhost:8888](http://localhost:8888) (Login con `JUPYTER_PASSWORD`)
*   **Terminal Web**: [http://localhost:7860](http://localhost:7860)

*(En Runpod, usa los enlaces HTTP proporcionados por la plataforma).*

## Documentación Específica

*   **[🚀 Inicio Rápido](./docs/quick_start.md)**: Cómo construir y ejecutar la imagen (Local y Runpod).
*   **[🛠️ Uso de Servicios](./docs/usage.md)**: Cómo acceder a Jupyter, Terminal y trabajar con el entorno.
*   **[📜 Scripts (.sh)](./docs/scripts.md)**: Explicación de los scripts de automatización.

## Documentación General del Proyecto

Para entender mejor los conceptos generales que aplican a todas las imágenes del proyecto, consulta la [documentación general](../docs/).

## Mantenimiento

### Gestión de Contenedores

```bash
docker ps -a && docker start -i migdrp-runpod-basic && docker stop migdrp-runpod-basic && docker rm -f migdrp-runpod-basic
```

### Gestión de Recursos

```bash
docker volume ls && docker volume rm basic_workspace && docker system prune
```

## Estructura de Directorios Relevante

```
/
├── workspace/           # Directorio principal de trabajo (persistente si se usa volumen)
├── opt/
│   └── venv/
│       └── jupyter/    # Entorno virtual de JupyterLab (en la imagen)
└── var/
    └── log/
        └── supervisor/ # Logs de servicios (dentro del contenedor)
```

## Notas Importantes

*   Esta imagen no requiere GPU.
*   Los servicios se inician automáticamente a través de Supervisor.
*   Los cambios en `/workspace` persisten si se utiliza un volumen nombrado.
*   Define `JUPYTER_PASSWORD` en el archivo `.env` correspondiente para asegurar JupyterLab.