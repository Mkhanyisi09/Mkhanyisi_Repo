#!/bin/bash
# ========================================
# Data Analytics Hub - Health Check Script
# ========================================

APP_URL="http://localhost:5000"
MINIO_CONTAINER="minio-server"
BUCKET_NAME="analytics-data"

echo "=== Data Analytics Hub Health Check ==="

# ------------------------------
# Check Flask app health
# ------------------------------
echo "Checking Flask app health..."
if curl -s $APP_URL/health | grep -q "healthy"; then
    echo "Flask app is healthy"
else
    echo "Flask app is not responding"
    exit 1
fi

# ------------------------------
# Check Minio health via container network
# ------------------------------
echo "Checking Minio health..."
if docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER$"; then
    # Configure mc alias inside Minio container
    docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:9000 minioadmin minioadmin >/dev/null 2>&1

    # Check bucket access
    if docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
        echo "Minio is ready and bucket '$BUCKET_NAME' is accessible"
    else
        echo "Minio is running but bucket '$BUCKET_NAME' is not accessible"
        exit 1
    fi
else
    echo "Minio container is not running"
    exit 1
fi

echo "Health check passed!"
