 PULL_REQUEST_NOTES.md 
# City of Cape Town - DevOps Assessment Submission  
**Candidate:** Mkhanyisi Ndlanga  
**Date:** 12 October 2025  

---

## Summary of Implementation Approach  
- Containerized Flask app + MinIO
- Deployment scripts (`deploy.sh`, `deploy-app.sh`) with idempotency & rollback
- Health-check script (`health-check.sh`) for Flask & MinIO
- Unit tests in `tests/test_app.py` including environment variable validation
- `.env` support for automatic MinIO credentials loading
- Added `.env` and `venv/` to repository
- Logging of tests for traceability

---

## Assumptions & Decisions  
- Gunicorn used as production WSGI server
- Ports: Flask (5000), MinIO (9000)
- Custom Docker network `datahub-net`
- `.env` ensures CI/CD consistency  

---

## Known Limitations / Future Improvements  
1. Local Deployment Only

The stack is designed for local testing and development.

Production deployment may require cloud hosting, proper TLS, and scaling strategies.

2. MinIO Secrets

Credentials are currently stored in .env for simplicity.

For production, use a secret manager or environment variables injected securely.

3. Virtual Environment

venv/ is included for full reproducibility.

Consider using requirements.txt for lightweight deployments or CI/CD pipelines.

4. No Orchestration (Docker Compose / Kubernetes)

The stack runs as standalone containers.

Future improvements could include Docker Compose or Kubernetes for multi-container management.

5. Logging & Monitoring

Logs are stored locally in logs/.

Future enhancements could integrate structured logging, monitoring, and alerting (e.g., Prometheus, Grafana).

---

## Instructions to Test

1. Clone repo & checkout branch `Mkhanyisi`
2. Ensure `.env` exists with proper values
3. Deploy stack: `bash bin/deploy.sh`
4. Run tests & health checks: `bash bin/test.sh`
5. Verify Flask app and MinIO endpoints


## Estimated Time Spent  
Approx. **5.5 hours** including testing, debugging, and documentation.  

---

## Testing Instructions  
1. Clone repo:  
   ```bash
   git clone https://github.com/Mkhanyisi09/Mkhanyisi_Repo.git
   cd Mkhanyisi_Repo
   git checkout Mkhanyisi


2.Deploy Locally:

bash bin/deploy.sh

3. Verify health:
 
 bash bin/health-check.sh

4. Test Flask endpoints via
http://127.0.0.1:5000


Day 2 Operations Scenario (Minio Failure)

If Minio becomes unavailable:

Flask app continues to run but data uploads will fail (returns error on Minio API call).

The issue can be detected via:

Health check (bash bin/health-check.sh)

Docker logs or alerting tools.

Recovery steps:

* Restar Minio container
Day 2 Operations Scenario (Minio Failure)

If Minio becomes unavailable:

* Flask app continues to run but data uploads will fail (returns error on Minio API call).

* The issue can be detected via:

* Health check (bash bin/health-check.sh)

* Docker logs or alerting tools.
* Recovery steps:

* Restart Minio container:

docker start minio-server
* If corrupted, redeploy with persistent data volume.
