#!/bin/bash
# bin/deploy.sh - Main deployment automation
# Repository: https://github.com/MkhanyisiNdlanga/rock-paper-scissors-MkhanyisiNdlanga
# Branch: CoT_data-analytics-hub
# Author: Mkhanyisi Ndlanga

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_IMAGE="data-analytics-app:latest"
PREV_IMAGE="data-analytics-app:previous"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-app.sh"
HEALTH_SCRIPT="$SCRIPT_DIR/health-check.sh"
APP_SRC="$PROJECT_ROOT/resources/app.py"

echo "=== Data Analytics Hub Deployment ==="
echo "Repository: https://github.com/MkhanyisiNdlanga/rock-paper-scissors-MkhanyisiNdlanga"
echo "Branch: CoT_data-analytics-hub"
echo ""

# ---- Check prerequisites ----
echo "Checking prerequisites..."
command -v docker >/dev/null || { echo "Docker not found"; exit 1; }
command -v python3 >/dev/null || { echo "Python3 not found"; exit 1; }
echo "Prerequisites OK"

# ---- Lint Python code ----
echo "Linting code..."
python3 -m py_compile "$APP_SRC" || { echo "Python syntax error"; exit 1; }
echo "Lint passed"

# ---- Build Docker image ----
echo "Building Docker image..."
if docker image inspect "$APP_IMAGE" >/dev/null 2>&1; then
    echo "Backing up previous image..."
    docker tag "$APP_IMAGE" "$PREV_IMAGE"
fi
docker build -t "$APP_IMAGE" "$PROJECT_ROOT" || { echo "Docker build failed"; exit 1; }
echo "Docker image built: $APP_IMAGE"

# ---- Deploy stack ----
echo "Deploying stack..."
bash "$DEPLOY_SCRIPT"

# ---- Health check ----
echo "Verifying deployment..."
if bash "$HEALTH_SCRIPT"; then
    echo "Deployment successful"
    docker image rm "$PREV_IMAGE" >/dev/null 2>&1 || true
else
    echo "Deployment failed – rolling back..."
    docker stop analytics-app >/dev/null 2>&1 || true
    docker rm analytics-app >/dev/null 2>&1 || true
    if docker image inspect "$PREV_IMAGE" >/dev/null 2>&1; then
        docker run -d --name analytics-app -p 127.0.0.1:8000:5000 "$PREV_IMAGE"
        echo "Rolled back to previous version"
    fi
    exit 1
fi

echo "=== Deployment Complete ==="
echo "Application: http://127.0.0.1:8000"
echo "Minio Console: http://127.0.0.1:9001"
