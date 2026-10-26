import httpx

from app import assistant
from app.models import Role
from tests.conftest import auth_header


def test_assistant_auth_config_limits_and_provider_errors(client, identities, monkeypatch):
    _, users = identities
    headers = auth_header(users[Role.PUBLIC_REPORTER.value])
    payload = {"messages": [{"role": "user", "content": "How do I report an animal?"}]}
    assert client.post("/api/v1/assistant/chat", json=payload).status_code == 401
    monkeypatch.setattr(assistant.settings, "OPENAI_API_KEY", None)
    assert client.post("/api/v1/assistant/chat", json=payload, headers=headers).status_code == 503
    monkeypatch.setattr(assistant.settings, "OPENAI_API_KEY", "synthetic-test-key")
    monkeypatch.setattr(assistant, "_requests", 0)
    monkeypatch.setattr(assistant.settings, "AI_DEMO_REQUEST_LIMIT", 2)

    async def reply(messages):
        assert messages[0].content == payload["messages"][0]["content"]
        return "Open Report and add a photo and location."

    monkeypatch.setattr(assistant, "provider_reply", reply)
    result = client.post("/api/v1/assistant/chat", json=payload, headers=headers)
    assert result.status_code == 200
    assert "Report" in result.json()["reply"]

    async def failed(messages):
        raise httpx.ConnectError("private-provider-details")

    monkeypatch.setattr(assistant, "provider_reply", failed)
    result = client.post("/api/v1/assistant/chat", json=payload, headers=headers)
    assert result.status_code == 503
    assert "private-provider-details" not in result.text
    assert client.post("/api/v1/assistant/chat", json=payload, headers=headers).status_code == 429
    oversized = {"messages": [{"role": "user", "content": "x" * 1501}]}
    assert client.post("/api/v1/assistant/chat", json=oversized, headers=headers).status_code == 422
