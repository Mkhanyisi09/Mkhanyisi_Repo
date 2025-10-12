# Data Analytics Hub - Deployment Instructions

## Prerequisites
- Linux (Ubuntu 20.04+)
- Docker installed and running
- Python 3.11+
- Git

## Deployment Steps
1. Clone repository:
git clone https://github.com/Mkhanyisi09/rock-paper-scissors-MkhanyisiNdlang
git checkout CoT_data-analytics-hub

2. Run deployment script:
Run deployment script:
3. Monitor logs:
tail -f /var/log/data-app/deploy_errors.log


## Running Tests


bin/test.sh

## Post-deployment Verification


bin/health-check.sh


## Rollback
- If deployment fails, `deploy.sh` will automatically rollback to the previous image.
- Check logs at `/var/log/data-app/deploy_errors.log`.

## Troubleshooting
1. **Docker not found**: Ensure Docker is installed (`sudo apt install docker.io`).
2. **Python syntax error**: Fix errors in `resources/app.py`.
3. **Minio not reachable**: Ensure the Minio container is running and ports 9000/9001 are free.

## Day 2 Operations
- **Scenario**: Minio becomes unavailable while the app is running.
- **Detection**: Health checks (`/storage/health`) will fail.
- **Impact**: App cannot store/retrieve data.
- **Recovery**:
  - Restart Minio container: `docker restart minio-server`
  - Re-run health checks
  - Application resumes normal operation
