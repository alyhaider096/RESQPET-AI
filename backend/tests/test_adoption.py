from app.models import Organization, RescueCase, Role, User
from tests.conftest import auth_header
from tests.test_rescue_api import rescue_payload


def test_rescued_animal_application_review_and_handover(client, identities, db_session):
    org, users = identities
    coordinator = auth_header(users[Role.NGO_COORDINATOR.value])
    citizen = auth_header(users[Role.PUBLIC_REPORTER.value])
    volunteer = auth_header(users[Role.RESCUE_VOLUNTEER.value])
    created = client.post("/api/v1/cases", json=rescue_payload(org.id), headers=citizen).json()
    data = {
        "case_id": created["id"],
        "animal_name": "Demo companion",
        "description": "A rescued animal looking for a suitable home.",
    }
    assert client.post("/api/v1/adoption/listings", json=data, headers=citizen).status_code == 403
    assert client.post("/api/v1/adoption/listings", json=data, headers=coordinator).status_code == 409
    case = db_session.get(RescueCase, created["id"])
    case.status, case.assigned_volunteer_id = "rescued", users[Role.RESCUE_VOLUNTEER.value].id
    db_session.commit()
    listing = client.post("/api/v1/adoption/listings", json=data, headers=volunteer)
    assert listing.status_code == 201
    item = listing.json()
    path = f"/api/v1/adoption/listings/{item['id']}"
    assert client.post("/api/v1/adoption/listings", json=data, headers=coordinator).status_code == 409
    assert client.post(path + "/complete", headers=coordinator).status_code == 409
    application = client.post(
        path + "/applications",
        json={"message": "I can offer a suitable home and veterinary care."},
        headers=citizen,
    )
    assert application.status_code == 201
    assert (
        client.post(
            path + "/applications", json={"message": "Another duplicate application"}, headers=citizen
        ).status_code
        == 409
    )
    assert client.get("/api/v1/adoption/applications", headers=volunteer).json() == []
    decision_path = "/api/v1/adoption/applications/" + application.json()["id"]
    decision = {"status": "approved", "review_note": "Placement checks completed by the NGO."}
    assert client.patch(decision_path, json=decision, headers=citizen).status_code == 403
    assert client.patch(decision_path, json=decision, headers=coordinator).status_code == 200
    assert client.patch(decision_path, json=decision, headers=coordinator).status_code == 409
    assert client.get("/api/v1/adoption/listings", headers=citizen).json()[0]["status"] == "reserved"
    assert client.post(path + "/complete", headers=coordinator).json()["status"] == "adopted"
    assert client.get("/api/v1/adoption/applications", headers=citizen).json()[0]["status"] == "approved"


def test_adoption_org_boundary_and_competing_applications(client, identities, db_session):
    org, users = identities
    citizen = auth_header(users[Role.PUBLIC_REPORTER.value])
    coordinator = auth_header(users[Role.NGO_COORDINATOR.value])
    case_data = client.post("/api/v1/cases", json=rescue_payload(org.id), headers=citizen).json()
    case = db_session.get(RescueCase, case_data["id"])
    case.status = "closed"
    other_org = Organization(name="Other NGO")
    db_session.add(other_org)
    db_session.flush()
    outsider = User(
        email="other@example.test",
        full_name="Other",
        role=Role.OWNER.value,
        organization_id=other_org.id,
        password_hash="synthetic",
    )
    second = User(
        email="second@example.test",
        full_name="Second",
        role=Role.OWNER.value,
        organization_id=org.id,
        password_hash="synthetic",
    )
    db_session.add_all([outsider, second])
    db_session.commit()
    listing = client.post(
        "/api/v1/adoption/listings",
        headers=coordinator,
        json={"case_id": case.id, "animal_name": "Demo", "description": "Rescued animal placement listing"},
    ).json()
    path = f"/api/v1/adoption/listings/{listing['id']}/applications"
    assert client.get("/api/v1/adoption/listings", headers=auth_header(outsider)).json() == []
    assert (
        client.post(
            path, headers=auth_header(outsider), json={"message": "I would like to apply here."}
        ).status_code
        == 404
    )
    first = client.post(path, headers=citizen, json={"message": "A suitable home and care plan."}).json()
    client.post(path, headers=auth_header(second), json={"message": "Another suitable home and care plan."})
    client.patch(
        "/api/v1/adoption/applications/" + first["id"],
        headers=coordinator,
        json={"status": "approved", "review_note": "Home check passed."},
    )
    apps = client.get("/api/v1/adoption/applications", headers=auth_header(second)).json()
    assert len(apps) == 1 and apps[0]["status"] == "rejected"


def test_coordinator_location_confirmation_creates_paw(client, identities):
    org, users = identities
    reporter, coordinator = (
        auth_header(users[Role.PUBLIC_REPORTER.value]),
        auth_header(users[Role.NGO_COORDINATOR.value]),
    )
    case = client.post("/api/v1/cases", json=rescue_payload(org.id), headers=reporter).json()
    path = f"/api/v1/cases/{case['id']}/location"
    point = {"latitude": 33.71, "longitude": 73.04}
    assert client.patch(path, headers=reporter, json=point).status_code == 403
    assert client.patch(path, headers=coordinator, json={"latitude": 91, "longitude": 0}).status_code == 422
    response = client.patch(path, headers=coordinator, json=point)
    assert response.status_code == 200
    assert response.json()["version"] == case["version"] + 1
    pins = client.get("/api/v1/map/cases", headers=reporter).json()
    assert pins[0]["latitude"] == 33.71
