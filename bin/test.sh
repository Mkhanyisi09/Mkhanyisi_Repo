#!/bin/bash
# ========================================
# Data Analytics Hub - Test Script
# ========================================

LOG_DIR="$HOME/logs/data-app"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/test_$TIMESTAMP.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

echo "=== Running Python unit tests ===" | tee -a "$LOG_FILE"

# ------------------------------
# Load environment variables
# ------------------------------
if [ -f .env ]; then
    echo "Loading environment variables from .env" | tee -a "$LOG_FILE"
    export $(grep -v '^#' .env | xargs)
else
    echo "No .env file found! Make sure MINIO vars are set." | tee -a "$LOG_FILE"
fi

# Show loaded variables (for debugging)
echo "Environment variables:" | tee -a "$LOG_FILE"
echo "MINIO_ENDPOINT=$MINIO_ENDPOINT" | tee -a "$LOG_FILE"
echo "MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY" | tee -a "$LOG_FILE"
echo "MINIO_SECRET_KEY=$MINIO_SECRET_KEY" | tee -a "$LOG_FILE"
echo "BUCKET_NAME=$BUCKET_NAME" | tee -a "$LOG_FILE"

# ------------------------------
# Run pytest and capture output
# ------------------------------
pytest --maxfail=1 --disable-warnings --tb=short | tee -a "$LOG_FILE"

# Capture exit code
EXIT_CODE=${PIPESTATUS[0]}

# Run health checks
echo "" | tee -a "$LOG_FILE"
echo "=== Running health checks ===" | tee -a "$LOG_FILE"
bash bin/health-check.sh | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ]; then
    echo "All tests passed!" | tee -a "$LOG_FILE"
else
    echo "Some tests failed. Check log: $LOG_FILE" | tee -a "$LOG_FILE"
fi

exit $EXIT_CODE
