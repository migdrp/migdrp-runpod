[<- Volver a runpod-fluxgym.md](../runpod-fluxgym.md)
# Explicación de los Scripts (`.sh`)

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

*   **`workspace/start-fluxgym.sh`**:
    *   **Gestionado por Supervisor**: Se ejecuta como el servicio `[program:fluxgym]`.
    *   **Orquestador de Ejecución (Entorno Pre-instalado)**: Este script *ya no instala* dependencias. Asume que el entorno virtual con todas las dependencias (incluyendo PyTorch+CUDA y los requisitos de FluxGym/sd-scripts) ha sido **pre-instalado en `/opt/fluxgym_env/venv` durante el `docker build`**.
    *   **Tareas Principales**:
        *   **Verificación del Venv**: Comprueba si el venv pre-instalado en `/opt/fluxgym_env/venv` existe.
        *   **Clonación/Actualización del Código Fuente**: Clona los repositorios `fluxgym` y `sd-scripts` (rama `sd3`) en el directorio de trabajo `/workspace/fluxgym` (en el volumen persistente) si no existen, o realiza `git pull` para actualizarlos. Esto permite al usuario ver y modificar el código fuente fácilmente.
        *   **Activación del Venv Pre-instalado**: Activa el entorno virtual desde `/opt/fluxgym_env/venv/bin/activate`.
        *   **Configuración Dinámica**:
            *   Configura el token de Hugging Face (`/root/.huggingface/token`) si la variable de entorno `HUGGINGFACE_TOKEN` está definida (proporcionada al contenedor).
            *   Modifica el archivo `app.py` (del código fuente recién clonado/actualizado en `/workspace/fluxgym`) para que la interfaz de Gradio se ejecute en el puerto `7862`, escuche en todas las interfaces (`server_name="0.0.0.0"`) y intente crear un túnel público (`share=True`).
        *   **Liberación de Puerto**: Intenta liberar el puerto `7862` si está en uso.
    *   **Lanzamiento de FluxGym**: Ejecuta la aplicación principal `python app.py` utilizando el intérprete y las bibliotecas del venv pre-instalado.

*   **`workspace/download_models.sh`**:
    *   **Ejecución Manual**: Diseñado para ser ejecutado manualmente por el usuario desde una terminal (Jupyter o Web).
    *   **Descarga de Modelos**: Contiene comandos `wget` para descargar archivos de modelos (checkpoints, VAE, etc.) desde URLs predefinidas (o editables) a las carpetas correspondientes en `/workspace/models/`.
    *   **Verificación**: Comprueba si un archivo ya existe antes de intentar descargarlo.

## Otros Archivos Relacionados

*   **`supervisord.conf`**:
    *   Archivo de configuración para Supervisor.
    *   Define cómo Supervisor debe ejecutar y gestionar los servicios `ttyd`, `jupyter` y `fluxgym` (comandos, reinicios, logs, etc.).
    *   Configura el servidor de Supervisor y `supervisorctl`.

*   **`Dockerfile`**:
    *   Define cómo construir la imagen Docker.
    *   Instala el sistema base, dependencias (Python, Git, Supervisor, build-essential, etc.), y herramientas (`ttyd`).
    *   **Pre-instalación de Entornos Virtuales**:
        *   Crea y configura el venv base para JupyterLab en `/opt/venv/jupyter`.
        *   **Crea y pre-instala completamente el venv para FluxGym en `/opt/fluxgym_env/venv`**:
            *   Instala la versión específica de PyTorch+CUDA (`torch==2.5.1+cu121`).
            *   Clona temporalmente `fluxgym` y `sd-scripts` para acceder a sus `requirements.txt`.
            *   Instala todas las dependencias de `sd-scripts` y `fluxgym` usando `pip install -r ... -c constraints.txt` para asegurar la compatibilidad con la versión de PyTorch instalada.
            *   Limpia los archivos temporales y la caché de pip.
    *   Copia los archivos de configuración (`supervisord.conf`) y los scripts de `workspace/` (como `start.sh`, `start-jupyter.sh`, `start-fluxgym.sh`) a la imagen (en `/workspace_template/` y `/opt/scripts/`).
    *   Define el volumen (`/workspace`), los puertos expuestos, el punto de entrada (`tini`) y el comando por defecto (`/opt/scripts/start.sh supervisor`).