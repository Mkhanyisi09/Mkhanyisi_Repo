#!/bin/bash
# bin/deploy-app.sh - Robust start of Flask app + Minio
# Author: Mkhanyisi Ndlanga
# Upgraded: Adds logging, rollback, Git integration, and environment variable flexibility

set -euo pipefail

# -------------------------
# Config
# -------------------------
NETWORK_NAME="${NETWORK_NAME:-analytics-network}"
MINIO_CONTAINER="${MINIO_CONTAINER:-minio-server}"
APP_CONTAINER="${APP_CONTAINER:-analytics-app}"
VOLUME_NAME="${VOLUME_NAME:-minio-data}"
APP_IMAGE="${APP_IMAGE:-data-analytics-app:latest}"

MINIO_USER="${MINIO_USER:-minioadmin}"
MINIO_PASS="${MINIO_PASS:-minioadmin}"

MINIO_PORT="${MINIO_PORT:-9000}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9001}"
APP_PORT="${APP_PORT:-5000}"

LOG_FILE="./logs/deploy-app.log"
mkdir -p ./logs
echo "Deployment started at $(date)" | tee -a $LOG_FILE

# -------------------------
# Git integration
# -------------------------
if command -v git >/dev/null 2>&1; then
    echo "Committing local changes..." | tee -a $LOG_FILE
    git add .
    git commit -m "Deployment update $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null || echo "No changes to commit" | tee -a $LOG_FILE
    git push origin Mkhanyisi 2>/dev/null || echo "Git push failed" | tee -a $LOG_FILE
fi

# -------------------------
# Network & Volume
# -------------------------
docker network ls | grep -q "$NETWORK_NAME" || docker network create "$NETWORK_NAME"
docker volume ls | grep -q "$VOLUME_NAME" || docker volume create "$VOLUME_NAME"

# -------------------------
# Cleanup old containers
# -------------------------
docker rm -f "$MINIO_CONTAINER" 2>/dev/null || true
docker rm -f "$APP_CONTAINER" 2>/dev/null || true

# -------------------------
# Start Minio
# -------------------------
echo "Starting Minio..." | tee -a $LOG_FILE
docker run -d \
  --name "$MINIO_CONTAINER" \
  --network "$NETWORK_NAME" \
  -p 127.0.0.1:$MINIO_PORT:$MINIO_PORT \
  -p 127.0.0.1:$MINIO_CONSOLE_PORT:$MINIO_CONSOLE_PORT \
  -v "$VOLUME_NAME:/data" \
  -e MINIO_ROOT_USER="$MINIO_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_PASS" \
  --restart unless-stopped \
  minio/minio server /data --console-address ":$MINIO_CONSOLE_PORT" >> $LOG_FILE

# Wait for Minio readiness
echo "Waiting for Minio..." | tee -a $LOG_FILE
for i in $(seq 1 30); do
    if docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:$MINIO_PORT $MINIO_USER $MINIO_PASS >/dev/null 2>&1 && \
       docker exec "$MINIO_CONTAINER" mc ls localminio >/dev/null 2>&1; then
        echo "Minio is ready" | tee -a $LOG_FILE
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "Minio failed to start" | tee -a $LOG_FILE
        exit 1
    fi
    sleep 2
done

# Ensure bucket exists
docker exec "$MINIO_CONTAINER" mc mb -p localminio/data-bucket >/dev/null 2>&1 || true
echo "Bucket ensured: localminio/data-bucket" | tee -a $LOG_FILE

# -------------------------
# Start Flask App with rollback
# -------------------------
echo "Starting Flask app..." | tee -a $LOG_FILE
if ! docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK_NAME" \
  -p 127.0.0.1:8000:$APP_PORT \
  -e MINIO_ENDPOINT="http://$MINIO_CONTAINER:$MINIO_PORT" \
  -e MINIO_ACCESS_KEY="$MINIO_USER" \
  -e MINIO_SECRET_KEY="$MINIO_PASS" \
  -e BUCKET_NAME="data-bucket" \
  --restart unless-stopped \
  "$APP_IMAGE" >> $LOG_FILE; then
    echo "Flask app failed to start, rolling back..." | tee -a $LOG_FILE
    docker rm -f "$APP_CONTAINER" 2>/dev/null || true
    exit 1
fi

echo "Stack deployed successfully" | tee -a $LOG_FILE
echo "App URL: http://127.0.0.1:8000"
echo "Minio Console: http://127.0.0.1:$MINIO_CONSOLE_PORT"
