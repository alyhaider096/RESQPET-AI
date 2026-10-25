# ResQPet API contract

The Flutter client and FastAPI backend use JSON over HTTPS. All protected
requests send `Authorization: Bearer <JWT>` and `Content-Type: application/json`.
Vapi uses a separate bearer secret and never receives an app user JWT.

| Method and path | Request | Response | Allowed callers |
|---|---|---|---|
| `POST /api/v1/auth/login` | `email`, `password` | access token and expiry | Public |
| `GET /api/v1/auth/me` | — | current user and role | Any authenticated role |
| `GET /api/v1/users/volunteers` | — | active volunteer list | Coordinator, admin |
| `POST /api/v1/cases` | `RescueCaseCreate` | `RescueCaseRead` | Any authenticated role in its own organization; admin may cross organizations |
| `GET /api/v1/cases` | optional `status`, `priority` | case list | Reporter: own cases; organization roles: own organization; admin: all |
| `GET /api/v1/cases/{case_id}` | — | one case with event history | Same case-scope rules |
| `POST /api/v1/cases/{case_id}/verify` | optional override and reason | updated case | Coordinator, admin |
| `POST /api/v1/cases/{case_id}/assign` | `volunteer_id` | updated case | Coordinator, admin |
| `PATCH /api/v1/cases/{case_id}/status` | `status`, `expected_version`, optional reason | updated case | Assigned volunteer, coordinator, admin |
| `POST /api/v1/voice/create-rescue-case` | rescue fields plus `vapi_call_id` | compact voice result | Vapi bearer secret |
| `POST /api/v1/voice/vapi-webhook` | native Vapi `tool-calls` envelope | Vapi result strings | Vapi bearer secret |
| `WS /api/v1/ws/cases?token=<JWT>` | `ping` | organization-scoped case events | Authenticated organization roles |

`GET /health` checks the API process. `GET /health/ready` also executes
`SELECT 1` against the configured database and is the deployment readiness
probe.

## Flutter field alignment

Flutter submits `organization_id`, `species`, `visible_condition`,
`consciousness`, `bleeding`, `mobility`, `breathing_difficulty`,
`surrounding_danger`, `district`, optional `village`, and optional `landmark`.
These names and enum values match `RescueCaseCreate`. Assignment uses
`volunteer_id`; status updates use `status` and `expected_version`. Flutter
reads only fields guaranteed by `TokenResponse`, `UserRead`, and
`RescueCaseRead`.

Interactive OpenAPI documentation is available at `/docs` in development and
the machine-readable schema remains available at `/openapi.json`.
