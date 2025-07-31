FROM python:3.10-slim

USER root
ENV HOME=/root \
    JUPYTER_PASSWORD=""
# HUGGINGFACE_TOKEN is not needed for the basic image

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    tini \
    vim \
    supervisor \
    python3-venv \
    procps \
    net-tools \
    lsof `# Added lsof for port checking in start script` \
    && pip install supervisor-stdout \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Create JupyterLab virtual environment with proper permissions
RUN python -m venv /opt/venv/jupyter && \
    chmod -R 755 /opt/venv/jupyter && \
    /opt/venv/jupyter/bin/pip install --no-cache-dir jupyterlab terminado jupyterlab-system-monitor

# Create necessary directories
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/run && \
    mkdir -p /opt/scripts && \
    mkdir -p /workspace_template && \
    mkdir -p /workspace && \
    chmod -R 755 /var/log/supervisor

# Copy scripts and configurations
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY workspace/* /workspace_template/
COPY workspace/* /opt/scripts/

# Set script permissions for both locations
RUN chmod -R +x /workspace_template/*.sh && \
    chmod -R +x /opt/scripts/*.sh && \
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension

VOLUME ["/workspace"]

# Expose only Jupyter and ttyd ports
EXPOSE 8888 7860

WORKDIR /
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/scripts/start.sh", "supervisor"]