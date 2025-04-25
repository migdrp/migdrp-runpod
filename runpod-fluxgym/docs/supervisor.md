[<- Volver a runpod-fluxgym.md](../runpod-fluxgym.md)
# Gestión de Procesos con Supervisor

[Supervisor](http://supervisord.org/) es un sistema cliente/servidor que permite monitorizar y controlar procesos en sistemas operativos tipo UNIX. En esta imagen, se utiliza para gestionar los servicios principales:

*   `ttyd`: La terminal web.
*   `jupyter`: El servidor JupyterLab.
*   `fluxgym`: El script que instala/actualiza y ejecuta FluxGym.

Supervisor se encarga de iniciar estos servicios cuando el contenedor arranca y de reiniciarlos automáticamente si fallan.

## Comandos Útiles (`supervisorctl`)

Puedes interactuar con Supervisor usando la herramienta `supervisorctl` desde una terminal dentro del contenedor (ya sea la Terminal Web en el puerto `7860` o conectándote con `docker exec`).

*   **Verificar estado de todos los servicios:**
    Muestra si los servicios están en ejecución (`RUNNING`), detenidos (`STOPPED`), fallaron (`FATAL`), etc.
    ```bash
    supervisorctl status
    ```
    *Salida de ejemplo:*
    ```
    fluxgym                          RUNNING   pid 123, uptime 0:10:15
    jupyter                          RUNNING   pid 124, uptime 0:10:15
    ttyd                             RUNNING   pid 125, uptime 0:10:15
    ```

*   **Ver logs de un servicio específico (últimas líneas):**
    Muestra las últimas líneas de la salida estándar (stdout) o de error (stderr) de un servicio. Útil para ver errores recientes.
    ```bash
    supervisorctl tail fluxgym
    supervisorctl tail jupyter stderr
    ```

*   **Seguir logs de un servicio en tiempo real:**
    Muestra los logs a medida que se generan. Presiona `Ctrl+C` para detener.
    ```bash
    supervisorctl tail -f fluxgym
    ```

*   **Reiniciar un servicio:**
    Detiene y vuelve a iniciar un servicio específico. Útil si un servicio parece bloqueado o quieres que recargue alguna configuración (aunque no todos los servicios recargan configuración al reiniciar).
    ```bash
    supervisorctl restart fluxgym
    ```

*   **Detener un servicio:**
    ```bash
    supervisorctl stop jupyter
    ```

*   **Iniciar un servicio (que estaba detenido):**
    ```bash
    supervisorctl start jupyter
    ```

*   **Reiniciar todos los servicios:**
    ```bash
    supervisorctl restart all
    ```

## Archivo de Configuración

La configuración de Supervisor se encuentra en `/etc/supervisor/conf.d/supervisord.conf` dentro del contenedor. Este archivo define los programas (`[program:...]`) que Supervisor debe gestionar, sus comandos de ejecución, directorios, usuarios, y cómo manejar los logs y reinicios.