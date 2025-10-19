# City of Cape Town Assessment - Data Analytics Hub

This project contains a Flask-based analytics app with MinIO (S3-compatible) storage.  

### Features
- Flask REST API
- MinIO object storage
- Deployment scripts for Docker containers
- Automated tests and health checks
- Full virtual environment included (`venv/`)

**Note:** The stack runs in a Linux environment provided by WSL2.  
All bash scripts, Docker images, and MinIO storage are fully functional, and deployment does not require Docker Compose or Kubernetes.

### Project Structure
Mkhanyisi_Repo/
├── app/
├── bin/
├── logs/
├── tests/
├── venv/
├── .env
├── Dockerfile
├── requirements.txt
├── README.md
└── DEPLOYMENT.md


### Notes
- `.env` and `venv/` are included for full reproducibility
- Logs are written to `logs/`


## Tech Stack

| Component | Description |
|------------|--------------|
| **Python (Flask)** | Web service and API endpoints |
| **MinIO** | Local S3-compatible object storage |
| **Docker** | Containerization and orchestration |
| **Bash scripts** | Deployment, health checks, and testing |
| **GitHub** | Version control and repository management |

---

## Repository Structure

Mkhanyisi_Repo/
├── app/
├── bin/
├── logs/
├── tests/
├── venv/
├── .env
├── Dockerfile
├── requirements.txt
├── README.md
└── DEPLOYMENT.md

### Notes
- `.env` and `venv/` are included for full reproducibility
- Logs are written to `logs/`

## Architecture ( ASCII)

+-------------------+           +-------------------+
|     Flask App     | <-------> |   MinIO Storage   |
|  (data-analytics) |           |     (S3 bucket)   |
+-------------------+           +-------------------+
       ^     ^
       |     |
    HTTP    S3 API
       |     |
  Users / Clients   Admin / Monitoring
  
  ## REST API Endpoints

  | Endpoint           | Method     | Description                                         |
| ------------------ | ---------- | --------------------------------------------------- |
| `/data`            | **POST**   | Uploads a data file to the MinIO S3 bucket          |
| `/data`            | **GET**    | Lists all files stored in the analytics-data bucket |
| `/data/<filename>` | **GET**    | Retrieves a specific file from S3                   |
| `/data/<filename>` | **DELETE** | Deletes a file from the S3 bucket                   |
| `/health`          | **GET**    | Checks the health of the Flask API                  |
| `/storage/health`  | **GET**    | Validates MinIO storage connectivity                |


## Repository & Branch

* Repository: https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git

* Branch: Mkhanyisi merged with main Branch on github

## Deployment

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

## Health Check

Verify service with:

bash bin/health-check.sh

Expected output:

* Flask app is healthy
* Minio bucket is accessible

## Testing 

Run automated Testing:

bash bin/test.sh

* Logs saved to logs/data-app/
* Tests cover health endpoints, storage connection, upload/list/delete of files


## Day 2 Operations
Scenario: If Minio becomes unavailable while the app is running

Impact:

Flask application will continue running but cannot perform storage operations (upload/list/retrieve/delete)

Any requests that interact with S3 will fail with 503 errors

## Detection:

Monitor /storage/health endpoint (GET /storage/health)

Logs will show connection errors when S3 client fails

## Recovery Steps:

1. Restart Minio container:

CMD - docker start minio-server

or , if removed:

docker run -d --name minio-server \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  --network datahub-net \
  quay.io/minio/minio server /data --console-address ":9001"
  
  
  2. Ensure bucket exists:
  
  docker exec minio-server mc alias set localminio http://minio-server:9000 minioadmin minioadmin
docker exec minio-server mc mb localminio/analytics-data


3. Application will resume normal operations once storage is available.

## Recommendations:

* Set up health monitoring and alerts for Minio
* Consider backup strategies to avoid data loss
* Use Sumo Logic for centralized logging and monitoring of application and container logs.
* Use Bitwarden to securely manage and store sensitive credentials such as MinIO credentials and Sumo Logic tokens.







