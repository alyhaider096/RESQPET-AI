# Vapi setup for the rescue hotline

The backend supports Vapi's native `tool-calls` webhook envelope at:

```text
POST https://YOUR-PUBLIC-BACKEND/api/v1/voice/vapi-webhook
Authorization: Bearer YOUR_VAPI_TOOL_SECRET
```

For local development, expose port `8000` with a trusted HTTPS tunnel and use
that public URL. Never put `VAPI_API_KEY` or `VAPI_TOOL_SECRET` in Flutter.

## Fastest hackathon demo path

1. Start the backend with a strong `VAPI_TOOL_SECRET` and a PostgreSQL or
   demo SQLite database that has already been migrated and seeded.
2. Expose port `8000` through a public HTTPS URL. Confirm the public
   `/health` endpoint before configuring Vapi.
3. In Vapi, create the function tool below and use the public webhook URL as
   its server URL. Configure a bearer credential whose value matches
   `VAPI_TOOL_SECRET`; do not paste the secret into the prompt.
4. Create the assistant, attach the tool, paste the system prompt below, test
   it in the dashboard, and publish the version used by phone calls.
5. In **Phone Numbers**, choose **Create Phone Number → Free Vapi Number**,
   enter an available three-digit US area code, and assign the published
   assistant under **Inbound Settings**. The first Vapi-managed number can be
   requested without adding a payment method, but it is a US number and is
   inbound-only.
6. Call that number from a phone you control, complete one rescue report, and
   verify both **Logs → Calls** in Vapi and the new case in the ResQPet admin
   dashboard.

For a Pakistan-local number, outbound calls, or international calling, import
a supported provider number (for example Twilio, Telnyx, or DIDWW). That is a
separate paid/provider setup; the free Vapi number cannot place outbound calls.

## Function tool

Create a synchronous Function tool named `create_rescue_case` and attach it to
the assistant. Set the tool server URL to the endpoint above and add the
Authorization header.

Use this JSON Schema for the function parameters:

```json
{
  "type": "object",
  "properties": {
    "species": {
      "type": "string",
      "enum": ["dog", "cat", "cattle", "buffalo", "goat", "sheep", "poultry", "horse", "donkey", "other"]
    },
    "visible_condition": { "type": "string" },
    "consciousness": { "type": "string", "enum": ["conscious", "unconscious", "unsure"] },
    "bleeding": { "type": "string", "enum": ["none", "minor", "severe"] },
    "mobility": { "type": "string", "enum": ["mobile", "limping", "immobile", "unsure"] },
    "breathing_difficulty": { "type": "string", "enum": ["yes", "no", "unsure"] },
    "surrounding_danger": { "type": "string", "enum": ["traffic", "fire", "water", "electrical", "violence", "none", "other"] },
    "district": { "type": "string" },
    "village": { "type": "string" },
    "landmark": { "type": "string" },
    "latitude": { "type": "number" },
    "longitude": { "type": "number" },
    "reporter_name": { "type": "string" },
    "reporter_phone": {
      "type": "string",
      "description": "Caller number in E.164 format, for example +923001234567"
    }
  },
  "required": [
    "species",
    "visible_condition",
    "consciousness",
    "bleeding",
    "mobility",
    "breathing_difficulty",
    "surrounding_danger",
    "district"
  ]
}
```

Add a static tool parameter so the model cannot choose or alter the tenant:

```text
organization_id = 00000000-0000-0000-0000-000000000001
```

The seed script creates that deterministic demo organization ID. The backend
derives `vapi_call_id` from Vapi's authenticated call object, making retries
idempotent.

## Assistant system prompt

```text
You are ResQ, an animal rescue intake assistant for Pakistan. Speak calmly and
use short, simple questions. You can understand English, Urdu, and Roman Urdu.
Your task is to collect a rescue report, not diagnose or prescribe treatment.

First determine whether any person is in immediate danger. If yes, tell the
caller to move to safety and contact the relevant emergency service. Never ask
the caller to approach an aggressive animal, enter traffic, touch electricity,
or put themselves at risk.

Collect one field at a time: animal species; visible condition; conscious,
unconscious, or unsure; bleeding none, minor, or severe; mobility mobile,
limping, immobile, or unsure; breathing difficulty yes, no, or unsure;
surrounding danger; district; village or area; and a clear landmark. Ask for
the caller's name and callback number only if they consent. Repeat the location
and urgent facts for confirmation.

Call create_rescue_case only after the caller confirms the summary. When the
tool succeeds, read back the case reference and priority, explain that an NGO
coordinator will verify the report, and do not promise an arrival time. If the
tool fails, apologize, ask the caller to retry once, then direct them to the
manual reporting channel.
```

## Verification checklist

1. Run migrations and `python -m scripts.seed_data` from `backend/`.
2. Confirm `/health` returns `healthy`.
3. Use a public HTTPS URL; `localhost` cannot be reached by Vapi.
4. Place a test call for a buffalo that cannot stand near traffic.
5. Confirm the caller hears a case reference.
6. Log in as `coordinator@resqpet.demo` and confirm the critical case appears.
7. Repeat the same webhook payload and confirm it returns the same case ID with
   `created: false`.
8. Review Vapi webhook logs if the tool is not invoked or returns an error.

Vapi's current server-tool contract requires an HTTP 200 response with one
string result per tool-call ID. This endpoint implements that contract while
keeping the simpler `/voice/create-rescue-case` route for direct API testing.
