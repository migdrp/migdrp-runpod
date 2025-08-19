# Guía de Uso: Imagen FluxGym

Esta guía detalla el uso y la configuración de los servicios para la imagen `migdrp/runpod:fluxgym`.

## Acceso a Servicios

*   **Runpod**: Usa los enlaces HTTP proporcionados por Runpod para cada puerto (`7862` para FluxGym, `8888` para Jupyter, `7860` para Terminal Web).
*   **Localmente**:
    *   **FluxGym UI**: `http://localhost:7862`
    *   **JupyterLab**: `http://localhost:8888`
    *   **Terminal Web**: `http://localhost:7860`

## Flujo de Trabajo Recomendado

1.  **Descargar Modelos**: Accede a una terminal y ejecuta el script de descarga:
    ```bash
    bash /workspace/download_models.sh
    ```
    Esto descargará los modelos necesarios (como SD3 Medium) a `/workspace/models/`.
2.  **Usar la Interfaz**: Abre la UI de FluxGym para configurar tu dataset y parámetros de entrenamiento.
3.  **Entrenamiento CLI (Opcional)**: Para un mayor control, puedes ejecutar el entrenamiento desde la línea de comandos usando el script `train.sh` que FluxGym genera en la carpeta de salida de tu trabajo.

## Explicación de los Scripts

*   **`start.sh`**: Orquestador principal. Limpia, fija permisos, copia scripts y lanza `supervisord`.
*   **`start-jupyter.sh`**: Inicia el servidor JupyterLab.
*   **`start-fluxgym.sh`**: Clona o actualiza el código fuente de `fluxgym` y `sd-scripts` en `/workspace/fluxgym`, activa el entorno virtual pre-instalado y lanza la aplicación web de Gradio.
*   **`download_models.sh`**: Script manual para descargar los checkpoints, VAEs y otros modelos necesarios para FluxGym.