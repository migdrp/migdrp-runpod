# Flujo de Trabajo Recomendado

1.  **Verificar ComfyUI-Manager**: El Manager ya viene pre-instalado. Al iniciar ComfyUI, deberías ver el menú del Manager en la parte inferior.

2.  **Instalar un Set de Modelos**: Usa los scripts preconfigurados para descargar modelos para un caso de uso específico. Por ejemplo, para Wan Video 2.2 (desde la terminal web o Jupyter):
    ```bash
    bash /workspace/model_setups/install_wan_video_2.2.sh
    ```
3.  **Reiniciar y Cargar Workflow**:
    *   Reinicia ComfyUI: `supervisorctl restart comfyui`
    *   Abre la interfaz, arrastra un archivo de workflow `.json`.
    *   Usa el Manager para instalar los nodos personalizados que falten haciendo clic en "Install Missing Custom Nodes".
    *   Reinicia ComfyUI una última vez si es necesario.