# Rescue Operations Design

## Goal

Deliver one reliable rescue journey from voice or mobile intake through NGO verification, responder assignment, field status updates, and closure.

## Components

- Flutter submits reports and receives assignments.
- Vapi invokes authenticated HTTPS tools; Vapi owns audio transport.
- FastAPI validates input, enforces roles and organizations, and owns state transitions.
- PostgreSQL is the source of truth and Alembic owns schema changes.
- WebSocket broadcasts typed, organization-scoped events only after commit.

## Integrity and privacy

- `vapi_call_id` is unique and makes voice retries idempotent.
- Assignment locks the case row and accepts only `verified` cases.
- Every mutation increments `version`; stale writes return HTTP 409.
- Reporter PII is encrypted and never included in WebSocket payloads.

## State machine

`reported → verified → assigned → accepted → en_route → on_scene → rescued → closed`

Reports may terminate as `duplicate` or `false_report` before assignment.

## Security

App endpoints use short-lived JWT tokens. Vapi tools use a separate bearer secret. Every operational query is scoped by `organization_id`.
