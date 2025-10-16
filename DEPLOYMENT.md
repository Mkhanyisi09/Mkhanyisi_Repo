## Prerequisites
- Linux (Ubuntu 24.04+)
- Docker installed and running
- Python 3.11+
- Git


## Repository & Branch

- Repository: `https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git`
- Branch: `Mkhanyisi`

## Deployment Steps

### 1. Clone repository
```bash
git clone https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git
cd Mkhanyisi_Repo
git checkout Mkhanyisi

## Set environment variables
Created a .env file in the root of the repo.
MINIO_ENDPOINT=http://127.0.0.1:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
BUCKET_NAME=analytics-data

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

## Verify deployent

* Flask app: http://127.0.0.1:5000

* MinIO Console: http://127.0.0.1:9000

## RollBack ( If needed)

docker rm -f data-analytics-app
docker rm -f minio-server
docker network rm datahub-net
docker volume rm minio-data
bash bin/deploy.sh

## Troubleshooting

1. Port in use: Stop conflicting container or change ports in deploy.sh.

2. MinIO not accessible: Check .env variables.

3. Flask app not responding: Check logs:

docker logs data-analytics-app

## Day 2 Operations

MinIO becomes unavailable

Detected via bin/health-check.sh

Recover:
docker restart minio-server
bash bin/health-check.sh

