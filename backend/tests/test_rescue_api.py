import json

from app.models import CaseStatus, Role
from tests.conftest import auth_header


def rescue_payload(org_id, **overrides):
    data = {
        "organization_id": org_id,
        "species": "buffalo",
        "visible_condition": "Unable to stand near the roadside",
        "consciousness": "conscious",
        "bleeding": "none",
        "mobility": "immobile",
        "breathing_difficulty": "no",
        "surrounding_danger": "traffic",
        "district": "Islamabad",
        "village": "Demo Village",
        "reporter_phone": "+923001234567",
    }
    data.update(overrides)
    return data


def test_authenticated_case_journey(client, identities):
    org, users = identities
    reporter, coordinator, volunteer = (
        users[Role.PUBLIC_REPORTER.value],
        users[Role.NGO_COORDINATOR.value],
        users[Role.RESCUE_VOLUNTEER.value],
    )
    created = client.post("/api/v1/cases", json=rescue_payload(org.id), headers=auth_header(reporter))
    assert created.status_code == 201, created.text
    case = created.json()
    assert case["priority"] == "critical"
    verified = client.post(f"/api/v1/cases/{case['id']}/verify", json={}, headers=auth_header(coordinator))
    assert verified.status_code == 200 and verified.json()["status"] == CaseStatus.VERIFIED.value
    assigned = client.post(
        f"/api/v1/cases/{case['id']}/assign",
        json={"volunteer_id": volunteer.id},
        headers=auth_header(coordinator),
    )
    assert assigned.status_code == 200, assigned.text
    assigned_case = assigned.json()
    assert assigned_case["status"] == CaseStatus.ASSIGNED.value
    accepted = client.patch(
        f"/api/v1/cases/{case['id']}/status",
        json={"status": "accepted", "expected_version": assigned_case["version"]},
        headers=auth_header(volunteer),
    )
    assert accepted.status_code == 200 and accepted.json()["status"] == CaseStatus.ACCEPTED.value


def test_reporter_only_lists_their_own_cases(client, identities, db_session):
    org, users = identities
    reporter = users[Role.PUBLIC_REPORTER.value]
    other_reporter = type(reporter)(
        email="other-reporter@example.test",
        full_name="Other Reporter",
        password_hash=reporter.password_hash,
        role=Role.PUBLIC_REPORTER.value,
        organization_id=org.id,
    )
    db_session.add(other_reporter)
    db_session.commit()
    client.post("/api/v1/cases", json=rescue_payload(org.id), headers=auth_header(reporter))
    client.post(
        "/api/v1/cases",
        json=rescue_payload(org.id, species="goat"),
        headers=auth_header(other_reporter),
    )
    response = client.get("/api/v1/cases", headers=auth_header(reporter))
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["species"] == "buffalo"


def test_vapi_idempotency(client, identities):
    org, _ = identities
    payload = rescue_payload(org.id, vapi_call_id="call-demo-001")
    headers = {"Authorization": "Bearer test-vapi-secret-000000000000000000000"}
    first = client.post("/api/v1/voice/create-rescue-case", json=payload, headers=headers)
    second = client.post("/api/v1/voice/create-rescue-case", json=payload, headers=headers)
    assert first.status_code == second.status_code == 200
    assert first.json()["created"] is True and second.json()["created"] is False
    assert first.json()["case_id"] == second.json()["case_id"]


def test_native_vapi_webhook_contract(client, identities):
    org, _ = identities
    headers = {"Authorization": "Bearer test-vapi-secret-000000000000000000000"}
    body = {
        "message": {
            "type": "tool-calls",
            "call": {"id": "call-native-001"},
            "toolCallList": [
                {
                    "id": "tool-call-001",
                    "type": "function",
                    "function": {
                        "name": "create_rescue_case",
                        "arguments": rescue_payload(org.id),
                    },
                }
            ],
        }
    }
    response = client.post("/api/v1/voice/vapi-webhook", json=body, headers=headers)
    assert response.status_code == 200
    result = response.json()["results"][0]
    assert result["toolCallId"] == "tool-call-001"
    parsed = json.loads(result["result"])
    assert parsed["created"] is True
    assert parsed["priority"] == "critical"


def test_native_vapi_webhook_returns_tool_error_with_http_200(client, identities):
    headers = {"Authorization": "Bearer test-vapi-secret-000000000000000000000"}
    response = client.post(
        "/api/v1/voice/vapi-webhook",
        json={
            "message": {
                "type": "tool-calls",
                "call": {"id": "call-native-002"},
                "toolCallList": [
                    {
                        "id": "tool-call-002",
                        "function": {"name": "unknown_tool", "arguments": {}},
                    }
                ],
            }
        },
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json()["results"] == [
        {"toolCallId": "tool-call-002", "error": "Unknown tool: unknown_tool"}
    ]
