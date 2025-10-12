#!/bin/bash
# ========================================
# Data Analytics Hub - Deployment Script
# ========================================

REPO_URL="https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git"
BRANCH="Mkhanyisi"
APP_NAME="data-analytics-app"
MINIO_CONTAINER="minio-server"
MINIO_PORT=9000
NETWORK_NAME="datahub-net"
BUCKET_NAME="analytics-data"

echo "=== Data Analytics Hub Deployment ==="
echo "Repository: $REPO_URL"
echo "Branch: $BRANCH"

# ------------------------------
# Prerequisites
# ------------------------------
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "Docker is required. Exiting."; exit 1; }
echo "Prerequisites OK"

# ------------------------------
# Build Docker Image
# ------------------------------
echo "Building Docker image..."
docker build -t $APP_NAME:latest .

# ------------------------------
# Create Docker Network
# ------------------------------
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "Creating Docker network: $NETWORK_NAME"
    docker network create $NETWORK_NAME
fi

# ------------------------------
# Start Minio Server
# ------------------------------
if ! docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER$"; then
    echo "Starting Minio server..."
    docker run -d \
        --name $MINIO_CONTAINER \
        -p $MINIO_PORT:9000 \
        -e MINIO_ROOT_USER=minioadmin \
        -e MINIO_ROOT_PASSWORD=minioadmin \
        --network $NETWORK_NAME \
        minio/minio server /data
else
    # Force restart if stopped
    if [ "$(docker inspect -f '{{.State.Running}}' $MINIO_CONTAINER)" != "true" ]; then
        echo "Restarting Minio server..."
        docker start $MINIO_CONTAINER
    else
        echo "Minio already running"
    fi
fi

# Wait until Minio is ready
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
echo "Ensuring bucket $BUCKET_NAME exists..."
docker exec "$MINIO_CONTAINER" mc mb -p localminio/$BUCKET_NAME >/dev/null 2>&1 || echo "Bucket already exists"

# ------------------------------
# Start Flask App
# ------------------------------
echo "Starting Flask app container..."
docker run -d \
    --name $APP_NAME \
    --network $NETWORK_NAME \
    -p 5000:5000 \
    -e MINIO_ENDPOINT=$MINIO_CONTAINER:9000 \
    -e MINIO_ACCESS_KEY=minioadmin \
    -e MINIO_SECRET_KEY=minioadmin \
    -e BUCKET_NAME=$BUCKET_NAME \
    $APP_NAME:latest

# ------------------------------
# Verify Deployment
# ------------------------------
echo "Verifying deployment..."
sleep 5
if curl -s http://localhost:5000/health | grep -q "healthy"; then
    echo "Flask app is healthy"
else
    echo "Flask app is not responding"
    exit 1
fi

if docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
    echo "Minio bucket is accessible"
else
    echo "Minio bucket not accessible"
    exit 1
fi

echo "Deployment successful!"
echo "App: http://127.0.0.1:5000"
echo "Minio Console: http://127.0.0.1:9000"
