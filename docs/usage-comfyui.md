# Guía de Uso: Imagen ComfyUI

Esta guía detalla el uso y la configuración de los servicios para la imagen `migdrp/runpod:comfyui`.

## Acceso a Servicios

*   **Runpod**: Usa los enlaces HTTP proporcionados por Runpod para cada puerto (`8188` para ComfyUI, `8888` para Jupyter, `7860` para Terminal Web).
*   **Localmente**:
    *   **ComfyUI**: `http://localhost:8188`
    *   **JupyterLab**: `http://localhost:8888`
    *   **Terminal Web**: `http://localhost:7860`

## Flujo de Trabajo Recomendado

1.  **Instalar ComfyUI-Manager**: Es la forma más fácil de gestionar nodos personalizados. Desde una terminal:
    ```bash
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git && supervisorctl restart comfyui
    ```
2.  **Instalar un Set de Modelos**: Usa los scripts preconfigurados para descargar modelos para un caso de uso específico. Por ejemplo, para Wan Video 2.2:
    ```bash
    bash /workspace/model_setups/install_wan_video_2.2.sh
    ```
3.  **Reiniciar y Cargar Workflow**:
    *   Reinicia ComfyUI: `supervisorctl restart comfyui`
    *   Abre la interfaz, arrastra un archivo de workflow `.json`.
    *   Usa el Manager para instalar los nodos personalizados que falten.
    *   Reinicia ComfyUI una última vez.

## Explicación de los Scripts

*   **`start.sh`**: Orquestador principal. Limpia, fija permisos, copia scripts (incluyendo `model_setups/`) y lanza `supervisord`.
*   **`start-jupyter.sh`**: Inicia el servidor JupyterLab.
*   **`start-comfyui.sh`**: Clona o actualiza el código fuente de ComfyUI en `/workspace/ComfyUI`, activa el entorno virtual pre-instalado y lanza la aplicación.
*   **`model_setups/*.sh`**: Scripts para descargar conjuntos de modelos y nodos para casos de uso específicos.