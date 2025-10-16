#!/bin/bash
# ========================================
# Data Analytics Hub - Deployment Script
# ========================================

REPO_URL="https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git"
BRANCH="Mkhanyisi"
APP_NAME="data-analytics-app"
MINIO_CONTAINER="minio-server"
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
NETWORK_NAME="datahub-net"
BUCKET_NAME="analytics-data"

echo "=== Data Analytics Hub Deployment ==="

# ------------------------------
# Prerequisites
# ------------------------------
command -v docker >/dev/null 2>&1 || { echo "Docker is required. Exiting."; exit 1; }

# ------------------------------
# Build Docker Image
# ------------------------------
docker build -t $APP_NAME:latest .

# ------------------------------
# Cleanup old containers
# ------------------------------
echo "Cleaning up old containers..."
docker rm -f "$APP_NAME" 2>/dev/null || true
docker rm -f "$MINIO_CONTAINER" 2>/dev/null || true

# ------------------------------
# Create Docker Network
# ------------------------------
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    docker network create $NETWORK_NAME
fi

# ------------------------------
# Start Minio Server
# ------------------------------
docker run -d \
    --name $MINIO_CONTAINER \
    -p $MINIO_PORT:9000 \
    -p $MINIO_CONSOLE_PORT:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    --network $NETWORK_NAME \
    -v minio-data:/data \
    --restart unless-stopped \
    minio/minio server /data --console-address ":$MINIO_CONSOLE_PORT"

# Wait for Minio readiness
echo "Waiting for Minio to fully start..."
for i in {1..30}; do
    if docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:9000 minioadmin minioadmin >/dev/null 2>&1; then
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

# Ensure bucket exists
docker exec "$MINIO_CONTAINER" mc mb -p localminio/$BUCKET_NAME >/dev/null 2>&1 || echo "Bucket already exists"

# ------------------------------
# Start Flask App
# ------------------------------
docker run -d \
    --name $APP_NAME \
    --network $NETWORK_NAME \
    -p 5000:5000 \
    -e MINIO_ENDPOINT=http://$MINIO_CONTAINER:9000 \
    -e MINIO_ACCESS_KEY=minioadmin \
    -e MINIO_SECRET_KEY=minioadmin \
    -e BUCKET_NAME=$BUCKET_NAME \
    --restart unless-stopped \
    $APP_NAME:latest

# ------------------------------
# Verify Deployment
# ------------------------------
sleep 5
if curl -s http://localhost:5000/health | grep -q "healthy"; then
    echo "Flask app is healthy "
else
    echo "Flask app is not responding "
    exit 1
fi

if docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
    echo "Minio bucket is accessible "
else
    echo "Minio bucket not accessible "
    exit 1
fi

echo "Deployment successful!"
echo "App: http://127.0.0.1:5000"
echo "Minio Console: http://127.0.0.1:$MINIO_CONSOLE_PORT"
