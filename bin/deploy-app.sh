#!/bin/bash
# ========================================
# Data Analytics Hub - Deployment Script
# ========================================
# Author: Mkhanyisi Ndlanga
# Description: Deploy Flask app + MinIO stack with health checks and rollback

set -euo pipefail

# ------------------------------
# Config
# ------------------------------
APP_NAME="data-analytics-app"
APP_IMAGE="${APP_NAME}:latest"
MINIO_CONTAINER="minio-server"
MINIO_USER="minioadmin"
MINIO_PASS="minioadmin"
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
NETWORK_NAME="datahub-net"
BUCKET_NAME="analytics-data"
VOLUME_NAME="minio-data"

# ------------------------------
# Functions
# ------------------------------
log() {
    echo -e "\033[1;34m[INFO] $1\033[0m"
}

error() {
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
}

rollback() {
    log "Rolling back..."
    docker rm -f "$APP_NAME" 2>/dev/null || true
    docker rm -f "$MINIO_CONTAINER" 2>/dev/null || true
    log "Rollback complete."
    exit 1
}

# ------------------------------
# Prerequisites
# ------------------------------
command -v docker >/dev/null 2>&1 || { error "Docker is required. Exiting."; exit 1; }

# ------------------------------
# Build Flask Docker image
# ------------------------------
log "Building Flask app Docker image..."
docker build -t "$APP_IMAGE" . || { error "Failed to build Docker image"; rollback; }

# ------------------------------
# Create network & volume
# ------------------------------
docker network ls | grep -q "$NETWORK_NAME" || docker network create "$NETWORK_NAME"
docker volume ls | grep -q "$VOLUME_NAME" || docker volume create "$VOLUME_NAME"

# ------------------------------
# Stop old containers
# ------------------------------
docker rm -f "$APP_NAME" 2>/dev/null || true
docker rm -f "$MINIO_CONTAINER" 2>/dev/null || true

# ------------------------------
# Start MinIO
# ------------------------------
log "Starting MinIO container..."
docker run -d \
    --name "$MINIO_CONTAINER" \
    --network "$NETWORK_NAME" \
    -p "$MINIO_PORT:9000" \
    -p "$MINIO_CONSOLE_PORT:9001" \
    -v "$VOLUME_NAME:/data" \
    -e MINIO_ROOT_USER="$MINIO_USER" \
    -e MINIO_ROOT_PASSWORD="$MINIO_PASS" \
    --restart unless-stopped \
    minio/minio server /data --console-address ":9001" || { error "Failed to start MinIO"; rollback; }

# Wait for MinIO to be ready
log "Waiting for MinIO to fully start..."
for i in {1..30}; do
    if docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:9000 $MINIO_USER $MINIO_PASS >/dev/null 2>&1; then
        if docker exec "$MINIO_CONTAINER" mc ls localminio >/dev/null 2>&1; then
            log "MinIO is ready"
            break
        fi
    fi
    if [ $i -eq 30 ]; then
        error "MinIO failed to start"
        rollback
    fi
    sleep 2
done

# Ensure bucket exists
docker exec "$MINIO_CONTAINER" mc mb -p localminio/$BUCKET_NAME >/dev/null 2>&1 || log "Bucket already exists"

# ------------------------------
# Start Flask app
# ------------------------------
log "Starting Flask app container..."
docker run -d \
    --name "$APP_NAME" \
    --network "$NETWORK_NAME" \
    -p 5000:5000 \
    -e MINIO_ENDPOINT="http://$MINIO_CONTAINER:9000" \
    -e MINIO_ACCESS_KEY="$MINIO_USER" \
    -e MINIO_SECRET_KEY="$MINIO_PASS" \
    -e BUCKET_NAME="$BUCKET_NAME" \
    --restart unless-stopped \
    "$APP_IMAGE" || { error "Failed to start Flask app"; rollback; }

# ------------------------------
# Health Checks
# ------------------------------
log "Performing health checks..."
sleep 5

APP_HEALTH=$(curl -s http://localhost:5000/health || echo "")
if [[ "$APP_HEALTH" != *"healthy"* ]]; then
    error "Flask app health check failed"
    rollback
fi

if ! docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
    error "MinIO bucket is not accessible"
    rollback
fi

log "Deployment successful!"
log "Flask app: http://127.0.0.1:5000"
log "MinIO Console: http://127.0.0.1:9001"
