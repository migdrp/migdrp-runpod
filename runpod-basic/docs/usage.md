[<- Volver a runpod-basic.md](../runpod-basic.md)

# Uso de los Servicios (Basic)

Una vez que el contenedor está en ejecución (localmente o en Runpod), puedes acceder a los diferentes servicios.

## Acceso a Servicios

*   **Runpod**: Usa los enlaces HTTP proporcionados por Runpod para cada puerto expuesto (`8888` para Jupyter, `7860` para Terminal Web).
*   **Localmente**: Usa los siguientes enlaces en tu navegador:
    *   **JupyterLab**: [http://localhost:8888](http://localhost:8888) (Inicia sesión con la `JUPYTER_PASSWORD` definida en el archivo `.env` o `envs/runpod-basic.env` que usaste al ejecutar `docker run`).
    *   **Terminal Web**: [http://localhost:7860](http://localhost:7860)

## Desarrollo con JupyterLab

La imagen basic es perfecta para desarrollo Python y exploración de datos:

1. **Crear un nuevo Notebook**: En JupyterLab, haz clic en el icono "+" en la barra lateral izquierda y selecciona "Python 3 (ipykernel)".

2. **Instalar Paquetes**: Puedes instalar paquetes adicionales directamente desde un notebook o desde la terminal:
   ```bash
pip install pandas matplotlib seaborn scikit-learn
```

3. **Organización de Archivos**: Todos los archivos se guardan dentro del volumen montado en `/workspace`. Este directorio persiste entre reinicios del contenedor.

## Uso de la Terminal Web (ttyd)

La terminal web proporciona acceso a una terminal completa a través del navegador:

1. **Comandos del Sistema**: Ejecuta comandos de sistema Linux desde cualquier lugar:
   ```bash
ls -la /workspace
```

2. **Edición de Archivos**: Usa editores de texto como `vim` o `nano`:
   ```bash
vim /workspace/mi_script.py
```

3. **Procesos en Segundo Plano**: Inicia procesos de larga duración y mantenlos en ejecución incluso después de cerrar la terminal con `nohup`:
   ```bash
nohup python /workspace/mi_script_largo.py > /workspace/output.log 2>&1 &
```

## Persistencia de Datos

Todos tus datos (notebooks, scripts, resultados) se guardan en el volumen Docker `basic_workspace`. Mientras no borres este volumen, tus datos persistirán entre reinicios del contenedor, incluso si usas la opción `--rm`.

## Instalación de Paquetes Permanentes

Para instalar paquetes que permanezcan después de reiniciar el contenedor:

1. **Usa el entorno virtual de Jupyter**: 
   ```bash
/opt/venv/jupyter/bin/pip install nombre-paquete
```

2. **Alternativa - Crear tu propio entorno virtual**:
   ```bash
python -m venv /workspace/mi_venv && /workspace/mi_venv/bin/pip install nombre-paquete
```
   Y luego para usarlo en notebooks:
   ```python
import sys
sys.path.append('/workspace/mi_venv/lib/python3.10/site-packages')
```