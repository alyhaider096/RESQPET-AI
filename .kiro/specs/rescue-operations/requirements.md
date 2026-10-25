# Requirements Document: Rescue Operations

## Introduction

The rescue-operations feature is the P0 (must-ship) core capability of AnimalCare PK. It provides a complete vertical slice of the emergency animal rescue workflow, enabling citizens to report injured or endangered animals through multiple channels (voice call or mobile app), NGO coordinators to verify and assign cases, and rescue volunteers to execute rescues with real-time status updates. The system implements explainable priority classification using transparent business rules, organization-scoped multi-tenancy, and comprehensive audit trails for accountability.

This feature supports Pakistan's diverse animal welfare needs, including urban pets (dogs, cats) and rural livestock (cattle, buffalo, goats, sheep, poultry, horses, donkeys).

---

## Glossary

- **System**: The AnimalCare PK backend application
- **Mobile_App**: The Flutter mobile application for reporters and volunteers
- **Voice_Assistant**: The Vapi AI voice receptionist accessible via phone call
- **Reporter**: A citizen (public_reporter, pet_owner, or livestock_farmer) submitting a rescue case
- **Coordinator**: An NGO staff member (ngo_coordinator role) who verifies and assigns cases
- **Volunteer**: A rescue team member (rescue_volunteer role) who executes rescues
- **Rescue_Case**: A record of an injured or endangered animal requiring intervention
- **Priority_Level**: Classification of urgency (Critical, Urgent, or Routine)
- **Case_Status**: Current state in the rescue workflow (Reported, Verified, Assigned, Accepted, En_Route, On_Scene, Rescued, Closed)
- **Organization**: An NGO or rescue group managing cases and volunteers
- **Audit_Log**: Time-stamped record of all case operations
- **Vapi_Call_ID**: Unique identifier from Vapi for idempotency
- **WebSocket**: Real-time bidirectional communication channel
- **PII**: Personally Identifiable Information (reporter name, phone number, exact address)
- **Idempotent_Operation**: Operation that produces the same result when executed multiple times
- **Concurrency_Control**: Mechanism to prevent conflicting operations under concurrent load

---

## Requirements

### Requirement 1: Multi-Channel Case Submission

**User Story:** As a citizen reporter, I want to submit rescue cases through voice call or mobile app, so that I can report endangered animals using my preferred communication method.

#### Acceptance Criteria

1. WHEN a Reporter calls the Voice_Assistant, THE System SHALL collect structured rescue case information through voice interaction
2. WHEN a Reporter uses the Mobile_App, THE System SHALL provide a form to collect structured rescue case information
3. THE System SHALL collect species from the list: dog, cat, cattle, buffalo, goat, sheep, poultry, horse, donkey
4. THE System SHALL collect visible condition description as free text (maximum 500 characters)
5. THE System SHALL collect consciousness level from: conscious, unconscious, unsure
6. THE System SHALL collect bleeding severity from: none, minor, severe
7. THE System SHALL collect mobility status from: mobile, limping, immobile
8. THE System SHALL collect breathing difficulty indicator from: yes, no, unsure
9. THE System SHALL collect surrounding danger from: traffic, fire, water, none
10. THE System SHALL collect location as GPS coordinates or manual district, village, and landmark
11. THE System SHALL collect reporter phone number in E.164 format
12. WHEN all required fields are collected, THE Voice_Assistant SHALL read back the case details for Reporter confirmation
13. WHEN the Reporter confirms details through Voice_Assistant or Mobile_App, THE System SHALL create the Rescue_Case in the database

---

### Requirement 2: Voice Call Integration

**User Story:** As a citizen reporter, I want to report emergencies by calling a phone number, so that I can report animals even without smartphone data access.

#### Acceptance Criteria

1. THE System SHALL expose Vapi tool endpoints for Voice_Assistant to call during conversations
2. THE System SHALL authenticate Vapi tool endpoint requests using Bearer token verification
3. WHEN the Voice_Assistant invokes a tool endpoint, THE System SHALL validate the request contains Vapi_Call_ID
4. THE System SHALL return structured JSON responses to Vapi tool endpoint requests within 1 second (p95)
5. WHEN a tool endpoint returns an error, THE System SHALL provide a user-friendly error message for the Voice_Assistant to communicate
6. THE System SHALL log all Vapi tool endpoint invocations with timestamp, Vapi_Call_ID, and response status

---

### Requirement 3: Idempotent Case Creation

**User Story:** As a system administrator, I want case creation to be idempotent, so that network retries or voice assistant retries do not create duplicate cases.

#### Acceptance Criteria

1. THE System SHALL require Vapi_Call_ID for all case creation requests from Voice_Assistant
2. WHEN the System receives a case creation request with Vapi_Call_ID, THE System SHALL check for existing Rescue_Case with that Vapi_Call_ID
3. IF an existing Rescue_Case with the same Vapi_Call_ID is found, THEN THE System SHALL return the existing case without creating a duplicate
4. IF no existing Rescue_Case with the Vapi_Call_ID is found, THEN THE System SHALL create a new Rescue_Case
5. THE System SHALL enforce database-level unique constraint on Vapi_Call_ID (nullable, unique when present)
6. THE System SHALL complete idempotent case creation within 500ms (p95)

---

### Requirement 4: Explainable Priority Classification

**User Story:** As an NGO coordinator, I want cases automatically classified with transparent priority rules, so that I can quickly identify which animals need immediate attention without relying on black-box algorithms.

#### Acceptance Criteria

1. WHEN a Rescue_Case is created, THE System SHALL apply rule-based classification to assign Priority_Level
2. THE System SHALL classify as Critical IF consciousness equals unconscious
3. THE System SHALL classify as Critical IF bleeding severity equals severe
4. THE System SHALL classify as Critical IF mobility status equals immobile AND surrounding danger equals traffic
5. THE System SHALL classify as Critical IF breathing difficulty equals yes
6. THE System SHALL classify as Urgent IF bleeding severity equals minor
7. THE System SHALL classify as Urgent IF mobility status equals limping
8. THE System SHALL classify as Urgent IF surrounding danger equals fire OR water
9. THE System SHALL classify as Routine IF none of the Critical or Urgent conditions are met
10. THE System SHALL store the priority classification explanation with the Rescue_Case
11. THE System SHALL record which specific rules triggered the classification
12. THE System SHALL expose the priority explanation in API responses and Mobile_App case details

---

### Requirement 5: Real-Time Case Distribution

**User Story:** As an NGO coordinator, I want new rescue cases to appear immediately in my dashboard, so that I can respond to emergencies without manually refreshing.

#### Acceptance Criteria

1. WHEN a Rescue_Case is created, THE System SHALL broadcast a WebSocket event to subscribers in the case's Organization
2. THE WebSocket event SHALL contain case_id, status, priority, species, location district, and created timestamp
3. THE WebSocket event SHALL NOT contain PII (reporter name, phone number, exact address)
4. THE System SHALL deliver WebSocket events within 1 second of database commit
5. THE System SHALL filter WebSocket events by Organization to prevent cross-organization data leaks
6. WHEN a Coordinator's WebSocket connection is established, THE System SHALL authenticate using JWT token
7. IF JWT token is invalid or expired, THEN THE System SHALL reject the WebSocket connection with code 1008

---

### Requirement 6: Case Verification

**User Story:** As an NGO coordinator, I want to review and verify incoming rescue cases, so that I can confirm legitimacy before dispatching volunteers.

#### Acceptance Criteria

1. THE System SHALL transition Rescue_Case status from Reported to Verified when Coordinator approves
2. THE System SHALL require Coordinator role and matching Organization for verification action
3. THE System SHALL record verification timestamp and Coordinator user_id in Audit_Log
4. THE System SHALL allow Coordinator to override Priority_Level during verification
5. WHEN Priority_Level is overridden, THE System SHALL require override reason (minimum 10 characters)
6. THE System SHALL log priority overrides with original priority, new priority, reason, and Coordinator user_id
7. THE System SHALL broadcast WebSocket event to Organization subscribers when case is verified

---

### Requirement 7: Volunteer Assignment with Concurrency Control

**User Story:** As an NGO coordinator, I want to assign verified cases to specific volunteers, so that rescue operations are coordinated and volunteers receive clear assignments.

#### Acceptance Criteria

1. THE System SHALL transition Rescue_Case status from Verified to Assigned when Coordinator assigns a Volunteer
2. THE System SHALL require Coordinator role and matching Organization for assignment action
3. THE System SHALL validate that assigned Volunteer belongs to the same Organization as the case
4. THE System SHALL validate that assigned Volunteer has rescue_volunteer role
5. THE System SHALL use database row-level locking during assignment to prevent double-assignment
6. WHEN two Coordinators attempt concurrent assignment of the same case, THE System SHALL allow only one assignment and return error to the other
7. THE System SHALL record assignment timestamp, Coordinator user_id, and Volunteer user_id in Audit_Log
8. THE System SHALL broadcast WebSocket event to Organization subscribers when case is assigned
9. THE System SHALL send targeted notification to assigned Volunteer via WebSocket or push notification
10. THE System SHALL complete assignment operation within 200ms (p95) excluding notification delivery

---

### Requirement 8: Volunteer Case Acceptance

**User Story:** As a rescue volunteer, I want to accept or decline case assignments, so that coordinators know whether I'm available to respond.

#### Acceptance Criteria

1. WHEN a Volunteer views assigned Rescue_Case in Mobile_App, THE System SHALL display case details including species, condition, location, and priority
2. THE System SHALL provide Accept and Decline actions for assigned cases
3. WHEN Volunteer accepts, THE System SHALL transition case status from Assigned to Accepted
4. WHEN Volunteer declines, THE System SHALL transition case status from Assigned back to Verified
5. THE System SHALL require rescue_volunteer role and matching Volunteer user_id for acceptance action
6. THE System SHALL record acceptance or decline timestamp and Volunteer user_id in Audit_Log
7. WHEN a case is declined, THE System SHALL broadcast WebSocket event to Coordinators for reassignment
8. THE System SHALL broadcast WebSocket event when case is accepted

---

### Requirement 9: Field Status Updates

**User Story:** As a rescue volunteer, I want to update case status as I progress through the rescue, so that coordinators can track rescue operations in real-time.

#### Acceptance Criteria

1. THE System SHALL support the following status transitions: Accepted → En_Route, En_Route → On_Scene, On_Scene → Rescued, Rescued → Closed
2. THE System SHALL validate status transitions follow the defined sequence
3. IF an invalid status transition is attempted, THEN THE System SHALL return error code INVALID_TRANSITION with allowed transitions
4. THE System SHALL require rescue_volunteer role and matching assigned Volunteer user_id for status updates
5. THE System SHALL record each status change timestamp and Volunteer user_id in Audit_Log
6. THE System SHALL broadcast WebSocket event to Organization subscribers for each status change
7. THE System SHALL allow optional notes (maximum 1000 characters) with each status update
8. WHEN status transitions to Rescued, THE System SHALL require rescue outcome from: animal_secured, transported_to_vet, released_safely, deceased
9. THE System SHALL complete status update within 200ms (p95)

---

### Requirement 10: Audit Trail and Timeline

**User Story:** As an NGO coordinator, I want to view complete case history with timestamps, so that I can review rescue operations and identify process improvements.

#### Acceptance Criteria

1. THE System SHALL create Audit_Log entry for every Rescue_Case state change
2. THE Audit_Log entry SHALL contain timestamp, user_id, event_type, old_value, new_value, and optional reason
3. THE System SHALL log the following events: case_created, case_verified, priority_overridden, case_assigned, assignment_accepted, assignment_declined, status_updated, case_closed
4. THE System SHALL order Audit_Log entries by timestamp ascending
5. THE System SHALL expose audit timeline via API endpoint requiring Coordinator or system_admin role
6. THE System SHALL filter audit timeline by Organization to prevent cross-organization access
7. THE System SHALL retain Audit_Log entries for minimum 2 years after case closure

---

### Requirement 11: Organization-Scoped Data Isolation

**User Story:** As an NGO coordinator, I want to see only my organization's rescue cases, so that case data remains confidential between organizations.

#### Acceptance Criteria

1. THE System SHALL filter all Rescue_Case queries by current user's Organization
2. THE System SHALL enforce Organization filtering in database queries, not application logic
3. THE System SHALL validate Organization membership before returning case details
4. IF a user requests a case from another Organization, THEN THE System SHALL return error code FORBIDDEN
5. THE System SHALL log cross-organization access attempts with user_id and attempted case_id
6. WHERE user has system_admin role, THE System SHALL allow cross-organization access with explicit override flag and audit log entry
7. THE System SHALL apply Organization filtering to WebSocket event subscriptions
8. THE System SHALL apply Organization filtering to audit log queries

---

### Requirement 12: PII Encryption and Protection

**User Story:** As a system administrator, I want reporter personal information encrypted at rest, so that data breaches do not expose sensitive information.

#### Acceptance Criteria

1. THE System SHALL encrypt reporter full name using PII_ENCRYPTION_KEY before storing in database
2. THE System SHALL encrypt reporter phone number using PII_ENCRYPTION_KEY before storing in database
3. THE System SHALL encrypt exact address using PII_ENCRYPTION_KEY before storing in database
4. THE System SHALL use AES-256-GCM authenticated encryption for PII fields
5. THE System SHALL generate unique initialization vector for each encrypted field
6. THE System SHALL store initialization vector alongside ciphertext
7. THE System SHALL hash phone number with PHONE_HASH_SALT for lookup operations
8. THE System SHALL store phone hash in separate indexed column for query performance
9. THE System SHALL decrypt PII fields only when requested by authorized users (Coordinator, system_admin)
10. THE System SHALL redact PII from application logs and error messages
11. THE System SHALL NOT include PII in WebSocket event payloads

---

### Requirement 13: Authentication and Authorization

**User Story:** As a system administrator, I want role-based access control enforced on all rescue operations, so that users can only perform actions appropriate to their role.

#### Acceptance Criteria

1. THE System SHALL require valid JWT access token for all protected API endpoints
2. THE System SHALL validate JWT signature, expiration, and issuer on every request
3. THE System SHALL extract user_id, role, and organization_id from JWT payload
4. THE System SHALL allow public_reporter role to create cases (via Voice_Assistant or Mobile_App)
5. THE System SHALL allow ngo_coordinator role to verify, override priority, and assign cases
6. THE System SHALL allow rescue_volunteer role to accept and update assigned cases
7. THE System SHALL allow system_admin role to access all organizations with audit logging
8. IF role is insufficient for requested action, THEN THE System SHALL return error code FORBIDDEN
9. THE System SHALL log authentication failures with attempted user identifier and IP address
10. THE System SHALL log authorization failures with user_id, role, and attempted action

---

### Requirement 14: Case List and Filtering

**User Story:** As an NGO coordinator, I want to filter rescue cases by status and priority, so that I can focus on cases requiring my attention.

#### Acceptance Criteria

1. THE System SHALL provide API endpoint to list Rescue_Cases filtered by Organization
2. THE System SHALL support filtering by case status (Reported, Verified, Assigned, Accepted, En_Route, On_Scene, Rescued, Closed)
3. THE System SHALL support filtering by Priority_Level (Critical, Urgent, Routine)
4. THE System SHALL support filtering by species
5. THE System SHALL support filtering by date range (created_at)
6. THE System SHALL support sorting by created_at, priority, and status
7. THE System SHALL implement pagination with configurable page size (default 20, maximum 100)
8. THE System SHALL return total count of matching cases in pagination metadata
9. THE System SHALL complete list query within 200ms (p95) for typical filters
10. THE System SHALL optimize queries using database indexes on frequently filtered columns

---

### Requirement 15: Case Detail Retrieval

**User Story:** As a rescue volunteer, I want to view complete case details including reporter information and location, so that I can execute the rescue effectively.

#### Acceptance Criteria

1. THE System SHALL provide API endpoint to retrieve Rescue_Case by case_id
2. THE System SHALL require authenticated user and Organization membership validation
3. THE System SHALL return all case fields including encrypted PII (decrypted for authorized roles)
4. THE System SHALL return priority classification with explanation
5. THE System SHALL return current status and assigned Volunteer (if assigned)
6. THE System SHALL return audit timeline with all status transitions
7. THE System SHALL return reporter phone number only to Coordinator and assigned Volunteer roles
8. THE System SHALL return reporter full name only to Coordinator and assigned Volunteer roles
9. THE System SHALL complete case detail retrieval within 200ms (p95)

---

### Requirement 16: WebSocket Connection Management

**User Story:** As a mobile app user, I want automatic reconnection when my internet connection drops, so that I continue receiving real-time updates without manual intervention.

#### Acceptance Criteria

1. THE System SHALL implement WebSocket heartbeat ping every 30 seconds
2. WHEN a WebSocket client misses 2 consecutive pongs, THE System SHALL close the connection
3. THE Mobile_App SHALL implement exponential backoff reconnection (1s, 2s, 4s, 8s, maximum 30s)
4. WHEN reconnecting, THE Mobile_App SHALL re-authenticate using current JWT token
5. IF JWT token expired during disconnection, THEN THE Mobile_App SHALL refresh token before reconnecting
6. THE System SHALL support multiple concurrent WebSocket connections per user (e.g., mobile app and web dashboard)
7. THE System SHALL limit maximum concurrent WebSocket connections per user to 5
8. IF connection limit exceeded, THEN THE System SHALL close oldest connection

---

### Requirement 17: Input Validation and Sanitization

**User Story:** As a system administrator, I want all user inputs validated and sanitized, so that the system is protected against injection attacks and invalid data.

#### Acceptance Criteria

1. THE System SHALL validate all API request inputs using Pydantic v2 models
2. THE System SHALL validate species against enumerated list (dog, cat, cattle, buffalo, goat, sheep, poultry, horse, donkey)
3. THE System SHALL validate consciousness level against enumerated list (conscious, unconscious, unsure)
4. THE System SHALL validate bleeding severity against enumerated list (none, minor, severe)
5. THE System SHALL validate mobility status against enumerated list (mobile, limping, immobile)
6. THE System SHALL validate breathing difficulty against enumerated list (yes, no, unsure)
7. THE System SHALL validate surrounding danger against enumerated list (traffic, fire, water, none)
8. THE System SHALL validate visible condition description length (maximum 500 characters)
9. THE System SHALL validate phone number format (E.164 international format)
10. THE System SHALL sanitize free text inputs to prevent XSS attacks
11. IF validation fails, THEN THE System SHALL return error code VALIDATION_ERROR with specific field errors

---

### Requirement 18: Error Handling and Recovery

**User Story:** As a developer, I want consistent error responses and graceful degradation, so that clients can handle errors appropriately and users receive helpful feedback.

#### Acceptance Criteria

1. THE System SHALL return standardized error response format with code, message, details, and timestamp
2. THE System SHALL use appropriate HTTP status codes (400 for validation, 401 for authentication, 403 for authorization, 404 for not found, 500 for server errors)
3. THE System SHALL log all errors with stack trace, request ID, and user context
4. THE System SHALL NOT expose sensitive information (database structure, secrets, internal paths) in error messages
5. WHEN database connection fails, THE System SHALL return error code DATABASE_UNAVAILABLE with retry guidance
6. WHEN WebSocket broadcast fails, THE System SHALL log error but complete the database transaction
7. WHEN Vapi tool endpoint times out, THE System SHALL return partial success indicator if case was created
8. THE System SHALL implement database transaction rollback on any error during multi-step operations

---

### Requirement 19: Performance and Scalability

**User Story:** As a system administrator, I want the system to handle concurrent rescue operations efficiently, so that response times remain fast during high-traffic periods.

#### Acceptance Criteria

1. THE System SHALL complete case creation within 500ms (p95) excluding Vapi latency
2. THE System SHALL complete Vapi tool endpoints within 1 second (p95)
3. THE System SHALL deliver WebSocket events within 1 second of database commit
4. THE System SHALL complete case assignment with row locking within 200ms (p95)
5. THE System SHALL complete status updates within 200ms (p95)
6. THE System SHALL use database connection pooling with 10-20 connections
7. THE System SHALL create database indexes on frequently queried columns (organization_id, status, priority, created_at)
8. THE System SHALL optimize queries to avoid N+1 query patterns
9. THE System SHALL implement rate limiting (60 requests/minute for unauthenticated, 120 requests/minute for authenticated)

---

### Requirement 20: Database Schema and Migrations

**User Story:** As a developer, I want database schema managed through migrations, so that schema changes are versioned and reproducible across environments.

#### Acceptance Criteria

1. THE System SHALL define Rescue_Case SQLAlchemy model with all required fields
2. THE Rescue_Case model SHALL include: id (UUID), organization_id (FK), species, visible_condition, consciousness, bleeding, mobility, breathing_difficulty, surrounding_danger, location_gps, location_district, location_village, location_landmark, reporter_name_encrypted, reporter_phone_encrypted, reporter_phone_hash, priority, priority_explanation, status, vapi_call_id, assigned_volunteer_id (FK), created_at, updated_at
3. THE System SHALL define Audit_Log SQLAlchemy model with: id (UUID), case_id (FK), user_id (FK), timestamp, event_type, old_value, new_value, reason
4. THE System SHALL create Alembic migration for initial schema
5. THE Alembic migration SHALL include unique constraint on vapi_call_id (nullable, unique when present)
6. THE Alembic migration SHALL include indexes on organization_id, status, priority, created_at, reporter_phone_hash
7. THE Alembic migration SHALL include foreign key constraints with ON DELETE behavior defined
8. THE Alembic migration SHALL include both upgrade and downgrade functions

---

### Requirement 21: Testing and Validation

**User Story:** As a developer, I want comprehensive test coverage for rescue operations, so that regressions are caught before deployment.

#### Acceptance Criteria

1. THE System SHALL include pytest unit tests for priority classification logic with all rule combinations
2. THE System SHALL include pytest unit tests for PII encryption and decryption
3. THE System SHALL include pytest unit tests for phone number hashing
4. THE System SHALL include pytest integration tests for case creation API with idempotency validation
5. THE System SHALL include pytest integration tests for case assignment with concurrency simulation
6. THE System SHALL include pytest integration tests for status transition validation
7. THE System SHALL include pytest integration tests for Organization filtering
8. THE System SHALL include pytest integration tests for role-based authorization
9. THE System SHALL include pytest integration tests for Vapi tool endpoints with authentication
10. THE System SHALL achieve minimum 80% code coverage for critical business logic paths

---

### Requirement 22: API Documentation

**User Story:** As a mobile app developer, I want comprehensive API documentation with examples, so that I can integrate with the backend efficiently.

#### Acceptance Criteria

1. THE System SHALL generate OpenAPI 3.0 documentation automatically from FastAPI route definitions
2. THE OpenAPI documentation SHALL include all request schemas with field descriptions and validation rules
3. THE OpenAPI documentation SHALL include all response schemas with example payloads
4. THE OpenAPI documentation SHALL include authentication requirements (Bearer token) for protected endpoints
5. THE OpenAPI documentation SHALL include error response schemas
6. THE System SHALL expose interactive API documentation at /docs endpoint
7. THE System SHALL expose OpenAPI JSON schema at /openapi.json endpoint

---

### Requirement 23: Deployment Configuration

**User Story:** As a system administrator, I want environment-specific configuration loaded from environment variables, so that the same code runs in development, staging, and production.

#### Acceptance Criteria

1. THE System SHALL load all configuration from environment variables using python-dotenv
2. THE System SHALL require the following environment variables: DATABASE_URL, JWT_SECRET_KEY, PII_ENCRYPTION_KEY, PHONE_HASH_SALT, VAPI_TOOL_SECRET
3. THE System SHALL provide comprehensive .env.example file with all required variables documented
4. THE System SHALL validate required environment variables on startup and fail fast if missing
5. THE System SHALL NOT include default secrets in code
6. THE System SHALL log configuration errors with specific missing variable names
7. THE System SHALL support optional environment variables for feature flags and service URLs

---

## Edge Cases and Error Scenarios

### Edge Case 1: Reporter Disconnects During Voice Call
- **Scenario**: Reporter's phone connection drops after providing partial information but before confirmation
- **Expected Behavior**: Voice_Assistant detects disconnection, System does NOT create incomplete Rescue_Case, Vapi_Call_ID is not consumed
- **Requirement Impact**: Requirement 3 (Idempotency) - partial data is not stored

### Edge Case 2: Coordinator Assigns Already-Assigned Case (Race Condition)
- **Scenario**: Two Coordinators view the same Verified case and attempt assignment to different Volunteers simultaneously
- **Expected Behavior**: Database row lock ensures only first assignment succeeds, second Coordinator receives CASE_ALREADY_ASSIGNED error
- **Requirement Impact**: Requirement 7 (Volunteer Assignment with Concurrency Control)

### Edge Case 3: Volunteer Loses Internet While En Route
- **Scenario**: Volunteer updates status to En_Route, then loses mobile data connection
- **Expected Behavior**: Mobile_App queues status update locally, retries with exponential backoff when connection restored, System accepts update with original timestamp
- **Requirement Impact**: Requirement 16 (WebSocket Connection Management) - reconnection and queued operations

### Edge Case 4: Priority Overrides to Lower Priority
- **Scenario**: Coordinator overrides Critical case to Routine after investigation reveals false alarm
- **Expected Behavior**: System allows override, requires detailed reason, logs original and new priority, broadcasts WebSocket update
- **Requirement Impact**: Requirement 6 (Case Verification) - priority override with reason

### Edge Case 5: Reporter Provides Invalid Phone Number
- **Scenario**: Reporter enters phone number in incorrect format during mobile app submission
- **Expected Behavior**: System validates E.164 format, returns VALIDATION_ERROR with field-specific message, does not create case
- **Requirement Impact**: Requirement 17 (Input Validation) - phone number format validation

### Edge Case 6: Database Connection Lost During Assignment
- **Scenario**: Database connection drops after Coordinator initiates assignment but before transaction commit
- **Expected Behavior**: System rolls back transaction, returns DATABASE_UNAVAILABLE error, assignment is not recorded, Coordinator can retry
- **Requirement Impact**: Requirement 18 (Error Handling) - transaction rollback and error recovery

### Edge Case 7: Vapi Retry After Successful Case Creation
- **Scenario**: Voice_Assistant successfully creates case, response times out, Vapi retries with same Vapi_Call_ID
- **Expected Behavior**: System detects existing case with Vapi_Call_ID, returns original case data without duplication
- **Requirement Impact**: Requirement 3 (Idempotent Case Creation)

### Edge Case 8: Volunteer Accepts Case Assigned to Different Volunteer
- **Scenario**: Case is reassigned while original Volunteer's Mobile_App is offline, original Volunteer attempts acceptance when reconnected
- **Expected Behavior**: System validates assigned Volunteer user_id, returns FORBIDDEN error with message indicating reassignment
- **Requirement Impact**: Requirement 8 (Volunteer Case Acceptance) - validation of matching Volunteer user_id

### Edge Case 9: System Admin Views Case from Different Organization
- **Scenario**: system_admin user queries case from Organization they are not a member of for audit investigation
- **Expected Behavior**: System allows access with explicit override flag, logs cross-organization access with reason in Audit_Log
- **Requirement Impact**: Requirement 11 (Organization-Scoped Data Isolation) - admin override with audit

### Edge Case 10: Case List Query with No Matching Results
- **Scenario**: Coordinator filters cases by status=Critical and species=poultry, no matching cases exist
- **Expected Behavior**: System returns empty array with pagination metadata showing total=0, responds within performance target
- **Requirement Impact**: Requirement 14 (Case List and Filtering) - empty result handling

---

## Requirements Summary

This specification defines **23 functional requirements** covering:
- Multi-channel case submission (voice and mobile app)
- Voice AI integration with Vapi tool endpoints
- Idempotent operations for retry scenarios
- Explainable priority classification using transparent rules
- Real-time case distribution via WebSocket
- Case verification and priority override by coordinators
- Volunteer assignment with concurrency protection
- Field status updates through defined workflow
- Comprehensive audit trail and timeline
- Organization-scoped multi-tenancy
- PII encryption and protection
- Role-based authentication and authorization
- Input validation and error handling
- Performance and scalability targets
- Database schema and migration management
- Testing requirements
- API documentation
- Deployment configuration

All requirements follow EARS patterns (Ubiquitous, Event-driven, State-driven, Unwanted event, Optional feature, Complex) and comply with INCOSE quality rules (clarity, testability, completeness, positive statements).

---

**Next Phase**: Design document will specify architecture, data models, API contracts, and implementation approach.
