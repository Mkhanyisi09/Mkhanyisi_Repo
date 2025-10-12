#!/bin/bash
# bin/deploy-app.sh - Start Flask app + Minio
# Author: Mkhanyisi Ndlanga

set -euo pipefail

NETWORK_NAME="analytics-network"
MINIO_CONTAINER="minio-server"
APP_CONTAINER="analytics-app"
VOLUME_NAME="minio-data"

MINIO_USER="minioadmin"
MINIO_PASS="minioadmin"
APP_IMAGE="data-analytics-app:latest"

MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
APP_PORT=5000

echo "Deploying stack..."

# Network & Volume
docker network ls | grep -q "$NETWORK_NAME" || docker network create "$NETWORK_NAME"
docker volume ls | grep -q "$VOLUME_NAME" || docker volume create "$VOLUME_NAME"

# Cleanup old containers
docker rm -f "$MINIO_CONTAINER" 2>/dev/null || true
docker rm -f "$APP_CONTAINER" 2>/dev/null || true

# Start Minio
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

echo "Waiting for Minio to fully start..."
for i in {1..30}; do
    if docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:$MINIO_PORT $MINIO_USER $MINIO_PASS >/dev/null 2>&1; then
        if docker exec "$MINIO_CONTAINER" mc ls localminio >/dev/null 2>&1; then
            echo "Minio is ready"
            break
        fi
    fi
    if [ $i -eq 30 ]; then
        echo "Minio failed to start"
        exit 1
    fi
    sleep 2
done

# Ensure bucket
docker exec "$MINIO_CONTAINER" mc mb -p localminio/data-bucket >/dev/null 2>&1 || true
echo "Bucket created successfully localminio/data-bucket"

# Start Flask App
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
