import os
import sys
import pytest

# ========================================
# Data Analytics Hub - Unit Test Suite
# Author: Mkhanyisi Ndlanga
# ========================================

# --- Ensure the app package is importable ---
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# --- Import the Flask app object from app/main.py ---
from app.main import app


# --- Flask Test Client Fixture ---
@pytest.fixture
def client():
    with app.test_client() as client:
        yield client


# --- Health Endpoint Test ---
def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert b"healthy" in response.data


# --- Root Route Test ---
def test_home_route(client):
    response = client.get('/')
    assert response.status_code in (200, 404)


# --- Environment Variable Validation Test ---
def test_minio_env_vars_exist():
    required_vars = ["MINIO_ENDPOINT", "MINIO_ACCESS_KEY", "MINIO_SECRET_KEY", "BUCKET_NAME"]
    for var in required_vars:
        assert var in os.environ, f"Missing environment variable: {var}"
