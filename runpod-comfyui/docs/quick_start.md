[<- Volver a runpod-comfyui.md](../runpod-comfyui.md)

# Inicio Rápido para ComfyUI

Esta guía te muestra cómo construir y ejecutar la imagen Docker de ComfyUI.

## Prerrequisitos

*   **Docker**: Necesitas tener Docker instalado en tu sistema.
*   **GPU NVIDIA**: Para usar la aceleración por GPU (necesaria para ComfyUI), necesitas:
    *   Una GPU NVIDIA compatible.
    *   Drivers NVIDIA actualizados.
    *   El [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) instalado.

## 1. Construir la Imagen Docker

Puedes construir la imagen desde dos ubicaciones:

**A) Desde la Carpeta Raíz del Repositorio (`migdrp-runpod`)**:
Esta es la forma recomendada, ya que centraliza la gestión.

```bash
docker build -t migdrp/runpod:comfyui -f runpod-comfyui/Dockerfile .
```
*   `-t migdrp/runpod:comfyui`: Asigna el nombre y tag a la imagen.
*   `-f runpod-comfyui/Dockerfile`: Especifica la ruta al Dockerfile de ComfyUI.
*   `.`: Indica que el contexto de construcción es la carpeta raíz actual.

**B) Desde la Carpeta Específica (`runpod-comfyui`)**:
Si prefieres trabajar directamente dentro de la carpeta de la imagen.

```bash
cd runpod-comfyui && docker build -t migdrp/runpod:comfyui . && cd ..
```

*Nota: Si modificas el `Dockerfile` y los cambios no parecen aplicarse, reconstruye usando `--no-cache` (ej. `docker build --no-cache ...`) para ignorar las capas cacheadas.*

## 2. Ejecutar Localmente (Para Pruebas)

Puedes ejecutar el contenedor en tu máquina local. Los comandos varían ligeramente dependiendo desde dónde los ejecutes.

**A) Ejecutar desde la Carpeta Raíz del Repositorio (`migdrp-runpod`)**:
Utiliza el archivo de entorno centralizado.

1.  **Preparar Archivo de Entorno**:
    *   Asegúrate de que el archivo `envs/runpod-comfyui.env` existe y contiene las variables necesarias (ej. `JUPYTER_PASSWORD`, `HUGGINGFACE_TOKEN`). Puedes copiar `envs/runpod-comfyui.env.example` si no existe.

2.  **Ejecutar el Contenedor**:
    ```bash
docker run -it --rm --name migdrp-runpod-comfyui --gpus all --env-file envs/runpod-comfyui.env -p 8888:8888 -p 7860:7860 -p 8188:8188 -v comfyui_workspace:/workspace -v ./runpod-comfyui/workspace:/workspace_template:ro migdrp/runpod:comfyui
```
    *   `--env-file envs/runpod-comfyui.env`: Carga las variables desde el archivo de entorno centralizado.
    *   `-v comfyui_workspace:/workspace`: Monta un volumen nombrado `comfyui_workspace` para persistencia. **Se recomienda usar volúmenes nombrados en lugar de `workspace` genérico para evitar conflictos entre tags.**
    *   `-v ./runpod-comfyui/workspace:/workspace_template:ro`: Monta la carpeta local de scripts como plantilla de solo lectura.

**B) Ejecutar desde la Carpeta Específica (`runpod-comfyui`)**:
Utiliza un archivo `.env` local dentro de esa carpeta.

1.  **Preparar Archivo de Entorno (`.env`)**:
    *   Dentro de la carpeta `runpod-comfyui`, copia el archivo de ejemplo si no existe: `cp .env.example .env` (o crea uno).
    *   Edita el archivo `.env` y añade tu contraseña para Jupyter (`JUPYTER_PASSWORD`) y, opcionalmente, tu token de Hugging Face (`HUGGINGFACE_TOKEN`).

2.  **Ejecutar el Contenedor**:
    ```bash
cd runpod-comfyui && docker run -it --rm --name migdrp-runpod-comfyui --gpus all --env-file .env -p 8888:8888 -p 7860:7860 -p 8188:8188 -v comfyui_workspace:/workspace -v ./workspace:/workspace_template:ro migdrp/runpod:comfyui && cd ..
```
    *   `--env-file .env`: Carga las variables desde el archivo `.env` local.
    *   `-v ./workspace:/workspace_template:ro`: Monta la carpeta local de scripts (relativa a `runpod-comfyui`).

**Parámetros Comunes**:
*   `-it`: Modo interactivo.
*   `--rm`: Elimina el contenedor al detenerlo (útil para pruebas). Omítelo para persistencia.
*   `--name migdrp-runpod-comfyui`: Nombre del contenedor.
*   `--gpus all`: Habilita el acceso a todas las GPUs NVIDIA (requiere NVIDIA Container Toolkit).
*   `-p PUERTO_HOST:PUERTO_CONTENEDOR`: Mapea los puertos.

Consulta la guía [Flujo de Trabajo Docker](../../docs/docker_workflow.md) para entender mejor cómo funcionan las actualizaciones y los volúmenes.

3.  **Ejecutar el Contenedor de Forma Persistente (Sin `--rm`)**:
    Si quieres que el contenedor permanezca después de detenerlo (para poder reiniciarlo rápidamente sin recrearlo), simplemente omite la opción `--rm` en cualquiera de los comandos `docker run` anteriores.

    *   Para detener el contenedor (sin eliminarlo): `docker stop migdrp-runpod-comfyui`
    *   Para volver a iniciarlo (usará el mismo volumen `comfyui_workspace`): `docker start -ai migdrp-runpod-comfyui` (el `-ai` es para adjuntar la terminal interactiva)
    *   Para eliminarlo manualmente cuando ya no lo necesites: `docker rm migdrp-runpod-comfyui` (asegúrate de detenerlo primero).

## 3. Desplegar en Runpod

1.  **Subir Imagen a Docker Hub**:
    *   Asegúrate de haber construido la imagen (`docker build ...`).
    *   Inicia sesión: `docker login`
    *   Sube la imagen: `docker push migdrp/runpod:comfyui`
    *   (Consulta [Gestión de Docker Hub](../../docs/docker_hub.md) para más comandos).

2.  **Crear Pod en Runpod**:
    *   Ve a Runpod y crea un nuevo Pod (GPU).
    *   **Imagen del Contenedor**: Introduce `migdrp/runpod:comfyui`.
    *   **Almacenamiento del Contenedor**: Asigna suficiente espacio (ej. 50GB o más) al disco que se montará en `/workspace`.
    *   **Puertos TCP Expuestos**: Añade los puertos `8888` (Jupyter), `7860` (Terminal Web) y `8188` (ComfyUI).
    *   **Variables de Entorno**: Define `JUPYTER_PASSWORD` y `HUGGINGFACE_TOKEN` con tus valores.
    *   Configura el resto de opciones (GPU, etc.) y despliega el Pod.