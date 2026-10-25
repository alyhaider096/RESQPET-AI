# Technology Stack & Constraints

## Backend Technology Decisions

### Framework: FastAPI
**Why**: High performance, automatic OpenAPI documentation, native async support, excellent type hints.

**Constraints**:
- Python 3.11+ required
- Use Pydantic v2 for all request/response models
- Enable strict type checking
- Follow REST conventions for public APIs
- Use snake_case for Python code

### Database: PostgreSQL 15+
**Why**: ACID compliance, JSON support, robust for production, excellent tooling.

**Constraints**:
- PostgreSQL is the single source of truth
- Do NOT use Firebase, Firestore, or other NoSQL databases
- All queries must enforce organization_id for multi-tenancy
- Use database transactions for multi-step operations
- Never expose raw SQL to clients

### ORM: SQLAlchemy 2.0
**Why**: Mature, powerful, type-safe with modern patterns.

**Constraints**:
- Use declarative models
- Enable lazy loading carefully (avoid N+1 queries)
- Use relationship loading strategies explicitly
- All models must have created_at and updated_at timestamps
- Use Alembic for all schema migrations

### Migrations: Alembic
**Why**: Industry standard for SQLAlchemy.

**Constraints**:
- Never modify committed migrations
- Always review auto-generated migrations
- Add both upgrade and downgrade paths
- Test migrations against demo data
- Use descriptive revision messages

### Authentication: JWT
**Why**: Stateless, scalable, standard.

**Constraints**:
- Access tokens expire in 30 minutes
- Refresh tokens expire in 7 days
- Use RS256 or HS256 (document choice)
- Store tokens securely (httpOnly cookies or secure storage)
- Implement token refresh endpoint

## Frontend Technology Decisions

### Mobile Framework: Flutter
**Why**: Cross-platform, native performance, rich widget ecosystem.

**Constraints**:
- Flutter SDK 3.10+
- Use Provider or Riverpod for state management
- Follow Material Design 3 guidelines
- Support Android API 21+ (Lollipop)
- Use secure_storage for tokens
- Implement proper error boundaries

### State Management
**Recommendation**: Riverpod (if team is familiar) or Provider

**Constraints**:
- Centralize API calls in repository classes
- Use stream controllers for WebSocket
- Implement loading, success, and error states
- Cache responses appropriately
- Handle offline scenarios gracefully

## Voice AI: Vapi

**Why**: Production-ready voice agents, tool calling, phone integration.

**Constraints**:
- All Vapi tool endpoints must require Bearer token authentication
- Implement idempotency using Vapi call IDs
- Return structured JSON responses
- Handle timeout and retry scenarios
- Never expose Vapi secrets to clients
- Use HTTPS tunnel (ngrok/cloudflared) for local testing

## Real-Time: WebSocket

**Why**: Native browser/mobile support, low latency, bidirectional.

**Constraints**:
- Authenticate via JWT before subscription
- Use typed, versioned events
- Implement heartbeat/ping every 30 seconds
- Support exponential backoff reconnection
- Filter events by organization_id
- Never broadcast PII in event payloads

## Containerization: Docker Compose

**Why**: Consistent local development, easy onboarding.

**Constraints**:
- Development configuration only (not production)
- PostgreSQL, backend, and optional frontend services
- Use named volumes for data persistence
- Map ports consistently (8000 for backend, 5432 for DB)
- Include health checks

## Testing

### Backend: pytest
**Requirements**:
- Unit tests for business logic
- Integration tests for API endpoints
- Fixture-based test data
- Minimum 80% coverage for critical paths
- Test auth, RBAC, and organization isolation

### Mobile: flutter_test
**Requirements**:
- Widget tests for screens
- Unit tests for business logic
- Mock HTTP and WebSocket clients
- Test offline scenarios
- Minimum 70% coverage for core features

## Code Quality

### Python
- **Linter**: ruff or flake8
- **Formatter**: black
- **Type checker**: mypy
- **Import sorting**: isort

### Dart/Flutter
- **Linter**: flutter_lints
- **Formatter**: dart format

## Dependencies Management

### Backend
- Use `requirements.txt` for production dependencies
- Use `requirements-dev.txt` for development tools
- Pin major versions (e.g., `fastapi>=0.104,<1.0`)
- Review security advisories regularly

### Mobile
- Use `pubspec.yaml` with version constraints
- Prefer stable packages with active maintenance
- Document any custom forks or patches

## Environment Variables

**Requirements**:
- Use `.env` for local development
- Never commit `.env` to version control
- Provide comprehensive `.env.example`
- Use different secrets for development, staging, production
- Load via `python-dotenv` (backend) or `flutter_dotenv` (mobile)

## API Design

### REST Conventions
- Use HTTP verbs correctly (GET, POST, PATCH, DELETE)
- Return appropriate status codes
- Use consistent error response format
- Version APIs (`/api/v1/...`)
- Implement pagination for list endpoints

### Request/Response
- Use Pydantic models for validation
- Return consistent JSON structure
- Include metadata (timestamps, pagination info)
- Use camelCase in JSON (auto-convert from snake_case)

### Error Handling
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "User-friendly error message",
    "details": [...],
    "timestamp": "2026-10-25T10:00:00Z"
  }
}
```

## Security Requirements

### Secrets Management
- Use environment variables exclusively
- Never hardcode API keys, database credentials, or JWT secrets
- Use separate secrets for each environment
- Rotate secrets regularly
- Use secret management service in production (AWS Secrets Manager, etc.)

### Data Protection
- Encrypt PII at rest using `PII_ENCRYPTION_KEY`
- Use HTTPS for all external communication
- Hash phone numbers for lookup (don't store plaintext)
- Redact PII from logs
- Implement field-level encryption for sensitive data

### Input Validation
- Validate all inputs using Pydantic
- Sanitize user-generated content
- Validate file uploads (type, size, content)
- Protect against SQL injection (use parameterized queries)
- Implement rate limiting

### Authentication & Authorization
- JWT with short-lived access tokens
- Role-based access control (RBAC)
- Organization-scoped data queries
- Audit logging for sensitive operations
- Implement account lockout after failed attempts

## Performance Targets

### API Response Times (p95)
- GET /health: < 100ms
- Simple queries: < 200ms
- Complex queries: < 500ms
- Vapi tool endpoints: < 1s
- File uploads: < 5s (excluding network)

### Database
- Connection pooling (10-20 connections)
- Index frequently queried fields
- Use database-level constraints
- Optimize N+1 queries
- Monitor slow query log

### Mobile
- App startup: < 2s
- Screen transitions: < 300ms
- Image compression before upload
- Lazy load lists
- Cache API responses

## Monitoring & Observability

**Recommended** (P2 - post-hackathon):
- Structured logging (JSON format)
- Request ID tracing
- Performance metrics (response times, error rates)
- Health check endpoint with dependency status
- Sentry or similar for error tracking

## Infrastructure

### Local Development
- Docker Compose for services
- Local PostgreSQL
- HTTPS tunnel for Vapi testing (ngrok/cloudflared)
- Hot reload for backend and mobile

### Production (P2)
- Deploy backend to cloud (AWS, GCP, Azure, or Railway/Render)
- Use managed PostgreSQL (RDS, Cloud SQL, or Supabase)
- CDN for static assets
- Load balancer for multiple backend instances
- Automated backups
- Monitoring and alerting

## Third-Party Services

### Required for P0
- **Vapi**: Voice AI assistant
- **PostgreSQL**: Database (can be local or hosted)

### Optional (P1/P2)
- **AWS S3** or **Cloudinary**: Media storage
- **Google Maps API**: Location services
- **Twilio**: SMS notifications
- **Sentry**: Error tracking
- **OpenAI**: Additional AI features beyond Vapi

## Technology Anti-Patterns (DO NOT USE)

❌ **Firebase/Firestore**: Migrate to PostgreSQL  
❌ **Client-side API keys**: All provider calls go through backend  
❌ **Synchronous blocking operations**: Use async/await  
❌ **Global state without proper management**: Use state management pattern  
❌ **Raw SQL strings**: Use SQLAlchemy ORM  
❌ **Storing secrets in code**: Use environment variables  
❌ **Monolithic god functions**: Break into small, testable units  
❌ **Missing error handling**: Always handle exceptions gracefully  
❌ **Hardcoded configuration**: Use environment-based config  
❌ **Skipping tests**: Write tests as you build features  

## Development Workflow

1. **Read the spec** (`.kiro/specs/{feature}/requirements.md` and `design.md`)
2. **Write tests first** (TDD approach recommended)
3. **Implement feature** in small, testable increments
4. **Run tests** after each change
5. **Update documentation** if APIs or behavior change
6. **Commit with meaningful messages** (reference spec tasks)
7. **Request review** before merging to main

## Dependency Versions (Minimum)

### Backend
- Python: 3.11+
- FastAPI: 0.104+
- SQLAlchemy: 2.0+
- Pydantic: 2.0+
- Alembic: 1.12+
- pytest: 7.4+
- uvicorn: 0.24+

### Mobile
- Flutter SDK: 3.10+
- Dart: 3.0+

### Infrastructure
- PostgreSQL: 15+
- Docker: 20.10+
- Docker Compose: 2.0+

## Current Architecture Direction

1. FastAPI issues JWT access tokens and enforces role-based access control.
2. PostgreSQL stores organization-scoped rescue data through SQLAlchemy.
3. File storage will use a backend-controlled local or S3-compatible service.
4. WebSocket events provide real-time case updates without exposing PII.
5. Vapi tool calls enter through authenticated, idempotent backend endpoints.
6. Flutter provides the mobile and web user experience.

## Open Source Compliance

- Use only permissively licensed dependencies (MIT, Apache-2.0, BSD)
- Document all third-party licenses
- Respect license attribution requirements
- Avoid GPL-licensed libraries (licensing conflict)

---

**Review this file before making technology decisions that deviate from these constraints.**
