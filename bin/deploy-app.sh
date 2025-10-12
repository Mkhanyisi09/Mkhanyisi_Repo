#!/bin/bash
# Deploy Python Flask app + Minio
# Repository: https://github.com/MkhanyisiNdlanga/rock-paper-scissors-MkhanyisiNdlanga
# Branch: CoT_data-analytics-hub

set -euo pipefail

# ---- Config ----
NETWORK_NAME="analytics-network"
MINIO_CONTAINER="minio-server"
APP_CONTAINER="analytics-app"
VOLUME_NAME="minio-data"

MINIO_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_PASS="${MINIO_ROOT_PASSWORD:-minioadmin}"
APP_IMAGE="${APP_IMAGE:-data-analytics-app:latest}"

MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
APP_PORT=5000

echo "Deploying stack..."
echo "Repo: https://github.com/MkhanyisiNdlanga/rock-paper-scissors-MkhanyisiNdlanga"
echo "Branch: CoT_data-analytics-hub"

# ---- Network & Volume ----
docker network ls | grep -q "$NETWORK_NAME" || docker network create "$NETWORK_NAME"
docker volume ls | grep -q "$VOLUME_NAME" || docker volume create "$VOLUME_NAME"

# ---- Cleanup old containers ----
docker rm -f "$MINIO_CONTAINER" 2>/dev/null || true
docker rm -f "$APP_CONTAINER" 2>/dev/null || true

# ---- Start Minio ----
docker run -d \
  --name "$MINIO_CONTAINER" \
  --network "$NETWORK_NAME" \
  -p 127.0.0.1:$MINIO_PORT:$MINIO_PORT \
  -p 127.0.0.1:$MINIO_CONSOLE_PORT:$MINIO_CONSOLE_PORT \
  -v "$VOLUME_NAME:/data" \
  -e MINIO_ROOT_USER="$MINIO_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_PASS" \
  --restart unless-stopped \
  minio/minio server /data --console-address ":$MINIO_CONSOLE_PORT"

# Wait for Minio ready
echo "Waiting for Minio..."
for i in {1..30}; do
  if curl -s -f http://127.0.0.1:$MINIO_PORT/minio/health/live >/dev/null 2>&1; then
    echo "Minio is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "Minio failed to start"
    exit 1
  fi
  sleep 2
done

# ---- Start Flask App ----
docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK_NAME" \
  -p 127.0.0.1:8000:$APP_PORT \
  -e MINIO_ENDPOINT="http://$MINIO_CONTAINER:$MINIO_PORT" \
  -e MINIO_ACCESS_KEY="$MINIO_USER" \
  -e MINIO_SECRET_KEY="$MINIO_PASS" \
  -e BUCKET_NAME="data-bucket" \
  --restart unless-stopped \
  "$APP_IMAGE"

echo "Stack deployed"
echo "App: http://127.0.0.1:8000"
echo "Minio Console: http://127.0.0.1:$MINIO_CONSOLE_PORT"
