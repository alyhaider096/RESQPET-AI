# ResQPet AI demo 0.2.0

Project development: Aly Haider. UI/UX design: Hadia Abbas.

## Working journeys

- Citizen: create a multi-species report, attach a photo, choose GPS/tap location,
  follow personal reports, browse nearby organization rescue paws and apply for adoption.
- Coordinator: open animal details, review and verify, confirm missing map locations,
  select a volunteer, review adoption applications and confirm placement handover.
- Volunteer: accept an assignment, progress the rescue and list rescued animals for adoption.
- Owner/farmer: request general, vaccination, heat-cycle or reproductive-health care
  from an organization veterinarian and read appointment status and follow-up notes.
- Veterinarian: schedule and complete assigned consultations.
- Admin: oversee rescue and adoption operations.

The case list refreshes every five seconds; the paw map refreshes every fifteen seconds.
Reporter accounts only see their own detailed reports. The shared map exposes animal
pins within the organization without reporter contact details. A voice report has a
spoken location, not automatic GPS or a photo: the coordinator can place a confirmed
location from its detail screen.

## Voice evidence and settings

An actual inbound call at 21:28 Pakistan time on 26 October 2026 lasted 2m 32s.
Vapi call `01a1790a-6ec3-7002-b3e8-0dc219f08d5b` matches the F-8 cat rescue
`RQP-261026-CC6FDF`, saved at 21:30 with Critical priority.

Assistant `71ff5fd7-3328-4482-8df2-e8b437a4ce09`, version 5, is published with all
new-call traffic. It uses Soniox automatic transcription, GPT-4.1 Mini and the Vapi
Elliot V2 voice with automatic language detection. Instructions support English/Urdu,
reuse supplied facts, confirm once before reporting, and distinguish rescue intake
from general animal-care questions. Urdu voice quality needs a separate real-call test.

General guidance is not a diagnosis or prescription. The assistant cannot retrieve
existing animal records, approve adoption or book care because no tools for those
actions are attached. It directs callers to the relevant app screens.

## Verification

27 backend tests passed; coverage 87.25%. Flutter analysis is clean and five Flutter
tests passed, including case review, selected-volunteer assignment and unavailable
server handling. All six local demo accounts passed HTTP login and role checks.
PostgreSQL smoke testing completed rescue, adoption application, NGO approval and
handover. Demo Luna remains available; Demo Tara is marked adopted. Both are synthetic.

## Running on the Pixel

Start PostgreSQL and FastAPI, keep USB debugging authorized, then run:

```powershell
adb reverse tcp:8000 tcp:8000
```

Set the app's Demo server connection to `http://127.0.0.1:8000`. USB forwarding is
lost when the phone disconnects or ADB restarts; repeat the command after reconnecting.
Vapi requires the HTTPS tunnel separately. Keep its URL and private Bearer credential
configured on `create_rescue_case`; never include keys in Flutter or Git.

The APK is signed with the development key for the hackathon. Permanent hosting,
video consultation, offline synchronization and trained ML triage remain future work.
