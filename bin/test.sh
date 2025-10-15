#!/bin/bash
# ========================================
# Data Analytics Hub - Full Test Script
# ========================================

# --- Set MinIO environment variables for tests ---
export MINIO_ENDPOINT="http://127.0.0.1:9000"
export MINIO_ACCESS_KEY="minioadmin"
export MINIO_SECRET_KEY="minioadmin"
export BUCKET_NAME="analytics-data"

# --- Logging setup ---
LOG_DIR="$HOME/logs/data-app"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/test_$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

echo "=== Running Python unit tests ===" | tee -a "$LOG_FILE"

# --- Run pytest ---
pytest --maxfail=1 --disable-warnings --tb=short | tee -a "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}

# --- Run health checks ---
echo "" | tee -a "$LOG_FILE"
echo "=== Running health checks ===" | tee -a "$LOG_FILE"
bash bin/health-check.sh | tee -a "$LOG_FILE"

# --- Summary ---
echo "" | tee -a "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All tests passed!" | tee -a "$LOG_FILE"
else
    echo "❌ Some tests failed. Check log: $LOG_FILE" | tee -a "$LOG_FILE"
fi

exit $EXIT_CODE
