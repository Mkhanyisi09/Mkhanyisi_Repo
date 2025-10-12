Data Analytics Hub - S3 Data Service


The application is built using a modern containerized architecture with the following components:

1. **Flask API Service**
   - Handles HTTP requests for uploading, listing, retrieving, and deleting data.
   - Connects to Minio S3 storage for all data persistence.
   - Runs in its own Docker container (`data-analytics-app`).

2. **Minio Object Storage**
   - S3-compatible storage solution running in a Docker container (`minio-server`).
   - Stores all JSON data uploaded via the Flask API.
   - Provides a web console for monitoring: `http://localhost:9000`.

3. **Docker Network**
   - `datahub-net` is a custom Docker bridge network.
   - Ensures secure communication between the Flask app and Minio.

4. **Local and Cloud Storage**
   - Minio serves as local object storage (can be extended to cloud S3 later).
   - Data files are uniquely named with timestamps for easy versioning.

5. **Health & Monitoring**
   - Flask app has `/health` and `/storage/health` endpoints.
   - Minio is monitored via container status and the `mc` CLI alias.

# Architecture ( ASCII)

+-------------------+ +-------------------+
| Flask App | <---> | Minio Storage |
| (data-analytics) | | (S3, bucket) |
+-------------------+ +-------------------+
^ ^
| |
HTTP/API S3 API
| |
Users/Clients Admin/Monitoring



Repository & Branch


* Repository: https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git

* Branch: Mkhanyisi merged with main Branch on github


Prerequisites

Docker (Desktop recommended for Windows)

Python 3.11+ (for tests)

Git

Network configuration: ensure Docker networks exist (datahub-net)

Deployment

1. Make scripts executable:

chmod +x bin/*.sh

2. Deployement application:

bash bin/deploy.sh

3. Deployment scripts actions:

* Builds Docker image for Flask app

* Ensures Minio is running

* Creates bucket analytics-data if missing

* Starts Flask app container

* Access services:

* Flask API: http://127.0.0.1:5000

* Minio Web Console: http://127.0.0.1:9000

Health Check

Verify service with:

bash bin/health-check.sh

Expected output:

* Flask app is healthy
* Minio bucket is accessible

Testing 

Run automated Testing:

bash bin/test.sh

* Logs saved to logs/data-app/
* Tests cover health endpoints, storage connection, upload/list/delete of files


Day 2 Operations
Scenario: If Minio becomes unavailable while the app is running

Impact:

Flask application will continue running but cannot perform storage operations (upload/list/retrieve/delete)

Any requests that interact with S3 will fail with 503 errors

Detection:

Monitor /storage/health endpoint (GET /storage/health)

Logs will show connection errors when S3 client fails

Recovery Steps:

1. Restart Minio container:

CMD - docker start minio-server

or , if removed:

docker run -d --name minio-server \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  --network datahub-net \
  quay.io/minio/minio server /data --console-address ":9001"
  
  
  2. ensure bucket exists:
  
  docker exec minio-server mc alias set localminio http://minio-server:9000 minioadmin minioadmin
docker exec minio-server mc mb localminio/analytics-data


3. Application will resume normal operations once storage is available.

Recommendations:

* Set up health monitoring and alerts for Minio
* Consider backup strategies to avoid data loss

Access

Flask App: http://127.0.0.1:5000

Minio Web Console: http://127.0.0.1:9000






