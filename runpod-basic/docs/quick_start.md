[<- Volver a runpod-basic.md](../runpod-basic.md)

# Inicio Rápido para Basic

Esta guía te muestra cómo construir y ejecutar la imagen Docker básica sin herramientas de IA específicas.

## Prerrequisitos

*   **Docker**: Necesitas tener Docker instalado en tu sistema.

## 1. Construir la Imagen Docker

Puedes construir la imagen desde dos ubicaciones:

**A) Desde la Carpeta Raíz del Repositorio (`migdrp-runpod`)**:
Esta es la forma recomendada, ya que centraliza la gestión.

```bash
docker build -t migdrp/runpod:basic -f runpod-basic/Dockerfile .
```
*   `-t migdrp/runpod:basic`: Asigna el nombre y tag a la imagen.
*   `-f runpod-basic/Dockerfile`: Especifica la ruta al Dockerfile básico.
*   `.`: Indica que el contexto de construcción es la carpeta raíz actual.

**B) Desde la Carpeta Específica (`runpod-basic`)**:
Si prefieres trabajar directamente dentro de la carpeta de la imagen.

```bash
cd runpod-basic && docker build -t migdrp/runpod:basic . && cd ..
```

*Nota: Si modificas el `Dockerfile` y los cambios no parecen aplicarse, reconstruye usando `--no-cache` (ej. `docker build --no-cache ...`) para ignorar las capas cacheadas.*

## 2. Ejecutar Localmente (Para Pruebas)

Puedes ejecutar el contenedor en tu máquina local. Los comandos varían ligeramente dependiendo desde dónde los ejecutes.

**A) Ejecutar desde la Carpeta Raíz del Repositorio (`migdrp-runpod`)**:
Utiliza el archivo de entorno centralizado.

1.  **Preparar Archivo de Entorno**:
    *   Asegúrate de que el archivo `envs/runpod-basic.env` existe y contiene las variables necesarias (ej. `JUPYTER_PASSWORD`). Puedes copiar `envs/runpod-basic.env.example` si no existe.

2.  **Ejecutar el Contenedor**:
    ```bash
docker run -it --rm --name migdrp-runpod-basic --env-file envs/runpod-basic.env -p 8888:8888 -p 7860:7860 -v basic_workspace:/workspace -v ./runpod-basic/workspace:/workspace_template:ro migdrp/runpod:basic
```
    *   `--env-file envs/runpod-basic.env`: Carga las variables desde el archivo de entorno centralizado.
    *   `-v basic_workspace:/workspace`: Monta un volumen nombrado `basic_workspace` para persistencia. **Se recomienda usar volúmenes nombrados en lugar de `workspace` genérico para evitar conflictos entre tags.**
    *   `-v ./runpod-basic/workspace:/workspace_template:ro`: Monta la carpeta local de scripts como plantilla de solo lectura.

**B) Ejecutar desde la Carpeta Específica (`runpod-basic`)**:
Utiliza un archivo `.env` local dentro de esa carpeta.

1.  **Preparar Archivo de Entorno (`.env`)**:
    *   Dentro de la carpeta `runpod-basic`, copia el archivo de ejemplo si no existe: `cp .env.example .env` (o crea uno).
    *   Edita el archivo `.env` y añade tu contraseña para Jupyter (`JUPYTER_PASSWORD`).

2.  **Ejecutar el Contenedor**:
    ```bash
cd runpod-basic && docker run -it --rm --name migdrp-runpod-basic --env-file .env -p 8888:8888 -p 7860:7860 -v basic_workspace:/workspace -v ./workspace:/workspace_template:ro migdrp/runpod:basic && cd ..
```
    *   `--env-file .env`: Carga las variables desde el archivo `.env` local.
    *   `-v ./workspace:/workspace_template:ro`: Monta la carpeta local de scripts (relativa a `runpod-basic`).

**Parámetros Comunes**:
*   `-it`: Modo interactivo.
*   `--rm`: Elimina el contenedor al detenerlo (útil para pruebas). Omítelo para persistencia.
*   `--name migdrp-runpod-basic`: Nombre del contenedor.
*   `-p PUERTO_HOST:PUERTO_CONTENEDOR`: Mapea los puertos.

Consulta la guía [Flujo de Trabajo Docker](../../docs/docker_workflow.md) para entender mejor cómo funcionan las actualizaciones y los volúmenes.

3.  **Ejecutar el Contenedor de Forma Persistente (Sin `--rm`)**:
    Si quieres que el contenedor permanezca después de detenerlo (para poder reiniciarlo rápidamente sin recrearlo), simplemente omite la opción `--rm` en cualquiera de los comandos `docker run` anteriores.

    *   Para detener el contenedor (sin eliminarlo): `docker stop migdrp-runpod-basic`
    *   Para volver a iniciarlo (usará el mismo volumen `basic_workspace`): `docker start -ai migdrp-runpod-basic` (el `-ai` es para adjuntar la terminal interactiva)
    *   Para eliminarlo manualmente cuando ya no lo necesites: `docker rm migdrp-runpod-basic` (asegúrate de detenerlo primero).

## 3. Desplegar en Runpod

1.  **Subir Imagen a Docker Hub**:
    *   Asegúrate de haber construido la imagen (`docker build ...`).
    *   Inicia sesión: `docker login`
    *   Sube la imagen: `docker push migdrp/runpod:basic`
    *   (Consulta [Gestión de Docker Hub](../../docs/docker_hub.md) para más comandos).

2.  **Crear Pod en Runpod**:
    *   Ve a Runpod y crea un nuevo Pod (no necesita GPU).
    *   **Imagen del Contenedor**: Introduce `migdrp/runpod:basic`.
    *   **Almacenamiento del Contenedor**: Asigna suficiente espacio (ej. 10GB o más) al disco que se montará en `/workspace`.
    *   **Puertos TCP Expuestos**: Añade los puertos `8888` (Jupyter) y `7860` (Terminal Web).
    *   **Variables de Entorno**: Define `JUPYTER_PASSWORD` con tu valor.
    *   Configura el resto de opciones y despliega el Pod.