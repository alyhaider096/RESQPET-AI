from datetime import UTC, datetime, timedelta

from app.models import Role, User
from tests.conftest import auth_header


def test_owner_veterinarian_appointment_and_role_permissions(client, identities, db_session):
    org, users = identities
    owner = users[Role.PUBLIC_REPORTER.value]
    vet = User(
        email="vet@example.test",
        full_name="Test Vet",
        password_hash=owner.password_hash,
        role=Role.VETERINARIAN.value,
        organization_id=org.id,
    )
    db_session.add(vet)
    db_session.commit()
    owner_headers, vet_headers = auth_header(owner), auth_header(vet)
    vets = client.get("/api/v1/care/veterinarians", headers=owner_headers).json()
    assert vets == [{"id": vet.id, "full_name": "Test Vet"}]
    response = client.post(
        "/api/v1/care/consultations",
        headers=owner_headers,
        json={
            "veterinarian_id": vet.id,
            "species": "buffalo",
            "animal_name": "Herd 1",
            "concern": "heat_cycle",
            "description": "Farmer requests a reproductive health consultation",
        },
    )
    assert response.status_code == 201
    item = response.json()
    path = f"/api/v1/care/consultations/{item['id']}"
    schedule = {"status": "scheduled", "appointment_at": (datetime.now(UTC) + timedelta(days=1)).isoformat()}
    assert client.patch(path, headers=owner_headers, json=schedule).status_code == 403
    assert client.patch(path, headers=vet_headers, json={"status": "completed"}).status_code == 409
    assert client.patch(path, headers=vet_headers, json=schedule).status_code == 200
    complete = client.patch(
        path, headers=vet_headers, json={"status": "completed", "vet_note": "Follow-up recorded"}
    )
    assert complete.status_code == 200
    assert (
        client.get("/api/v1/care/consultations", headers=owner_headers).json()[0]["vet_note"]
        == "Follow-up recorded"
    )
    volunteer_headers = auth_header(users[Role.RESCUE_VOLUNTEER.value])
    assert client.get("/api/v1/care/consultations", headers=volunteer_headers).json() == []
