from app.database import normalize_database_url


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

    ready = client.get("/health/ready")
    assert ready.status_code == 200
    assert ready.json() == {"status": "ready", "database": "reachable"}


def test_postgresql_provider_urls_use_installed_driver():
    assert normalize_database_url("postgres://user:pass@host/db") == (
        "postgresql+psycopg2://user:pass@host/db"
    )
    assert normalize_database_url("postgresql://user:pass@host/db") == (
        "postgresql+psycopg2://user:pass@host/db"
    )
