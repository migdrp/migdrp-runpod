# Entorno de Producción Local para Wan Video 2.2

Este proyecto contiene todo lo necesario para construir y ejecutar un entorno Docker autocontenido para la generación de video con el modelo **Wan Video 2.2 (versión 14B GGUF)**, utilizando ComfyUI como interfaz.

El objetivo es crear una "fábrica" local de contenido de video que pueda ser utilizado en proyectos creativos, como performances audiovisuales con TouchDesigner.

## ✨ Características

- **Modelo Principal**: Wan Video 2.2 14B en formato GGUF (Q4_K_M) para un rendimiento optimizado en GPUs de consumidor.
- **Entorno Aislado**: Todo se ejecuta dentro de un contenedor Docker.
- **Interfaz Web**: Se utiliza [ComfyUI](https://github.com/comfyanonymous/ComfyUI).
- **Automatización**: Incluye un script para descargar todos los modelos necesarios (Unets, VAE, Text Encoders, LoRAs).
- **Persistencia de Datos**: Utiliza un "bind mount" para guardar los datos en una carpeta específica de tu disco duro (ej. `D:\docker-volumes\wan-video-workspace`).

## ⚙️ Prerrequisitos

1.  **Docker Desktop**: Instalado y en ejecución en Windows.
2.  **GPU NVIDIA**: Tarjeta gráfica con al menos **16 GB de VRAM**.
3.  **Drivers NVIDIA**: Drivers actualizados.

---

## 🚀 Guía de Ejecución Local (Windows con Docker Desktop)

Sigue estos pasos para poner en marcha tu estudio de generación de video.

### Paso 1: Preparar el Entorno Local

1.  **Crear la Carpeta del Proyecto**:
    Crea la siguiente estructura de carpetas y archivos en tu ordenador, por ejemplo en `D:\proyectos\runpod-video-wan\`.
    ```
    runpod-video-wan/
    ├── Dockerfile
    ├── supervisord.conf
    └── workspace/
        ├── download_models_wan22.sh
        ├── start-comfyui.sh
        ├── start-jupyter.sh
        └── start.sh
    ```
    *Copia el contenido de los archivos proporcionados en este documento en su lugar correspondiente.*

2.  **Crear la Carpeta de Almacenamiento en el Disco D:**
    Crea la carpeta en tu disco D: donde se guardarán todos los modelos y videos. **Esta es la carpeta que actuará como tu volumen persistente.**
    ```
    # En el explorador de archivos o en una terminal:
    mkdir D:\docker-volumes\wan-video-workspace
    ```

3.  **Crear el Archivo de Entorno (`.env`)**:
    Dentro de la carpeta `runpod-video-wan`, crea un archivo llamado `.env` y añade el siguiente contenido. **Reemplaza los valores de ejemplo por los tuyos.**
    ```env
    # Contraseña para acceder a JupyterLab
    JUPYTER_PASSWORD="tu_contraseña_segura_aqui"

    # Token de Hugging Face para descargas (opcional pero recomendado)
    HUGGINGFACE_TOKEN="hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    ```

### Paso 2: Construir la Imagen Docker

1.  Abre una terminal (PowerShell o CMD).
2.  Navega hasta la carpeta de tu proyecto: `cd D:\proyectos\runpod-video-wan`
3.  Ejecuta el comando de construcción:
    ```bash
    docker build -t migdrp/runpod:video-wan .
    ```

### Paso 3: Ejecutar el Contenedor

1.  En la misma terminal, ejecuta el siguiente comando. Este comando mapea la carpeta que creaste en el disco D: al directorio `/workspace` dentro del contenedor.
    ```bash
    docker run -it --rm --name wan-video-studio --gpus all ^
      --env-file ./.env ^
      -p 8188:8188 -p 8888:8888 -p 7860:7860 ^
      -v D:\docker-volumes\wan-video-workspace:/workspace ^
      -v ${PWD}/workspace:/workspace_template:ro ^
      migdrp/runpod:video-wan
    ```
    *   **Nota:** `^` es el carácter de continuación de línea en CMD/PowerShell. Si usas otra terminal, puede ser `\`.*

### Paso 4: Descargar los Modelos y Ejecutar

1.  Una vez que el contenedor esté en marcha, abre un navegador y ve a la terminal web: `http://localhost:7860`.
2.  Dentro de la terminal, ejecuta el script de descarga. **Esto tardará un tiempo ya que los modelos son grandes.**
    ```bash
    bash /workspace/download_models_wan22.sh
    ```
3.  Cuando termine, reinicia ComfyUI desde esa misma terminal para que cargue los nuevos nodos:
    ```bash
    supervisorctl restart comfyui
    ```
4.  Abre la interfaz de ComfyUI en: `http://localhost:8188`.
5.  Arrastra tu archivo de workflow `.json` a la interfaz.
6.  El **ComfyUI-Manager** detectará los nodos faltantes. Haz clic en **"Install Missing Custom Nodes"**.
7.  Una vez instalados, **reinicia ComfyUI una última vez** (`supervisorctl restart comfyui`).
8.  ¡Listo! El workflow cargará correctamente y podrás empezar a generar videos. Los archivos se guardarán en `D:\docker-volumes\wan-video-workspace\ComfyUI\output`.
