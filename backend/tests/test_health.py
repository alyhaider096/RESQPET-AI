"""
Health Check Endpoint Tests

Original work for ResQ Pet AI Hackathon (October 2026)
"""

import pytest

from app.database import normalize_database_url


def test_database_readiness(client):
    response = client.get("/health/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "ready", "database": "reachable"}


def test_postgresql_provider_urls_use_installed_driver():
    for prefix in ("postgres://", "postgresql://"):
        assert normalize_database_url(f"{prefix}user:pass@host/db") == (
            "postgresql+psycopg2://user:pass@host/db"
        )


@pytest.mark.unit
def test_health_check_returns_200(client):
    """Test that GET /health returns 200 OK."""
    response = client.get("/health")
    assert response.status_code == 200


@pytest.mark.unit
def test_health_check_returns_json(client):
    """Test that GET /health returns valid JSON."""
    response = client.get("/health")
    assert response.headers["content-type"] == "application/json"
    data = response.json()
    assert isinstance(data, dict)


@pytest.mark.unit
def test_health_check_contains_status(client):
    """Test that health check response contains status field."""
    response = client.get("/health")
    data = response.json()
    assert "status" in data
    assert data["status"] == "healthy"


@pytest.mark.unit
def test_health_check_contains_environment(client):
    """Test that health check response contains environment field."""
    response = client.get("/health")
    data = response.json()
    assert "environment" in data
    assert isinstance(data["environment"], str)


@pytest.mark.unit
def test_health_check_contains_version(client):
    """Test that health check response contains version field."""
    response = client.get("/health")
    data = response.json()
    assert "version" in data
    assert data["version"] == "0.1.0"


@pytest.mark.unit
def test_health_check_contains_service_name(client):
    """Test that health check response contains service field."""
    response = client.get("/health")
    data = response.json()
    assert "service" in data
    assert isinstance(data["service"], str)


@pytest.mark.unit
def test_root_endpoint_returns_200(client):
    """Test that GET / returns 200 OK."""
    response = client.get("/")
    assert response.status_code == 200


@pytest.mark.unit
def test_root_endpoint_contains_message(client):
    """Test that root endpoint returns API information."""
    response = client.get("/")
    data = response.json()
    assert "message" in data
    assert "version" in data
    assert "health" in data
