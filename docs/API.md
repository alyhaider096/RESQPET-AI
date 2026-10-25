# P0 API

OpenAPI is available at `http://localhost:8000/docs` in development.

## Authentication

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

## Rescue operations

- `POST /api/v1/cases`
- `GET /api/v1/cases`
- `GET /api/v1/cases/{case_id}`
- `POST /api/v1/cases/{case_id}/verify`
- `POST /api/v1/cases/{case_id}/assign`
- `PATCH /api/v1/cases/{case_id}/status`

## Vapi tool

- `POST /api/v1/voice/create-rescue-case`
- `Authorization: Bearer <VAPI_TOOL_SECRET>`
- `POST /api/v1/voice/vapi-webhook` (native Vapi `tool-calls` envelope)

See `docs/VAPI_SETUP.md` for the tool schema, assistant prompt, and test flow.
- `vapi_call_id` is mandatory and idempotent.

## Real-time

- `WS /api/v1/ws/cases?token=<JWT>`
- Send `ping` to receive `{"type":"pong"}`.
