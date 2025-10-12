# tests/test_app.py
import sys
import os
import json
import pytest
from unittest.mock import patch, MagicMock
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data['status'] == 'healthy'
    print("Health endpoint check successful")

def test_root(client):
    res = client.get("/")
    assert res.status_code == 200
    data = res.get_json()
    assert 'service' in data
    assert 'version' in data
    print("Root endpoint check successful")

@patch('boto3.client')
def test_storage_health_success(mock_boto, client):
    mock_s3 = MagicMock()
    mock_s3.list_buckets.return_value = {'Buckets': []}
    mock_boto.return_value = mock_s3

    res = client.get("/storage/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data['status'] == 'healthy'
    assert data['storage'] == 'connected'
    print("Minio connectivity check successful")

@patch('boto3.client')
def test_upload_data(mock_boto, client):
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3

    test_data = {"test": "data"}
    res = client.post("/data", data=json.dumps(test_data), content_type='application/json')
    assert res.status_code == 201
    data = res.get_json()
    assert data['message'] == 'Data uploaded successfully'
    print("Data upload check successful")

@patch('boto3.client')
def test_list_files(mock_boto, client):
    mock_s3 = MagicMock()
    mock_s3.list_objects_v2.return_value = {
        'Contents': [{'Key': 'test_file.json', 'Size': 100}]
    }
    mock_boto.return_value = mock_s3

    res = client.get("/data")
    assert res.status_code == 200
    data = res.get_json()
    assert 'files' in data
    assert data['total_files'] == 1
    print("File listing check successful")
