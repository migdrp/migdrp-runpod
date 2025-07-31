[<- Volver a runpod-comfyui.md](../runpod-comfyui.md)
# Explicación de los Scripts para ComfyUI (`.sh`)

Este proyecto utiliza varios scripts Bash (`.sh`) para automatizar la configuración y ejecución de los servicios. Se encuentran principalmente en la carpeta `workspace/` del proyecto local y se copian al contenedor.

## Scripts Principales

*   **`workspace/start.sh`**:
    *   **Punto de Entrada Principal**: Es el script que ejecuta el `CMD` del `Dockerfile`.
    *   **Orquestador**: Llama a otras funciones/scripts para preparar el entorno antes de lanzar Supervisor.
    *   **Limpieza Inicial**: Elimina archivos temporales y libera puertos potencialmente ocupados de ejecuciones anteriores.
    *   **Permisos**: Asegura que los directorios necesarios existan y tengan los permisos correctos (especialmente `/workspace`).
    *   **Copia Inicial de Scripts**: Copia los scripts de `/workspace_template/` (desde la imagen) a `/workspace` (el volumen) *solo si no existen* en el volumen. Esto permite persistencia y actualizaciones controladas. (Nota: Ya no intenta eliminar `/workspace_template` después de copiar, ya que se monta como solo lectura).
    *   **Verificación de Venv (Jupyter)**: Comprueba si el entorno virtual de Jupyter existe y lo recrea si es necesario.
    *   **Lanzamiento de Supervisor**: Finalmente, ejecuta `supervisord` para que este gestione los servicios definidos en `supervisord.conf`.

*   **`workspace/start-jupyter.sh`**:
    *   **Gestionado por Supervisor**: Se ejecuta como el servicio `[program:jupyter]`.
    *   **Configuración de Jupyter**:
        *   Activa el venv de Jupyter (`/opt/venv/jupyter`).
        *   Configura el tema oscuro.
        *   Genera `jupyter_server_config.py` si no existe.
        *   Configura el servidor Jupyter (IP, puerto, contraseña basada en la variable de entorno `JUPYTER_PASSWORD` proporcionada al contenedor, CORS, etc.).
    *   **Lanzamiento de JupyterLab**: Inicia el proceso `jupyter lab` escuchando en el puerto 8888.

*   **`workspace/start-comfyui.sh`**:
    *   **Gestionado por Supervisor**: Se ejecuta como el servicio `[program:comfyui]`.
    *   **Tareas Principales**:
        *   **Verificación del Venv**: Comprueba si el venv pre-instalado en `/opt/comfyui_env/venv` existe.
        *   **Clonación/Actualización del Código Fuente**: Clona el repositorio `ComfyUI` en el directorio de trabajo `/workspace/ComfyUI` (en el volumen persistente) si no existe, o realiza `git pull` para actualizarlo. Esto permite al usuario ver y modificar el código fuente fácilmente.
        *   **Activación del Venv Pre-instalado**: Activa el entorno virtual desde `/opt/comfyui_env/venv/bin/activate`.
        *   **Configuración Dinámica**:
            *   Configura el token de Hugging Face (`/root/.huggingface/token`) si la variable de entorno `HUGGINGFACE_TOKEN` está definida (proporcionada al contenedor).
            *   Asegura que las carpetas para modelos y resultados existan.
        *   **Liberación de Puerto**: Intenta liberar el puerto `8188` si está en uso.
    *   **Lanzamiento de ComfyUI**: Ejecuta la aplicación principal utilizando el intérprete y las bibliotecas del venv pre-instalado.

## Otros Archivos Relacionados

*   **`supervisord.conf`**:
    *   Archivo de configuración para Supervisor.
    *   Define cómo Supervisor debe ejecutar y gestionar los servicios `ttyd`, `jupyter` y `comfyui` (comandos, reinicios, logs, etc.).
    *   Configura el servidor de Supervisor y `supervisorctl`.

*   **`Dockerfile`**:
    *   Define cómo construir la imagen Docker.
    *   Instala el sistema base, dependencias (Python, Git, Supervisor, build-essential, etc.), y herramientas (`ttyd`).
    *   **Pre-instalación de Entornos Virtuales**:
        *   Crea y configura el venv base para JupyterLab en `/opt/venv/jupyter`.
        *   **Crea y pre-instala completamente el venv para ComfyUI en `/opt/comfyui_env/venv`**:
            *   Instala la versión específica de PyTorch+CUDA (`torch==2.5.1+cu121`).
            *   Clona temporalmente `ComfyUI` para acceder a sus dependencias.
            *   Instala todas las dependencias necesarias.
            *   Limpia los archivos temporales y la caché de pip.
    *   Copia los archivos de configuración (`supervisord.conf`) y los scripts de `workspace/` (como `start.sh`, `start-jupyter.sh`, `start-comfyui.sh`) a la imagen (en `/workspace_template/` y `/opt/scripts/`).
    *   Define el volumen (`/workspace`), los puertos expuestos, el punto de entrada (`tini`) y el comando por defecto (`/opt/scripts/start.sh supervisor`).