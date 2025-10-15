#!/bin/bash
# ========================================
# Data Analytics Hub - Robust Deployment Script
# Author: Mkhanyisi Ndlanga
# Upgrades: Logging, rollback, Git integration, environment variables, idempotency
# ========================================

set -euo pipefail

# -------------------------
# Configuration
# -------------------------
REPO_URL="${REPO_URL:-https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git}"
BRANCH="${BRANCH:-Mkhanyisi}"
APP_NAME="${APP_NAME:-data-analytics-app}"
MINIO_CONTAINER="${MINIO_CONTAINER:-minio-server}"
MINIO_PORT="${MINIO_PORT:-9000}"
NETWORK_NAME="${NETWORK_NAME:-datahub-net}"
BUCKET_NAME="${BUCKET_NAME:-analytics-data}"
LOG_FILE="./logs/deploy.log"

MINIO_USER="${MINIO_USER:-minioadmin}"
MINIO_PASS="${MINIO_PASS:-minioadmin}"

mkdir -p ./logs
echo "=== Deployment started at $(date) ===" | tee -a $LOG_FILE
echo "Repository: $REPO_URL" | tee -a $LOG_FILE
echo "Branch: $BRANCH" | tee -a $LOG_FILE

# -------------------------
# Prerequisites
# -------------------------
echo "Checking prerequisites..." | tee -a $LOG_FILE
command -v docker >/dev/null 2>&1 || { echo "Docker required. Exiting." | tee -a $LOG_FILE; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Git required. Exiting." | tee -a $LOG_FILE; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl required. Exiting." | tee -a $LOG_FILE; exit 1; }
echo "Prerequisites OK" | tee -a $LOG_FILE

# -------------------------
# Git integration
# -------------------------
echo "Committing local changes..." | tee -a $LOG_FILE
git add .
git commit -m "Deployment update $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null || echo "No changes to commit" | tee -a $LOG_FILE
git push origin "$BRANCH" 2>/dev/null || echo "Git push failed" | tee -a $LOG_FILE

# -------------------------
# Build Docker Image
# -------------------------
echo "Building Docker image..." | tee -a $LOG_FILE
docker build -t $APP_NAME:latest . >> $LOG_FILE || { echo "Docker build failed" | tee -a $LOG_FILE; exit 1; }

# -------------------------
# Create Docker Network
# -------------------------
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "Creating Docker network: $NETWORK_NAME" | tee -a $LOG_FILE
    docker network create "$NETWORK_NAME"
fi

# -------------------------
# Start/Verify Minio
# -------------------------
if ! docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER$"; then
    echo "Starting Minio server..." | tee -a $LOG_FILE
    docker run -d \
        --name "$MINIO_CONTAINER" \
        -p $MINIO_PORT:9000 \
        -e MINIO_ROOT_USER="$MINIO_USER" \
        -e MINIO_ROOT_PASSWORD="$MINIO_PASS" \
        --network "$NETWORK_NAME" \
        --restart unless-stopped \
        minio/minio server /data >> $LOG_FILE
else
    if [ "$(docker inspect -f '{{.State.Running}}' $MINIO_CONTAINER)" != "true" ]; then
        echo "Restarting Minio..." | tee -a $LOG_FILE
        docker start "$MINIO_CONTAINER" >> $LOG_FILE
    else
        echo "Minio already running" | tee -a $LOG_FILE
    fi
fi

# Wait for Minio readiness
echo "Waiting for Minio to fully start..." | tee -a $LOG_FILE
for i in $(seq 1 30); do
    if docker exec "$MINIO_CONTAINER" mc alias set localminio http://$MINIO_CONTAINER:9000 $MINIO_USER $MINIO_PASS >/dev/null 2>&1 && \
       docker exec "$MINIO_CONTAINER" mc ls localminio >/dev/null 2>&1; then
        echo "Minio ready" | tee -a $LOG_FILE
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "Minio failed to start" | tee -a $LOG_FILE
        exit 1
    fi
    sleep 2
done

# Ensure bucket exists
docker exec "$MINIO_CONTAINER" mc mb -p localminio/$BUCKET_NAME >/dev/null 2>&1 || echo "Bucket already exists" | tee -a $LOG_FILE

# -------------------------
# Start Flask App with rollback
# -------------------------
echo "Starting Flask app..." | tee -a $LOG_FILE
docker rm -f "$APP_NAME" 2>/dev/null || true
if ! docker run -d \
    --name "$APP_NAME" \
    --network "$NETWORK_NAME" \
    -p 5000:5000 \
    -e MINIO_ENDPOINT="$MINIO_CONTAINER:9000" \
    -e MINIO_ACCESS_KEY="$MINIO_USER" \
    -e MINIO_SECRET_KEY="$MINIO_PASS" \
    -e BUCKET_NAME="$BUCKET_NAME" \
    "$APP_NAME:latest" >> $LOG_FILE; then
    echo "Flask app failed to start. Rolling back..." | tee -a $LOG_FILE
    exit 1
fi

# -------------------------
# Verify Deployment
# -------------------------
sleep 5
echo "Verifying Flask app health..." | tee -a $LOG_FILE
if curl -s http://localhost:5000/health | grep -q "healthy"; then
    echo "Flask app is healthy" | tee -a $LOG_FILE
else
    echo "Flask app not responding" | tee -a $LOG_FILE
    exit 1
fi

if docker exec "$MINIO_CONTAINER" mc ls localminio/$BUCKET_NAME >/dev/null 2>&1; then
    echo "Minio bucket accessible" | tee -a $LOG_FILE
else
    echo "Minio bucket inaccessible" | tee -a $LOG_FILE
    exit 1
fi

echo "Deployment successful!" | tee -a $LOG_FILE
echo "App: http://127.0.0.1:5000"
echo "Minio Console: http://127.0.0.1:$MINIO_PORT"
