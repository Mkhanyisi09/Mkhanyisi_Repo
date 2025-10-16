#!/bin/bash
# ========================================
# Data Analytics Hub - Health Check Script
# ========================================

APP_URL="http://localhost:5000"
MINIO_CONTAINER="minio-server"
BUCKET_NAME="analytics-data"

echo "[INFO] === Data Analytics Hub Health Check ==="

# ------------------------------
# Check Flask app health
# ------------------------------
echo "[INFO] Checking Flask app health at $APP_URL..."
if curl -s $APP_URL/health | grep -q "healthy"; then
    echo "[INFO] Flask app is healthy "
else
    echo "[ERROR] Flask app is not responding "
    exit 1
fi

# ------------------------------
# Check MinIO health
# ------------------------------
echo "[INFO] Checking MinIO container '$MINIO_CONTAINER'..."
if docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER$"; then
    # Configure mc alias
    docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:9000 minioadmin minioadmin >/dev/null 2>&1

    # Check bucket
    if docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
        echo "[INFO] MinIO is running and bucket '$BUCKET_NAME' is accessible "
    else
        echo "[ERROR] MinIO bucket '$BUCKET_NAME' is not accessible "
        exit 1
    fi
else
    echo "[ERROR] MinIO container '$MINIO_CONTAINER' is not running "
    exit 1
fi

echo "[INFO] Health check passed! "
