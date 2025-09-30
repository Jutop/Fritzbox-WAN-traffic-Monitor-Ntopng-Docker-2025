#!/bin/bash

echo "Starting Fritz!Box Monitor..."

# Ensure we have necessary directories
mkdir -p /var/lib/ntopng /var/run

# Start Redis (required by ntopng)
echo "Starting Redis..."
redis-server --daemonize yes

# Wait a bit for Redis to start
sleep 2

echo "Trying to login into Fritz!Box and start capture..."

# Run our Fritz!Box capture script directly (it will pipe to ntopng)
exec /usr/local/bin/fritzdump.sh