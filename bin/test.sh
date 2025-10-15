#!/bin/bash
# ========================================
# Data Analytics Hub - Robust Test Script
# Author: Mkhanyisi Ndlanga
# Features: Logging, health check integration, CI/CD friendly
# ========================================

set -euo pipefail

LOG_DIR="${LOG_DIR:-$HOME/logs/data-app}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/test_$TIMESTAMP.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"
echo "=== Test run started at $(date) ===" | tee -a "$LOG_FILE"

# -------------------------
# Run Pytest
# -------------------------
echo "Running Python unit tests..." | tee -a "$LOG_FILE"
if command -v pytest >/dev/null 2>&1; then
    pytest --maxfail=1 --disable-warnings --tb=short | tee -a "$LOG_FILE"
    EXIT_CODE=${PIPESTATUS[0]}
else
    echo "pytest not found. Install it with pip install pytest" | tee -a "$LOG_FILE"
    exit 1
fi

# -------------------------
# Run Health Check
# -------------------------
echo "" | tee -a "$LOG_FILE"
echo "Running post-test health check..." | tee -a "$LOG_FILE"
if bash bin/health-check.sh | tee -a "$LOG_FILE"; then
    HEALTH_STATUS=0
else
    HEALTH_STATUS=1
fi

# -------------------------
# Summary & Exit
# -------------------------
echo "" | tee -a "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ] && [ $HEALTH_STATUS -eq 0 ]; then
    e
