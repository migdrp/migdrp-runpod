[<- Volver a runpod-fluxgym.md](../runpod-fluxgym.md)
# Flujo de Trabajo con Docker (Para Principiantes)

Entender cómo interactúan la imagen, el contenedor y el volumen es clave para usar este proyecto eficazmente.

## Conceptos Básicos

*   **Imagen Docker (`migdrp/runpod:fluxgym`)**:
    *   Es una plantilla **inmutable** (no cambia una vez construida).
    *   Contiene el sistema operativo base, las dependencias instaladas (`python`, `git`, `jupyter`, etc.) y las **copias iniciales** de los scripts (`start.sh`, etc.) y configuraciones (`supervisord.conf`).
    *   Se crea con el comando `docker build`.

*   **Contenedor Docker (`migdrp-runpod-fluxgym`)**:
    *   Es una instancia **en ejecución** de una imagen.
    *   Es **efímero** por defecto (los cambios dentro se pierden al detenerlo), a menos que uses volúmenes.
    *   Se crea y ejecuta con `docker run`. Puedes detenerlo (`docker stop`), iniciarlo (`docker start`), y eliminarlo (`docker rm`). El flag `--rm` en `docker run` lo elimina automáticamente al detenerse.

*   **Volumen Docker (ej. `fluxgym_workspace`)**:
    *   Es un mecanismo para **persistir datos** fuera del ciclo de vida del contenedor. Se recomienda usar un nombre específico por tag (ej. `fluxgym_workspace`) para evitar conflictos.
    *   Se monta en una ruta específica *dentro* del contenedor (en nuestro caso, `/workspace`).
    *   Los archivos escritos en `/workspace` dentro del contenedor se guardan en el volumen en tu sistema host.
    *   Sobrevive aunque el contenedor se detenga o elimine. Se gestiona con `docker volume create fluxgym_workspace`, `docker volume rm fluxgym_workspace`, `docker volume ls`.

## Ciclo de Vida Típico

**1. Construcción (Crear/Actualizar la Plantilla)**

```bash
# Construye la imagen a partir del Dockerfile
docker build -t migdrp/runpod:fluxgym .
```
*   Esto lee el `Dockerfile` y crea la imagen `migdrp/runpod:fluxgym`.
*   Si cambias el `Dockerfile` o los archivos que copia (como `supervisord.conf`), necesitas reconstruir.
*   Si cambias scripts en `workspace/` y reconstruyes, la *nueva imagen* tendrá las copias actualizadas en `/workspace_template/`.

**2. Primera Ejecución (Con Volumen Nuevo)**

```bash
# Opcional: Crear volumen explícitamente (docker run también lo crea si no existe)
# docker volume create fluxgym_workspace

# Ejecutar por primera vez (ejemplo desde la raíz del repo)
docker run -it --rm --name migdrp-runpod-fluxgym ... -v fluxgym_workspace:/workspace ... migdrp/runpod:fluxgym
```
*   Docker crea el contenedor `migdrp-runpod-fluxgym` desde la imagen.
*   Docker crea el volumen `fluxgym_workspace` (si no existe) y lo monta en `/workspace` del contenedor.
*   El script `start.sh` se ejecuta dentro del contenedor.
*   Detecta que `/workspace` (el volumen) está vacío.
*   **Copia** los scripts (`start.sh`, `start-fluxgym.sh`, etc.) desde `/workspace_template/` (dentro de la imagen) a `/workspace` (el volumen).
*   `start-fluxgym.sh` clona FluxGym, instala dependencias, etc., **dentro del volumen** (`/workspace/fluxgym`).
*   Los servicios (Jupyter, FluxGym UI) se inician.

**3. Ejecuciones Posteriores (Con Volumen Existente)**

```bash
# Detener el contenedor (si usaste --rm, se elimina)
docker stop migdrp-runpod-fluxgym

# Volver a ejecutar (usando el MISMO volumen, ejemplo desde la raíz del repo)
docker run -it --rm --name migdrp-runpod-fluxgym ... -v fluxgym_workspace:/workspace ... migdrp/runpod:fluxgym
```
*   Docker crea un *nuevo* contenedor `migdrp-runpod-fluxgym` desde la imagen.
*   Docker monta el volumen `fluxgym_workspace` **existente** en `/workspace`. Este volumen ya contiene los scripts copiados en la primera ejecución y la instalación de FluxGym.
*   El script `start.sh` se ejecuta.
*   Detecta que `/workspace/start.sh` **ya existe** en el volumen.
*   **NO** copia los scripts desde `/workspace_template/`. Usa los que ya están en el volumen.
*   `start-fluxgym.sh` detecta que `/workspace/fluxgym` existe, ejecuta `git pull` para actualizar y verifica dependencias (más rápido que la primera vez).
*   Los servicios se inician.

**4. Aplicar Actualizaciones**

*   **Si cambiaste `Dockerfile` o `supervisord.conf`**:
    1.  `docker stop migdrp-runpod-fluxgym`
    2.  `docker build [--no-cache] -t migdrp/runpod:fluxgym -f runpod-fluxgym/Dockerfile .` (Reconstruir imagen desde la raíz)
    3.  `docker volume rm fluxgym_workspace` (Eliminar volumen viejo)
    4.  `docker run ...` (Ejecutar con volumen nuevo)

*   **Si cambiaste scripts en `runpod-fluxgym/workspace/` (ej. `start.sh`)**:
    1.  `docker stop migdrp-runpod-fluxgym`
    2.  `docker build -t migdrp/runpod:fluxgym -f runpod-fluxgym/Dockerfile .` (Reconstruir imagen desde la raíz para actualizar `/workspace_template/`)
    3.  `docker volume rm fluxgym_workspace` (Eliminar volumen viejo para forzar la copia)
    4.  `docker run ...` (Ejecutar con volumen nuevo)

*   **Si cambiaste archivos *dentro* del volumen `/workspace` (ej. vía Jupyter)**:
    *   Los cambios ya están guardados. Solo reinicia el contenedor si es necesario:
    *   `docker stop migdrp-runpod-fluxgym`
    *   `docker start migdrp-runpod-fluxgym` (si no usaste `--rm`) o `docker run ...` (si usaste `--rm`).

**5. Limpieza**

```bash
# Detener contenedor
docker stop migdrp-runpod-fluxgym

# Eliminar contenedor (si no usaste --rm)
# docker rm migdrp-runpod-fluxgym

# Eliminar volumen (¡BORRA TODOS LOS DATOS PERSISTENTES DE FLUXGYM!)
docker volume rm fluxgym_workspace

# Eliminar imagen (si ya no la necesitas)
# docker rmi migdrp/runpod:fluxgym

# Limpieza general de Docker (contenedores parados, redes no usadas, imágenes colgantes)
# docker system prune -a --volumes # ¡CUIDADO! Borra TODO lo no usado.