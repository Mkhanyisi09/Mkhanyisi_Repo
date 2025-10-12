## Prerequisites
- Linux (Ubuntu 24.04+)
- Docker installed and running
- Python 3.11+
- Git

DEPLOYMENT.md
Data Analytics Hub - Deployment Guide

This document provides the latest details for deploying the Data Analytics Hub - S3 Data Service application.

1. Repository & Branch

Repository: https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git

Branch: Mkhanyisi

2. Prerequisites

Docker installed and running (Docker Desktop recommended for Windows)

Python 3.11+ (used for testing scripts)

Git installed for version control

Network configuration: Ensure Docker networks exist (datahub-net created by deployment script)

3. Environment Configuration
Minio (S3 Storage)

Container Name: minio-server

Ports: 9000 (API), 9001 (Web Console)

Credentials:

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

Bucket Name: analytics-data

Network: datahub-net

Flask App

Container Name: data-analytics-app

Port: 5000

Network: datahub-net

Environment Variables:

MINIO_ENDPOINT=minio-server:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
BUCKET_NAME=analytics-data

4. Deployment Steps

1. Make scripts executable:
chmod +x bin/*.sh

2. Run deployment script
bash bin/deploy.sh

3. Check deployemnet output:
* Flask app health
* Minio bucket accessible

4. Acces service:

* Flask API: http://127.0.0.1:5000
* Minio Console: http://127.0.0.1:9000

5. Health Check
I used the health check script to verify Services:

bash bin/health-check.sh

Expected output:

* Flask app is healthy
* Minio bucket is accessible

Testing 

Run automated tests:
bash bin/test.sh

* Logs saved to logs/data-app/
* Test coverage includes: health endpoints, storage connections, upload/list/delete of files.

7. Notes & Recommendations

* Minio credentials are default (minioadmin:minioadmin) — change for production

* Docker containers must be unique in name; remove old containers if conflicts occur:

docker rm -f minio-server data-analytics-app

* Bucket analytics-data is created automatically if missing

* Flask app now reuses S3 client to avoid connection overhead

8 Git Operations
1. Stage and commit changes:

git add
git commit -m "Update deployment scripts and documentation"

2. Push to Github:

git push origin Mkhanyisi

3. Share repository link with the City of Cape Town:

https://github.com/Mkhanyisi09/Mkhanyisi_Repo
