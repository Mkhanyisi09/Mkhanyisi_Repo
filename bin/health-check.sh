#!/bin/bash
# bin/health-check.sh - Verify application + Minio health
# Repository: https://github.com/Mkhanyisi09/rock-paper-scissors-MkhanyisiNdlang
# Branch: CoT_data-analytics-hub
# Author: Mkhanyisi Ndlanga

set -euo pipefail

APP_CONTAINER="analytics-app"
MINIO_CONTAINER="minio-server"
APP_URL="http://127.0.0.1:8000"
MINIO_URL="http://127.0.0.1:9000"

echo "Checking containers..."
docker ps | grep "$APP_CONTAINER" >/dev/null || { echo "App not running"; exit 1; }
docker ps | grep "$MINIO_CONTAINER" >/dev/null || { echo "Minio not running"; exit 1; }

echo "Checking app health..."
curl -s -f "$APP_URL/health" >/dev/null || { echo "App health check failed"; exit 1; }

echo "Checking Minio connection..."
curl -s -f "$APP_URL/storage/health" | grep '"status":"healthy"' >/dev/null || { echo "Minio connection failed"; exit 1; }

# Test upload & retrieval
TEST_JSON='{"test":"data"}'
FILENAME="test_$(date +%Y%m%d_%H%M%S).json"

UPLOAD=$(curl -s -X POST -H "Content-Type: application/json" -d "$TEST_JSON" "$APP_URL/data")
echo "$UPLOAD" | grep '"message":"Data uploaded successfully"' >/dev/null || { echo "Upload failed"; exit 1; }

curl -s -f "$APP_URL/data/$FILENAME" >/dev/null || { echo "Retrieve failed"; exit 1; }

# Cleanup test data
curl -s -X DELETE "$APP_URL/data/$FILENAME" >/dev/null || true

echo "Health check passed"
