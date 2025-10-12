# resources/app.py (Flask + Minio robust)
"""
Data Analytics Hub - S3 Data Service
"""

import os
import json
from datetime import datetime
from flask import Flask, jsonify, request
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__)

# Configuration from environment variables
MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT', 'minio-server:9000')
MINIO_ACCESS_KEY = os.getenv('MINIO_ACCESS_KEY', 'minioadmin')
MINIO_SECRET_KEY = os.getenv('MINIO_SECRET_KEY', 'minioadmin')
BUCKET_NAME = os.getenv('BUCKET_NAME', 'analytics-data')

# Reuse S3 client
s3_client = None

def get_s3_client():
    global s3_client
    if s3_client is None:
        s3_client = boto3.client(
            's3',
            endpoint_url=f'http://{MINIO_ENDPOINT}',
            aws_access_key_id=MINIO_ACCESS_KEY,
            aws_secret_access_key=MINIO_SECRET_KEY,
            region_name='us-east-1'
        )
    return s3_client

def ensure_bucket_exists():
    client = get_s3_client()
    try:
        client.head_bucket(Bucket=BUCKET_NAME)
    except ClientError:
        client.create_bucket(Bucket=BUCKET_NAME)
        print(f"Created bucket: {BUCKET_NAME}")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'data-analytics-service'
    }), 200

@app.route('/storage/health', methods=['GET'])
def storage_health():
    """Check Minio health robustly"""
    try:
        client = get_s3_client()
        # Try a lightweight call to check connection
        client.list_buckets()
        return jsonify({
            'status': 'healthy',
            'storage': 'connected',
            'endpoint': MINIO_ENDPOINT
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'storage': 'disconnected',
            'error': str(e)
        }), 503

@app.route('/data', methods=['POST'])
def upload_data():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        filename = f'data_{timestamp}.json'
        client = get_s3_client()
        client.put_object(
            Bucket=BUCKET_NAME,
            Key=filename,
            Body=json.dumps(data),
            ContentType='application/json'
        )
        return jsonify({'message': 'Data uploaded', 'filename': filename, 'bucket': BUCKET_NAME}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/data', methods=['GET'])
def list_data():
    try:
        client = get_s3_client()
        response = client.list_objects_v2(Bucket=BUCKET_NAME)
        files = []
        if 'Contents' in response:
            for obj in response['Contents']:
                files.append({
                    'filename': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'].isoformat()
                })
        return jsonify({
            'bucket': BUCKET_NAME,
            'total_files': len(files),
            'files': files
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/data/<filename>', methods=['GET'])
def get_data(filename):
    try:
        client = get_s3_client()
        response = client.get_object(Bucket=BUCKET_NAME, Key=filename)
        data = json.loads(response['Body'].read().decode('utf-8'))
        return jsonify({'filename': filename, 'data': data}), 200
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchKey':
            return jsonify({'error': 'File not found'}), 404
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/data/<filename>', methods=['DELETE'])
def delete_data(filename):
    try:
        client = get_s3_client()
        client.delete_object(Bucket=BUCKET_NAME, Key=filename)
        return jsonify({'message': 'File deleted', 'filename': filename}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        'service': 'Data Analytics Hub - S3 Data Service',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'storage_health': '/storage/health',
            'upload_data': 'POST /data',
            'list_data': 'GET /data',
            'get_data': 'GET /data/<filename>',
            'delete_data': 'DELETE /data/<filename>'
        }
    }), 200

if __name__ == '__main__':
    try:
        ensure_bucket_exists()
    except Exception as e:
        print(f"Warning: Could not ensure bucket exists: {e}")
    app.run(host='0.0.0.0', port=5000, debug=False)
