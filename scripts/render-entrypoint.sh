#!/bin/sh
# =====================================================
# DS2API Render.com Entrypoint
# Generates config.json from environment variables
# =====================================================

set -e

echo "============================================"
echo "  DS2API - Render.com Deployment"
echo "============================================"

# Ensure PORT is set (Render provides this)
if [ -z "$PORT" ]; then
    export PORT=5001
    echo "[entrypoint] PORT not set, defaulting to 5001"
else
    echo "[entrypoint] PORT: $PORT"
fi

# If DS2API_CONFIG_JSON is provided, use it directly
if [ -n "$DS2API_CONFIG_JSON" ]; then
    echo "[entrypoint] Using DS2API_CONFIG_JSON environment variable"
    echo "[entrypoint] Starting DS2API..."
    exec "$@"
fi

# If config file exists, use it
if [ -f "/data/config.json" ]; then
    echo "[entrypoint] Using existing config at /data/config.json"
    export DS2API_CONFIG_PATH="/data/config.json"
    echo "[entrypoint] Starting DS2API..."
    exec "$@"
fi

# Otherwise, generate config from environment variables
echo "[entrypoint] Generating config from environment variables..."
mkdir -p /data

python3 /usr/local/bin/generate_config.py

export DS2API_CONFIG_PATH="/data/config.json"
echo "[entrypoint] Config generated at /data/config.json"
echo "[entrypoint] Starting DS2API..."
echo "============================================"

exec "$@"
