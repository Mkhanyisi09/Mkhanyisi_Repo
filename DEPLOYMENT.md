## Prerequisites
- Docker Docker (Desktop with WSL2 Linux Engine)
- Python 3.14.0
- Git

  **Note:** The original assessment requested a Linux environment.
  Due to limited resources, the stack has been tested and deployed on Windows 11 using Docker Desktop with WSL2 Linux Engine.  
  All bash scripts, Docker images, and Minio storage are fully functional in this environment.  
  The deployment scripts are designed to work without Docker Compose or Kubernetes, in line with the assessment requirements.

## DEPLOYMENT.md
Data Analytics Hub - Deployment Guide
=======

## Repository & Branch

- Repository: `https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git`
- Branch: `Mkhanyisi`

## Deployment Steps

### 1. Clone repository
```bash
git clone https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git
cd Mkhanyisi_Repo
git checkout Mkhanyisi


## Network configuration: Ensure Docker networks exist (datahub-net created by deployment script)

2. Environment Configuration
Minio (S3 Storage)

Container Name: minio-server

Ports: 9000 (API), 9001 (Web Console)

## Credentials:

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

Bucket Name: analytics-data

Network: datahub-net

## Flask App

Container Name: data-analytics-app

Port: 5000

Network: datahub-net

Environment Variables:

MINIO_ENDPOINT=minio-server:9000
=======
Set environment variables
Created a .env file in the root of the repo.
MINIO_ENDPOINT=http://127.0.0.1:9000
Mkhanyisi
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
BUCKET_NAME=analytics-data


Deployment Steps

1. Make scripts executable:
chmod +x bin/*.sh

2. Run deployment script
bash bin/deploy.sh

## Check deployemnet output:
* Flask app health
* Minio bucket accessible

 Acces service

* Flask API: http://127.0.0.1:5000
* Minio Console: http://127.0.0.1:9000

Health Check
I used the health check script to verify Services:

bash bin/health-check.sh

Expected output

* Flask app is healthy
* Minio bucket is accessible

## Testing 

Run automated tests:
=======
## Deploy the stack
bash bin/deploy.sh

* Builds Flask app image
* Start MinIO Container
* Creates bucket analytics-data
* Starts Flacks app Container
* Verifies Services

## Run Tests

bash bin/test.sh

* Runs unit tests & health checks
* Logs output in ~/logs/data-app


## Notes & Recommendations
=======
## Verify deployent


* Flask app: http://127.0.0.1:5000

* MinIO Console: http://127.0.0.1:9000


  docker rm -f minio-server data-analytics-app
=======
## RollBack ( If needed)


docker rm -f data-analytics-app
docker rm -f minio-server
docker network rm datahub-net
docker volume rm minio-data
bash bin/deploy.sh

## Troubleshooting



## Git Operations

1. Stage and commit changes:
=======
1. Port in use: Stop conflicting container or change ports in deploy.sh.


2. MinIO not accessible: Check .env variables.

3. Flask app not responding: Check logs:

docker logs data-analytics-app


## Troubleshoot
    | Issue                            | Fix                                                                                            |                                        |
| -------------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------------------- |
| **Port already in use**          | `netstat -ano                                                                                  | findstr 5000`→`taskkill /PID <pid> /F` |
| **Container name conflict**      | `docker rm -f minio-server data-analytics-app`                                                 |                                        |
| **Flask app cannot reach MinIO** | Ensure both containers are on the same Docker network:<br>`docker network inspect datahub-net` |                                        |
| **WSL or Docker not starting**   | Restart Docker Desktop and ensure WSL integration is enabled for your Linux distro             |                                        |


=======
## Day 2 Operations

MinIO becomes unavailable

Detected via bin/health-check.sh

Recover:
docker restart minio-server
bash bin/health-check.sh


