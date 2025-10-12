# tests/test_app.py
import pytest
from app import app
from unittest.mock import patch, MagicMock
import json

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_health(client):
    res = client.get('/health')
    assert res.status_code == 200
    data = res.get_json()
    assert data['status'] == 'healthy'
    assert 'timestamp' in data
    assert data['service'] == 'data-analytics-service'

@patch('app.get_s3_client')
def test_storage_health_success(mock_get_client, client):
    mock_s3 = MagicMock()
    mock_s3.list_buckets.return_value = {'Buckets': []}
    mock_get_client.return_value = mock_s3

    res = client.get('/storage/health')
    assert res.status_code == 200
    data = res.get_json()
    assert data['status'] == 'healthy'
    assert data['storage'] == 'connected'
    assert 'endpoint' in data

@patch('app.get_s3_client')
def test_storage_health_failure(mock_get_client, client):
    mock_s3 = MagicMock()
    mock_s3.list_buckets.side_effect = Exception("Connection failed")
    mock_get_client.return_value = mock_s3

    res = client.get('/storage/health')
    assert res.status_code == 503
    data = res.get_json()
    assert data['status'] == 'unhealthy'
    assert data['storage'] == 'disconnected'
    assert 'Connection failed' in data['error']

@patch('app.get_s3_client')
def test_upload_data(mock_get_client, client):
    mock_s3 = MagicMock()
    mock_get_client.return_value = mock_s3

    payload = {"name": "test", "value": 123}
    res = client.post('/data', data=json.dumps(payload), content_type='application/json')
    assert res.status_code == 201
    data = res.get_json()
    assert 'filename' in data
    assert data['bucket'] == 'analytics-data'
    assert data['message'] == 'Data uploaded'

@patch('app.get_s3_client')
def test_list_files(mock_get_client, client):
    mock_s3 = MagicMock()
    mock_s3.list_objects_v2.return_value = {
        'Contents': [{'Key': 'test_file.json', 'Size': 100, 'LastModified': '2025-10-12T10:00:00'}]
    }
    mock_get_client.return_value = mock_s3

    res = client.get('/data')
    assert res.status_code == 200
    data = res.get_json()
    assert 'files' in data
    assert data['total_files'] == 1
    assert data['bucket'] == 'analytics-data'

@patch('app.get_s3_client')
def test_get_data(mock_get_client, client):
    mock_s3 = MagicMock()
    mock_s3.get_object.return_value = {'Body': MagicMock(read=lambda: b'{"foo": "bar"}')}
    mock_get_client.return_value = mock_s3

    res = client.get('/data/test_file.json')
    assert res.status_code == 200
    data = res.get_json()
    assert data['filename'] == 'test_file.json'
    assert data['data']['foo'] == 'bar'

@patch('app.get_s3_client')
def test_delete_data(mock_get_client, client):
    mock_s3 = MagicMock()
    mock_get_client.return_value = mock_s3

    res = client.delete('/data/test_file.json')
    assert res.status_code == 200
    data = res.get_json()
    assert data['filename'] == 'test_file.json'
    assert data['message'] == 'File deleted'
