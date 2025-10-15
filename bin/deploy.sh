#!/bin/bash
# ========================================
# Data Analytics Hub - Robust Deployment Script
# Author: Mkhanyisi Ndlanga
# ========================================

set -euo pipefail

# --- Configuration ---
REPO_URL="https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git"
BRANCH="Mkhanyisi"
APP_NAME="data-analytics-app"
APP_IMAGE="$APP_NAME:latest"
MINIO_CONTAINER="minio-server"
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
NETWORK_NAME="datahub-net"
BUCKET_NAME="analytics-data"
VOLUME_NAME="minio-data"
LOG_DIR="$HOME/logs/data-app"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/deploy_$TIMESTAMP.log"

mkdir -p "$LOG_DIR"

# --- Environment Variables for Flask App ---
export MINIO_ENDPOINT="http://$MINIO_CONTAINER:$MINIO_PORT"
export MINIO_ACCESS_KEY="minioadmin"
export MINIO_SECRET_KEY="minioadmin"
export BUCKET_NAME="$BUCKET_NAME"

# --- Logging helper ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== Starting Deployment ==="

# --- Check prerequisites ---
command -v docker >/dev/null 2>&1 || { log "Docker not found. Exiting."; exit 1; }
log "Prerequisites OK"

# --- Docker network & volume ---
docker network ls | grep -q "$NETWORK_NAME" || docker network create "$NETWORK_NAME"
docker volume ls | grep -q "$VOLUME_NAME" || docker volume create "$VOLUME_NAME"

# --- Backup existing containers for rollback ---
docker ps -a --format '{{.Names}}' | grep -q "^$APP_NAME$" && docker rename "$APP_NAME" "$APP_NAME-backup-$TIMESTAMP"
docker ps -a --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER$" && docker rename "$MINIO_CONTAINER" "$MINIO_CONTAINER-backup-$TIMESTAMP"

# --- Build Flask Docker Image ---
log "Building Docker image $APP_IMAGE..."
docker build -t "$APP_IMAGE" . | tee -a "$LOG_FILE"

# --- Deploy MinIO ---
log "Deploying MinIO..."
docker run -d \
    --name "$MINIO_CONTAINER" \
    --network "$NETWORK_NAME" \
    -p 127.0.0.1:$MINIO_PORT:9000 \
    -p 127.0.0.1:$MINIO_CONSOLE_PORT:9001 \
    -v "$VOLUME_NAME:/data" \
    -e MINIO_ROOT_USER="minioadmin" \
    -e MINIO_ROOT_PASSWORD="minioadmin" \
    --restart unless-stopped \
    minio/minio server /data --console-address ":$MINIO_CONSOLE_PORT"

# --- Wait for MinIO ---
log "Waiting for MinIO to start..."
for i in {1..30}; do
    if docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:$MINIO_PORT minioadmin minioadmin >/dev/null 2>&1 \
       && docker exec "$MINIO_CONTAINER" mc ls localminio >/dev/null 2>&1; then
        log "MinIO is ready"
        break
    fi
    [ $i -eq 30 ] && { log "MinIO failed to start. Rolling back."; docker rollback; exit 1; }
    sleep 2
done

# --- Ensure bucket exists ---
docker exec "$MINIO_CONTAINER" mc mb -p localminio/$BUCKET_NAME >/dev/null 2>&1 || log "Bucket $BUCKET_NAME already exists"

# --- Deploy Flask App ---
log "Deploying Flask App..."
docker run -d \
    --name "$APP_NAME" \
    --network "$NETWORK_NAME" \
    -p 127.0.0.1:5000:5000 \
    -e MINIO_ENDPOINT="$MINIO_ENDPOINT" \
    -e MINIO_ACCESS_KEY="$MINIO_ACCESS_KEY" \
    -e MINIO_SECRET_KEY="$MINIO_SECRET_KEY" \
    -e BUCKET_NAME="$BUCKET_NAME" \
    --restart unless-stopped \
    "$APP_IMAGE"

# --- Post-deployment Health Checks ---
log "Running post-deployment health checks..."
sleep 5

FLASK_HEALTH=$(curl -s http://127.0.0.1:5000/health || echo "fail")
if [[ "$FLASK_HEALTH" != *"healthy"* ]]; then
    log "Flask app failed health check. Rolling back..."
    docker rollback
    exit 1
fi

if ! docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
    log "MinIO bucket not accessible. Rolling back..."
    docker rollback
    exit 1
fi

log "✅ Deployment successful!"
log "App: http://127.0.0.1:5000"
log "MinIO Console: http://127.0.0.1:$MINIO_CONSOLE_PORT"

# --- Rollback function ---
docker_rollback() {
    log "Rolling back to previous containers..."
    docker rm -f "$APP_NAME" "$MINIO_CONTAINER" >/dev/null 2>&1 || true
    docker rename "$APP_NAME-backup-$TIMESTAMP" "$APP_NAME" >/dev/null 2>&1 || true
    docker rename "$MINIO_CONTAINER-backup-$TIMESTAMP" "$MINIO_CONTAINER" >/dev/null 2>&1 || true
    docker start "$APP_NAME" >/dev/null 2>&1 || true
    docker start "$MINIO_CONTAINER" >/dev/null 2>&1 || true
    log "Rollback completed."
}
