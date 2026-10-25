import os

os.environ.setdefault("APP_ENV", "test")
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_resqpet.db")
os.environ.setdefault("APP_SECRET_KEY", "test-app-secret-000000000000000000000")
os.environ.setdefault("JWT_SECRET_KEY", "test-jwt-secret-000000000000000000000")
os.environ.setdefault("PII_ENCRYPTION_KEY", "test-pii-secret-000000000000000000000")
os.environ.setdefault("PHONE_HASH_SALT", "test-phone-salt-000000000000000000000")
os.environ.setdefault("VAPI_TOOL_SECRET", "test-vapi-secret-000000000000000000000")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app
from app.models import Organization, Role, User
from app.security import create_access_token, hash_password


@pytest.fixture()
def db_session():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    TestingSession = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    Base.metadata.create_all(engine)
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(engine)


@pytest.fixture()
def identities(db_session):
    org = Organization(name="Test NGO", district="Islamabad")
    db_session.add(org)
    db_session.flush()
    users = {}
    for role in [Role.NGO_COORDINATOR, Role.RESCUE_VOLUNTEER, Role.PUBLIC_REPORTER]:
        user = User(
            email=f"{role.value}@example.test",
            full_name=role.value,
            password_hash=hash_password("TestPassword123!"),
            role=role.value,
            organization_id=org.id,
        )
        db_session.add(user)
        users[role.value] = user
    db_session.commit()
    return org, users


@pytest.fixture()
def client(db_session):
    def override_db():
        yield db_session

    app.dependency_overrides[get_db] = override_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def auth_header(user):
    return {"Authorization": f"Bearer {create_access_token(user.id, user.role, user.organization_id)}"}
