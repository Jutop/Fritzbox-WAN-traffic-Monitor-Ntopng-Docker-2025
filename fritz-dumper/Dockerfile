FROM ntop/ntopng:latest

# Switch to root to install packages
USER root

# Install the necessary tools for Fritz!Box communication
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    perl \
    libdigest-md5-perl \
    && rm -rf /var/lib/apt/lists/*

# Copy the scripts into the container
COPY fritzdump.sh /usr/local/bin/fritzdump.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/fritzdump.sh /usr/local/bin/entrypoint.sh

# Expose ntopng web interface port
EXPOSE 3000

# Override the ntopng image entrypoint completely
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
