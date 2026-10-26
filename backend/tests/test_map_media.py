from app.models import Role
from tests.conftest import auth_header
from tests.test_rescue_api import rescue_payload


def test_map_shares_only_active_org_pins_without_reporter_data(client, identities):
    org, users = identities
    reporter = auth_header(users[Role.PUBLIC_REPORTER.value])
    case = client.post(
        "/api/v1/cases", headers=reporter, json=rescue_payload(org.id, latitude=33.68, longitude=73.04)
    ).json()
    response = client.get("/api/v1/map/cases", headers=reporter)
    assert response.status_code == 200
    pin = response.json()[0]
    assert pin["case_reference"] == case["case_reference"]
    assert pin["latitude"] == 33.68
    assert "reporter_phone" not in pin and "reporter_user_id" not in pin
    assert client.get("/api/v1/map/cases").status_code == 401


def test_photo_is_authenticated_and_content_validated(client, identities):
    org, users = identities
    reporter = auth_header(users[Role.PUBLIC_REPORTER.value])
    coordinator = auth_header(users[Role.NGO_COORDINATOR.value])
    case = client.post("/api/v1/cases", headers=reporter, json=rescue_payload(org.id)).json()
    path = f"/api/v1/cases/{case['id']}/photo"
    assert (
        client.post(path, headers=reporter, files={"file": ("bad.jpg", b"not an image")}).status_code == 415
    )
    image = b"\x89PNG\r\n\x1a\n" + b"demo"
    assert client.post(path, headers=reporter, files={"file": ("demo.png", image)}).status_code == 200
    assert client.get(path).status_code == 401
    response = client.get(path, headers=coordinator)
    assert response.status_code == 200 and response.content == image
    assert response.headers["cache-control"] == "private, no-store"
    assert client.get(f"/api/v1/cases/{case['id']}", headers=reporter).json()["photo_count"] == 1
