[<- Volver a runpod-comfyui.md](../runpod-comfyui.md)

# Uso de los Servicios (ComfyUI)

Una vez que el contenedor está en ejecución (localmente o en Runpod), puedes acceder a los diferentes servicios.

## Acceso a Servicios

*   **Runpod**: Usa los enlaces HTTP proporcionados por Runpod para cada puerto expuesto (`8888` para Jupyter, `7860` para Terminal Web, `8188` para ComfyUI).
*   **Localmente**: Usa los siguientes enlaces en tu navegador:
    *   **ComfyUI**: [http://localhost:8188](http://localhost:8188)
    *   **JupyterLab**: [http://localhost:8888](http://localhost:8888) (Inicia sesión con la `JUPYTER_PASSWORD` definida en el archivo `.env` o `envs/runpod-comfyui.env` que usaste al ejecutar `docker run`).
    *   **Terminal Web**: [http://localhost:7860](http://localhost:7860)

## Gestión de Modelos

ComfyUI requiere modelos preentrenados (checkpoint, VAE, controlnet, etc.). Hay varias formas de obtenerlos:

### 1. Descarga Manual desde JupyterLab o Terminal Web

1. Accede a la terminal de JupyterLab o la Terminal Web
2. Usa comandos como `wget` o `curl` para descargar modelos:
   ```bash
mkdir -p /workspace/models/checkpoints && cd /workspace/models/checkpoints && wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
```

### 2. Instalar ComfyUI-Manager

ComfyUI-Manager facilita la descarga e instalación de modelos y extensiones directamente desde la interfaz:

1. Instala ComfyUI-Manager:
   ```bash
cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git && supervisorctl restart comfyui
```
2. Accede a ComfyUI ([http://localhost:8188](http://localhost:8188)) y busca el nodo "Manager" para instalar modelos y extensiones.

### 3. Instalar Configuraciones de Modelos (Model Setups)

Para facilitar la configuración de entornos para modelos específicos (como Wan Video 2.2), puedes usar los scripts proporcionados en el directorio `/workspace/model_setups`.

1.  **Accede a una terminal** (vía JupyterLab o la Terminal Web en el puerto `7860`).
2.  **Lista los scripts disponibles**:
    ```bash
    ls /workspace/model_setups
    ```
3.  **Ejecuta el script deseado**. Por ejemplo, para instalar todo lo necesario para Wan Video 2.2:
    ```bash
    bash /workspace/model_setups/install_wan_video_2.2.sh
    ```
4.  **Sigue las instrucciones del script**. Generalmente, esto implicará:
    *   Esperar a que se descarguen todos los modelos.
    *   Reiniciar ComfyUI: `supervisorctl restart comfyui`.
    *   Abrir la interfaz de ComfyUI, cargar un workflow, y usar el **ComfyUI-Manager** para instalar cualquier nodo personalizado que falte.

## Estructura de Carpetas Recomendada

Para mantener los modelos organizados en ComfyUI, se recomienda la siguiente estructura de carpetas:

```
/workspace/models/
├── checkpoints/      # Modelos principales SD (*.safetensors, *.ckpt)
├── vae/              # Modelos VAE
├── loras/            # Modelos LoRA
├── controlnet/       # Modelos ControlNet
├── upscale_models/   # Modelos de upscaling
└── embeddings/       # Textual Inversion embeddings
```

## Uso de Nodos Personalizados

ComfyUI se puede extender con nodos personalizados:

1. Instalación manual:
   ```bash
cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/AUTOR/NOMBRE-EXTENSION
```

2. Tras la instalación de cualquier nodo personalizado, reinicia ComfyUI:
   ```bash
supervisorctl restart comfyui
```

## Persistencia de Datos

Todos tus datos (modelos, workflows, nodos personalizados) se guardan en el volumen Docker `comfyui_workspace`. Mientras no borres este volumen, tus datos persistirán entre reinicios del contenedor, incluso si usas la opción `--rm`.