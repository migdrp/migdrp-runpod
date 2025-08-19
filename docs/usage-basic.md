# Guía de Uso: Imagen Basic

Esta guía detalla el uso y la configuración de los servicios para la imagen `migdrp/runpod:basic`.

## Acceso a Servicios

*   **Runpod**: Usa los enlaces HTTP proporcionados por Runpod para cada puerto expuesto (`8888` para Jupyter, `7860` para Terminal Web).
*   **Localmente**: Usa los siguientes enlaces en tu navegador:
    *   **JupyterLab**: `http://localhost:8888` (Inicia sesión con la `JUPYTER_PASSWORD`).
    *   **Terminal Web**: `http://localhost:7860`

## Explicación de los Scripts

*   **`start.sh`**: Punto de entrada principal del contenedor. Realiza tareas de limpieza, verifica permisos, copia scripts iniciales si es necesario y finalmente lanza `supervisord`.
*   **`start-jupyter.sh`**: Gestionado por Supervisor. Configura e inicia el servidor de JupyterLab, aplicando la contraseña de la variable de entorno `JUPYTER_PASSWORD`.

## Desarrollo y Persistencia

*   **Instalación de Paquetes**: Para instalar paquetes de Python de forma permanente, usa el pip del entorno virtual:
    ```bash
    /opt/venv/jupyter/bin/pip install pandas matplotlib
    ```
*   **Persistencia de Datos**: Todos los archivos creados en `/workspace` (notebooks, scripts, datos) se guardan en el volumen Docker (`basic_workspace` por defecto), persistiendo entre reinicios del contenedor.