# Flujo de Trabajo con Docker (Para Principiantes)

Entender cómo interactúan la imagen, el contenedor y el volumen es clave para usar este proyecto eficazmente.

## Conceptos Básicos

*   **Imagen Docker (`migdrp/runpod:tag`)**:
    *   Es una plantilla **inmutable** (no cambia una vez construida).
    *   Contiene el sistema operativo base, las dependencias instaladas (`python`, `git`, `jupyter`, etc.) y las **copias iniciales** de los scripts (`start.sh`, etc.) y configuraciones (`supervisord.conf`).
    *   Se crea con el comando `docker build`.

*   **Contenedor Docker (`migdrp-runpod-tag`)**:
    *   Es una instancia **en ejecución** de una imagen.
    *   Es **efímero** por defecto (los cambios dentro se pierden al detenerlo), a menos que uses volúmenes.
    *   Se crea y ejecuta con `docker run`. Puedes detenerlo (`docker stop`), iniciarlo (`docker start`), y eliminarlo (`docker rm`). El flag `--rm` en `docker run` lo elimina automáticamente al detenerse.

*   **Volumen Docker (ej. `tag_workspace`)**:
    *   Es un mecanismo para **persistir datos** fuera del ciclo de vida del contenedor. Se recomienda usar un nombre específico por tag (ej. `fluxgym_workspace`, `comfyui_workspace`) para evitar conflictos.
    *   Se monta en una ruta específica *dentro* del contenedor (en nuestro caso, `/workspace`).
    *   Los archivos escritos en `/workspace` dentro del contenedor se guardan en el volumen en tu sistema host.
    *   Sobrevive aunque el contenedor se detenga o elimine. Se gestiona con `docker volume create tag_workspace`, `docker volume rm tag_workspace`, `docker volume ls`.

## Ciclo de Vida Típico

**1. Construcción (Crear/Actualizar la Plantilla)**

```bash
docker build -t migdrp/runpod:tag -f runpod-tag/Dockerfile .
```
*   Esto lee el `Dockerfile` y crea la imagen `migdrp/runpod:tag`.
*   Si cambias el `Dockerfile` o los archivos que copia (como `supervisord.conf`), necesitas reconstruir.
*   Si cambias scripts en `workspace/` y reconstruyes, la *nueva imagen* tendrá las copias actualizadas en `/workspace_template/`.

**2. Primera Ejecución (Con Volumen Nuevo)**

```bash
docker run -it --rm --name migdrp-runpod-tag --gpus all --env-file envs/runpod-tag.env -p PUERTOS -v tag_workspace:/workspace -v ./runpod-tag/workspace:/workspace_template:ro migdrp/runpod:tag
```
*   Docker crea el contenedor `migdrp-runpod-tag` desde la imagen.
*   Docker crea el volumen `tag_workspace` (si no existe) y lo monta en `/workspace` del contenedor.
*   El script `start.sh` se ejecuta dentro del contenedor.
*   Detecta que `/workspace` (el volumen) está vacío.
*   **Copia** los scripts desde `/workspace_template/` (dentro de la imagen) a `/workspace` (el volumen).
*   `start-*.sh` clona repositorios e instala/configura el entorno **dentro del volumen** (`/workspace/`).
*   Los servicios se inician.

**3. Ejecuciones Posteriores (Con Volumen Existente)**

```bash
docker stop migdrp-runpod-tag && docker run -it --rm --name migdrp-runpod-tag --gpus all --env-file envs/runpod-tag.env -p PUERTOS -v tag_workspace:/workspace -v ./runpod-tag/workspace:/workspace_template:ro migdrp/runpod:tag
```
*   Docker crea un *nuevo* contenedor desde la imagen.
*   Docker monta el volumen **existente** en `/workspace`. Este volumen ya contiene los scripts y la instalación.
*   El script `start.sh` se ejecuta.
*   Detecta que `/workspace/start.sh` **ya existe** en el volumen.
*   **NO** copia los scripts desde `/workspace_template/`. Usa los que ya están en el volumen.
*   Los scripts iniciales actualizan los repositorios si es necesario.
*   Los servicios se inician.

**4. Aplicar Actualizaciones**

*   **Si cambiaste `Dockerfile` o `supervisord.conf`**:
    ```bash
docker stop migdrp-runpod-tag && docker build --no-cache -t migdrp/runpod:tag -f runpod-tag/Dockerfile . && docker volume rm tag_workspace && docker run -it --rm --name migdrp-runpod-tag --gpus all --env-file envs/runpod-tag.env -p PUERTOS -v tag_workspace:/workspace -v ./runpod-tag/workspace:/workspace_template:ro migdrp/runpod:tag
```

*   **Si cambiaste scripts en `runpod-tag/workspace/` (ej. `start.sh`)**:
    ```bash
docker stop migdrp-runpod-tag && docker build -t migdrp/runpod:tag -f runpod-tag/Dockerfile . && docker volume rm tag_workspace && docker run -it --rm --name migdrp-runpod-tag --gpus all --env-file envs/runpod-tag.env -p PUERTOS -v tag_workspace:/workspace -v ./runpod-tag/workspace:/workspace_template:ro migdrp/runpod:tag
```

*   **Si cambiaste archivos *dentro* del volumen `/workspace` (ej. vía Jupyter)**:
    ```bash
docker stop migdrp-runpod-tag && docker start migdrp-runpod-tag
```
    O si usaste `--rm`:
    ```bash
docker run -it --rm --name migdrp-runpod-tag --gpus all --env-file envs/runpod-tag.env -p PUERTOS -v tag_workspace:/workspace -v ./runpod-tag/workspace:/workspace_template:ro migdrp/runpod:tag
```

**5. Limpieza**

```bash
docker stop migdrp-runpod-tag && docker rm migdrp-runpod-tag && docker volume rm tag_workspace && docker rmi migdrp/runpod:tag
```

* Detener contenedor: `docker stop migdrp-runpod-tag`
* Eliminar contenedor: `docker rm migdrp-runpod-tag` (si no usaste `--rm`)
* Eliminar volumen: `docker volume rm tag_workspace` (¡BORRA TODOS LOS DATOS PERSISTENTES!)
* Eliminar imagen: `docker rmi migdrp/runpod:tag`
* Limpieza general: `docker system prune -a --volumes` (¡CUIDADO! Borra TODO lo no usado)