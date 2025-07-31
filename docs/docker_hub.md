# Gestión de Docker Hub

[Docker Hub](https://hub.docker.com/) es un registro de imágenes Docker donde puedes almacenar y compartir tus imágenes.

## Comandos Básicos

*   **Iniciar Sesión:**
    Necesitas iniciar sesión con tu cuenta de Docker Hub antes de poder subir imágenes.
    ```bash
docker login
```
    Te pedirá tu nombre de usuario y contraseña (o un token de acceso).

*   **Etiquetar una Imagen:**
    Antes de subir una imagen, debes etiquetarla con el formato `<tu_usuario_dockerhub>/<nombre_repositorio>:<etiqueta>`. Ya lo hacemos durante la construcción con `-t`:
    ```bash
docker build -t migdrp/runpod:tag -f runpod-tag/Dockerfile .
```

*   **Subir (Push) una Imagen:**
    Una vez etiquetada correctamente, puedes subirla a Docker Hub.
    ```bash
docker push migdrp/runpod:tag
```
    Esto subirá la imagen con la etiqueta especificada al repositorio `runpod` bajo el usuario `migdrp`.

## Verificar Repositorios y Etiquetas (Opcional)

Puedes usar herramientas externas como `curl` y `jq` para consultar la API de Docker Hub y verificar qué etiquetas existen en un repositorio.

*   **Listar Etiquetas de un Repositorio:**
    (Requiere `curl` y `jq` instalados en tu sistema local)
    ```bash
REPO=migdrp/runpod && curl -s "https://hub.docker.com/v2/repositories/$REPO/tags/?page_size=100" | jq -r '.results[].name'
```

*   **Verificar si una Etiqueta Específica Existe:**
    ```bash
REPO=migdrp/runpod && TAG=tag && curl --silent -f --head -lL "https://hub.docker.com/v2/repositories/$REPO/tags/$TAG/" > /dev/null && echo "La etiqueta $TAG existe para $REPO" || echo "La etiqueta $TAG NO existe para $REPO"
```