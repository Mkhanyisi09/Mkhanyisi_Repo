import os
from flask import Flask, jsonify
from minio import Minio
from minio.error import S3Error

# -----------------------------
# App and MinIO setup
# -----------------------------
app = Flask(__name__)

# Environment variables for MinIO
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9000")  # no http://
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")
BUCKET_NAME = os.getenv("BUCKET_NAME", "analytics-data")

# MinIO client
minio_client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=False  # because using HTTP
)

# -----------------------------
# Health endpoint
# -----------------------------
@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

# -----------------------------
# Example bucket creation
# -----------------------------
def ensure_bucket(bucket_name):
    try:
        if not minio_client.bucket_exists(bucket_name):
            minio_client.make_bucket(bucket_name)
            print(f"Bucket '{bucket_name}' created")
        else:
            print(f"ℹ Bucket '{bucket_name}' already exists")
    except S3Error as e:
        print(f"MinIO error: {e}")

# Ensure bucket at startup
ensure_bucket(BUCKET_NAME)

# -----------------------------
# Example API
# -----------------------------
@app.route("/ping")
def ping():
    return jsonify({"message": "pong"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
