[<- Volver a runpod-fluxgym.md](../runpod-fluxgym.md)

# Uso de los Servicios

Una vez que el contenedor está en ejecución (localmente o en Runpod), puedes acceder a los diferentes servicios.

## Acceso a Servicios

*   **Runpod**: Usa los enlaces HTTP proporcionados por Runpod para cada puerto expuesto (`8888` para Jupyter, `7860` para Terminal Web, `7862` para FluxGym UI).
*   **Localmente**: Usa los siguientes enlaces en tu navegador:
    *   **FluxGym UI**: [http://localhost:7862](http://localhost:7862)
    *   **JupyterLab**: [http://localhost:8888](http://localhost:8888) (Inicia sesión con la `JUPYTER_PASSWORD` definida en el archivo `.env` o `envs/runpod-fluxgym.env` que usaste al ejecutar `docker run`).
    *   **Terminal Web**: [http://localhost:7860](http://localhost:7860)

## Descarga de Modelos

FluxGym requiere modelos preentrenados (checkpoint, VAE, encoders). Se incluye un script para facilitar la descarga.

1.  **Accede a una terminal**: Usa JupyterLab ([http://localhost:8888](http://localhost:8888)) y abre una nueva terminal, o usa la Terminal Web ([http://localhost:7860](http://localhost:7860)).
2.  **(Opcional) Edita el script**: Si necesitas descargar modelos específicos o desde URLs diferentes, edita el script:
    ```bash
    # Puedes usar 'vim' o el editor de JupyterLab
    vim /workspace/download_models.sh
    ```
3.  **Ejecuta el script**:
    ```bash
    bash /workspace/download_models.sh
    ```
    Los modelos se descargarán en las subcarpetas correspondientes dentro de `/workspace/models/`.

## Entrenamiento vía Línea de Comandos (CLI)

Aunque FluxGym tiene una UI para configurar entrenamientos, a veces es útil lanzar el entrenamiento directamente desde la línea de comandos (por ejemplo, para ver logs más detallados o ejecutarlo en segundo plano).

1.  **Configura en la UI**: Usa la interfaz de FluxGym ([http://localhost:7862](http://localhost:7862) o el enlace de Runpod) para preparar tu dataset y configurar los parámetros de entrenamiento como lo harías normalmente.
2.  **Localiza el Script `train.sh`**: Al preparar el entrenamiento, FluxGym generalmente crea un script llamado `train.sh` dentro de la carpeta de salida del trabajo, por ejemplo: `/workspace/fluxgym/outputs/<nombre_del_trabajo>/train.sh`.
3.  **Ejecuta desde la Terminal**: Accede a una terminal (JupyterLab o Web) y ejecuta el script:
    ```bash
    cd /workspace/fluxgym/outputs/<nombre_del_trabajo>/ && bash train.sh