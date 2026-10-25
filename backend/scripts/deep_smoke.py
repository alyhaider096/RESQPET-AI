"""Run a destructive demo-only smoke test against the configured database."""

import json
from uuid import uuid4

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from scripts.seed_data import DEMO_ORGANIZATION_ID


def assert_ok(response, expected: int = 200):
    if response.status_code != expected:
        raise AssertionError(f"{response.request.method} {response.request.url}: {response.text}")
    return response.json()


def login(client: TestClient, email: str, password: str) -> dict[str, str]:
    body = assert_ok(client.post("/api/v1/auth/login", json={"email": email, "password": password}))
    return {"Authorization": f"Bearer {body['access_token']}"}


def rescue_payload() -> dict:
    return {
        "organization_id": DEMO_ORGANIZATION_ID,
        "species": "buffalo",
        "visible_condition": "Unable to stand beside fast-moving traffic",
        "consciousness": "conscious",
        "bleeding": "none",
        "mobility": "immobile",
        "breathing_difficulty": "no",
        "surrounding_danger": "traffic",
        "district": "Islamabad",
        "village": "Demo Village",
        "landmark": "Water tank",
    }


def main() -> None:
    run_id = uuid4().hex[:10]
    with TestClient(app) as client:
        assert assert_ok(client.get("/health"))["status"] == "healthy"
        admin = login(client, settings.ADMIN_BOOTSTRAP_EMAIL, settings.ADMIN_BOOTSTRAP_PASSWORD)
        coordinator = login(client, "coordinator@resqpet.demo", "DemoCoordinator123!")
        volunteer = login(client, "volunteer@resqpet.demo", "DemoVolunteer123!")
        reporter = login(client, "reporter@resqpet.demo", "DemoReporter123!")
        assert assert_ok(client.get("/api/v1/auth/me", headers=admin))["role"] == "system_admin"

        case = assert_ok(
            client.post("/api/v1/cases", headers=reporter, json=rescue_payload()),
            201,
        )
        assert case["priority"] == "critical"
        reporter_cases = assert_ok(client.get("/api/v1/cases", headers=reporter))
        assert case["id"] in {item["id"] for item in reporter_cases}

        case = assert_ok(client.post(f"/api/v1/cases/{case['id']}/verify", headers=coordinator, json={}))
        volunteers = assert_ok(client.get("/api/v1/users/volunteers", headers=coordinator))
        case = assert_ok(
            client.post(
                f"/api/v1/cases/{case['id']}/assign",
                headers=coordinator,
                json={"volunteer_id": volunteers[0]["id"]},
            )
        )
        for status in ["accepted", "en_route", "on_scene", "rescued", "closed"]:
            case = assert_ok(
                client.patch(
                    f"/api/v1/cases/{case['id']}/status",
                    headers=volunteer,
                    json={"status": status, "expected_version": case["version"]},
                )
            )

        voice_args = {
            key: value
            for key, value in (rescue_payload() | {"species": "goat"}).items()
            if key != "organization_id"
        }
        voice_body = {
            "organization_id": DEMO_ORGANIZATION_ID,
            "message": {
                "type": "tool-calls",
                "call": {"id": f"smoke-vapi-{run_id}"},
                "toolCallList": [
                    {
                        "id": f"tool-{run_id}",
                        "function": {"name": "create_rescue_case", "arguments": voice_args},
                    }
                ],
            }
        }
        voice_headers = {"Authorization": f"Bearer {settings.VAPI_TOOL_SECRET}"}
        first = assert_ok(client.post("/api/v1/voice/vapi-webhook", headers=voice_headers, json=voice_body))
        second = assert_ok(client.post("/api/v1/voice/vapi-webhook", headers=voice_headers, json=voice_body))
        first_result = json.loads(first["results"][0]["result"])
        second_result = json.loads(second["results"][0]["result"])
        assert first_result["created"] is True
        assert second_result["created"] is False
        assert first_result["case_id"] == second_result["case_id"]

        print(
            json.dumps(
                {
                    "health": "healthy",
                    "admin_login": "passed",
                    "reporter_scope": "passed",
                    "case_reference": case["case_reference"],
                    "final_case_status": case["status"],
                    "priority": case["priority"],
                    "vapi_idempotency": "passed",
                    "vapi_case_reference": first_result["case_reference"],
                },
                indent=2,
            )
        )


if __name__ == "__main__":
    main()
