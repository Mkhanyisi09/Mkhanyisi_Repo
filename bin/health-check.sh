#!/bin/bash
# ========================================
# Data Analytics Hub - Robust Health Check Script
# Author: Mkhanyisi Ndlanga
# Features: Logging, retries, environment overrides
# ========================================

set -euo pipefail

APP_URL="${APP_URL:-http://localhost:5000}"
MINIO_CONTAINER="${MINIO_CONTAINER:-minio-server}"
BUCKET_NAME="${BUCKET_NAME:-analytics-data}"
LOG_FILE="./logs/health-check.log"

mkdir -p ./logs
echo "=== Health Check started at $(date) ===" | tee -a $LOG_FILE

# ------------------------------
# Check Flask app health
# ------------------------------
echo "Checking Flask app health at $APP_URL..." | tee -a $LOG_FILE
for i in $(seq 1 5); do
    if curl -s "$APP_URL/health" | grep -q "healthy"; then
        echo "Flask app is healthy" | tee -a $LOG_FILE
        break
    else
        echo "Flask app not responding, retrying... ($i/5)" | tee -a $LOG_FILE
        sleep 2
    fi
    if [ "$i" -eq 5 ]; then
        echo "Flask app failed health check" | tee -a $LOG_FILE
        exit 1
    fi
done

# ------------------------------
# Check Minio health
# ------------------------------
echo "Checking Minio container '$MINIO_CONTAINER'..." | tee -a $LOG_FILE
if docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER$"; then
    # Configure mc alias inside Minio container
    docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:9000 minioadmin minioadmin >/dev/null 2>&1

    # Retry bucket access
    for i in $(seq 1 5); do
        if docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
            echo "Minio is running and bucket '$BUCKET_NAME' is accessible" | tee -a $LOG_FILE
            break
        else
            echo "Bucket '$BUCKET_NAME' not accessible, retrying... ($i/5)" | tee -a $LOG_FILE
            sleep 2
        fi
        if [ "$i" -eq 5 ]; then
            echo "Minio bucket health check failed" | tee -a $LOG_FILE
            exit 1
        fi
    done
else
    echo "Minio container '$MINIO_CONTAINER' is not running" | tee -a $LOG_FILE
    exit 1
fi

echo "Health check passed!" | tee -a $LOG_FILE
exit 0
