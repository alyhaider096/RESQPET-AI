# Security Requirements & Best Practices

## Critical Security Context

**⚠️ IMPORTANT**: An earlier version of the Animal Welfare AI project contained an exposed OpenAI API key in the Flutter client code. That key has been **revoked** and must **NEVER** be copied or reused.

This project implements defense-in-depth security to prevent similar issues.

---

## Security Principles

1. **Defense in Depth**: Multiple layers of security controls
2. **Least Privilege**: Users and services have minimum required permissions
3. **Secure by Default**: Security controls enabled from the start
4. **Zero Trust**: Verify every request, never assume trust
5. **Data Minimization**: Collect and retain only necessary data
6. **Transparency**: Log security events, be transparent about incidents

---

## Secrets Management

### Never Store Secrets In:
- ❌ Client applications (Flutter, web, mobile)
- ❌ Git repositories (including commit history)
- ❌ Docker images
- ❌ Environment variables visible to clients
- ❌ Configuration files committed to version control
- ❌ Log files or error messages
- ❌ API responses
- ❌ URLs or query parameters

### Always Store Secrets In:
- ✅ Environment variables loaded server-side
- ✅ Secret management services (AWS Secrets Manager, HashiCorp Vault)
- ✅ Encrypted configuration files (with keys stored separately)
- ✅ Secure environment-specific .env files (gitignored)

### Secret Categories

**Critical Secrets** (require immediate rotation if exposed):
- Database credentials
- JWT signing keys
- PII encryption keys
- Provider API keys (OpenAI, Vapi, Twilio)
- Admin passwords

**Sensitive Secrets** (require rotation if exposed):
- Service-to-service authentication tokens
- Webhook secrets
- Session encryption keys

### Secret Generation

Generate cryptographically secure secrets:

```bash
# JWT and encryption keys (32 bytes = 256 bits)
openssl rand -hex 32

# Shorter secrets (16 bytes = 128 bits)
openssl rand -hex 16

# Base64-encoded secrets
openssl rand -base64 32
```

### Secret Rotation Schedule

- **Critical secrets**: Rotate every 90 days or immediately if exposed
- **Sensitive secrets**: Rotate every 180 days
- **Service tokens**: Rotate on team member departure
- **Admin credentials**: Rotate quarterly

---

## Authentication & Authorization

### JWT Implementation

**Access Tokens**:
- Expire: 30 minutes
- Payload: user_id, email, role, organization_id
- Algorithm: HS256 or RS256 (document choice)
- Signed with `JWT_SECRET_KEY`

**Refresh Tokens**:
- Expire: 7 days
- Stored: httpOnly cookies or secure storage
- One-time use: invalidate after refresh
- Store hash in database for revocation

**Security Requirements**:
- Never expose JWT secret to clients
- Validate signature on every request
- Check expiration (exp claim)
- Verify issuer (iss claim)
- Implement token revocation list for logout
- Use secure random token generation

### Role-Based Access Control (RBAC)

**Roles**:
- `system_admin`: Full system access
- `ngo_coordinator`: Organization management, case oversight
- `rescue_volunteer`: Assigned case updates
- `veterinarian`: Consultation access
- `pet_owner`: Own animals and cases
- `livestock_farmer`: Own herds and cases
- `public_reporter`: Submit anonymous reports

**Permission Enforcement**:
- Check role on every protected endpoint
- Combine role check with organization membership
- Never rely only on UI hiding
- Log authorization failures

### Multi-Tenancy & Data Isolation

**Organization Scoping**:
```python
# CORRECT: Filter by organization_id
cases = db.query(Case).filter(
    Case.organization_id == current_user.organization_id
).all()

# WRONG: No organization filter
cases = db.query(Case).all()  # Exposes all organizations' data!
```

**Enforcement Rules**:
- Every protected query MUST filter by organization_id
- Use database row-level security (RLS) where supported
- Validate organization membership in middleware
- Log cross-organization access attempts
- System admins can override with explicit flag and audit log

---

## Data Protection

### PII (Personally Identifiable Information)

**PII Fields**:
- Full names
- Phone numbers
- Email addresses
- Exact addresses (street level)
- National ID numbers
- Medical information
- Photos with faces
- Voice recordings

**Protection Requirements**:

1. **Encryption at Rest**:
   - Encrypt PII fields using `PII_ENCRYPTION_KEY`
   - Use AES-256-GCM or similar authenticated encryption
   - Store IV/nonce with ciphertext
   - Never reuse IVs

2. **Encryption in Transit**:
   - HTTPS/TLS 1.3 for all external communication
   - WSS (WebSocket Secure) for real-time connections
   - Certificate pinning for mobile apps (optional)

3. **Access Control**:
   - Log all PII access
   - Mask in UI unless explicitly needed
   - Redact from logs and error messages
   - Implement field-level permissions

4. **Data Minimization**:
   - Collect only necessary PII
   - Anonymize or pseudonymize where possible
   - Delete after retention period
   - Don't store raw transcripts unless required

### Phone Number Handling

**Never store plaintext phone numbers for lookup**:

```python
# Store hashed phone for lookup
import hashlib

def hash_phone(phone: str, salt: str) -> str:
    return hashlib.sha256(f"{phone}{salt}".encode()).hexdigest()

# Lookup by hash
phone_hash = hash_phone(incoming_phone, settings.PHONE_HASH_SALT)
user = db.query(User).filter(User.phone_hash == phone_hash).first()

# Store encrypted phone for display
user.phone_encrypted = encrypt_pii(incoming_phone)
```

### Audit Logging

**Log Security-Sensitive Events**:
- Authentication attempts (success and failure)
- Authorization failures
- PII access
- Role changes
- Organization membership changes
- Rescue case assignments
- Priority overrides
- Data exports

**Audit Log Format**:
```json
{
  "timestamp": "2026-10-25T10:30:00Z",
  "event_type": "CASE_ASSIGNED",
  "user_id": "uuid",
  "organization_id": "uuid",
  "resource_type": "rescue_case",
  "resource_id": "uuid",
  "action": "assign_volunteer",
  "result": "success",
  "ip_address": "masked",
  "user_agent": "redacted",
  "metadata": {
    "volunteer_id": "uuid",
    "case_id": "uuid"
  }
}
```

**Audit Log Protection**:
- Write-only for application
- Separate database or append-only storage
- Tamper detection (cryptographic hashing)
- Regular export to secure archive
- Retention: minimum 1 year

---

## Input Validation

### Validation Requirements

1. **Type Validation**: Use Pydantic models for all inputs
2. **Range Validation**: Check min/max for numbers, lengths
3. **Format Validation**: Phone, email, URL patterns
4. **Whitelist Validation**: Enum values, allowed file types
5. **Business Logic Validation**: State transitions, uniqueness

### SQL Injection Prevention

**Always use parameterized queries**:

```python
# CORRECT: Parameterized query
user = db.query(User).filter(User.email == email).first()

# WRONG: String concatenation
query = f"SELECT * FROM users WHERE email = '{email}'"  # Vulnerable!
```

SQLAlchemy ORM provides automatic parameterization. Never use raw SQL strings.

### XSS Prevention

- Sanitize user-generated content before storage
- Use Content-Security-Policy headers
- Escape output in templates
- Validate and sanitize HTML if accepting rich text

### File Upload Security

**Validation**:
- Check file extension (whitelist: .jpg, .png, .mp4, .mp3)
- Validate MIME type (not just extension)
- Check file size limits
- Scan for malware (optional: ClamAV)
- Strip EXIF data if not needed

**Storage**:
- Store outside web root
- Generate random filenames
- Use signed URLs for access
- Implement rate limiting on uploads

**Example Limits**:
- Images: 5 MB max
- Videos: 30 MB max (compress in client)
- Audio: 10 MB max

---

## API Security

### Rate Limiting

**Per-IP Rate Limits**:
- Public endpoints: 60 requests/minute
- Authenticated endpoints: 120 requests/minute
- Vapi webhooks: 300 requests/minute (burst tolerance)

**Per-User Rate Limits**:
- Report submission: 10 per hour
- Case updates: 60 per hour
- File uploads: 20 per hour

**Implementation**: Use Redis or in-memory store with sliding window

### CORS Configuration

```python
# Restrictive CORS for production
allow_origins = [
    "https://animalcare.pk",
    "https://app.animalcare.pk"
]

# Development: localhost only
allow_origins = [
    "http://localhost:3000",
    "http://localhost:8000"
]

# NEVER use "*" in production
```

### Request Size Limits

- Request body: 10 MB max (file uploads)
- JSON payload: 1 MB max
- Query string: 2048 characters max
- Headers: 8 KB max

### HTTPS/TLS

**Requirements**:
- TLS 1.3 preferred, TLS 1.2 minimum
- Strong cipher suites only
- Certificate from trusted CA (Let's Encrypt, etc.)
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- Redirect HTTP to HTTPS

---

## Vapi Integration Security

### Tool Endpoint Authentication

**Verify Vapi requests**:

```python
from fastapi import Header, HTTPException

async def verify_vapi_request(
    authorization: str = Header(None)
):
    if not authorization:
        raise HTTPException(401, "Missing Authorization header")
    
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "Invalid Authorization format")
    
    token = authorization.replace("Bearer ", "")
    
    if token != settings.VAPI_TOOL_SECRET:
        raise HTTPException(401, "Invalid Vapi tool secret")
    
    return True
```

### Idempotency

**Prevent duplicate case creation**:

```python
# Store Vapi call_id to detect retries
vapi_call_id = request_data.get("call_id")

existing = db.query(RescueCase).filter(
    RescueCase.vapi_call_id == vapi_call_id
).first()

if existing:
    return existing  # Return original result
```

**Database constraint**:
```sql
CREATE UNIQUE INDEX idx_rescue_cases_vapi_call_id 
ON rescue_cases(vapi_call_id) 
WHERE vapi_call_id IS NOT NULL;
```

---

## WebSocket Security

### Authentication

**Verify JWT before subscription**:

```python
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(None)
):
    if not token:
        await websocket.close(code=1008)  # Policy violation
        return
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user_id = payload.get("user_id")
        organization_id = payload.get("organization_id")
    except JWTError:
        await websocket.close(code=1008)
        return
    
    await websocket.accept()
    # Subscribe to organization-scoped events only
```

### Message Filtering

**Never broadcast PII**:

```python
# CORRECT: Send only case ID and status
event = {
    "type": "case.updated",
    "case_id": case.id,
    "status": case.status,
    "priority": case.priority
}

# WRONG: Exposes PII
event = {
    "type": "case.updated",
    "reporter_name": case.reporter_name,  # PII!
    "reporter_phone": case.reporter_phone,  # PII!
    "address": case.address  # PII!
}
```

Clients must fetch full details via authenticated API.

---

## Mobile App Security

### Secure Storage

**Use flutter_secure_storage for**:
- JWT tokens
- User credentials (if persisted)
- Encryption keys

**Never use**:
- SharedPreferences for sensitive data
- Plain files
- SQLite without encryption

### Certificate Pinning (Optional)

Pin backend TLS certificate to prevent MITM:

```dart
// Example with dio package
final dio = Dio();
dio.httpClientAdapter = IOHttpClientAdapter()
  ..onHttpClientCreate = (client) {
    client.badCertificateCallback = 
        (X509Certificate cert, String host, int port) {
      // Verify certificate fingerprint
      return cert.sha256.toString() == EXPECTED_CERT_HASH;
    };
    return client;
  };
```

### Code Obfuscation

Build release APK with obfuscation:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

---

## Database Security

### Connection Security

- Use TLS for database connections in production
- Restrict database access to backend servers only
- Use strong database passwords (32+ characters)
- Create separate database users per service
- Grant minimum required privileges

### Backup Security

- Encrypt backups at rest
- Store backups in separate location
- Test restore procedures regularly
- Implement backup retention policy
- Control access to backups

### Migration Safety

- Review auto-generated migrations before applying
- Test migrations on copy of production data
- Always include rollback (downgrade) path
- Back up before running migrations
- Use transactions for data migrations

---

## Logging & Monitoring

### What to Log

✅ **Log**:
- Request method, path, status code
- Response time
- Authentication events
- Authorization failures
- Error stack traces
- Rate limit violations
- Unusual patterns

❌ **Never Log**:
- Passwords (plaintext or hashed)
- JWT tokens
- API keys
- PII (names, phones, addresses)
- Credit card numbers
- Session IDs
- Full request/response bodies with sensitive data

### Log Sanitization

```python
import re

def sanitize_log(message: str) -> str:
    # Redact phone numbers
    message = re.sub(r'\+?\d{10,15}', '[PHONE_REDACTED]', message)
    # Redact emails
    message = re.sub(r'[\w\.-]+@[\w\.-]+', '[EMAIL_REDACTED]', message)
    # Redact tokens
    message = re.sub(r'Bearer\s+[\w\-\.]+', 'Bearer [REDACTED]', message)
    return message
```

---

## Incident Response

### Security Incident Procedure

1. **Detect**: Monitor logs, alerts, user reports
2. **Contain**: Disable affected accounts, rotate secrets
3. **Investigate**: Determine scope and impact
4. **Remediate**: Fix vulnerability, apply patches
5. **Communicate**: Notify affected users if PII exposed
6. **Learn**: Post-mortem, improve controls

### Secret Exposure Response

**If a secret is exposed in code or logs**:

1. **Immediately revoke** the exposed secret
2. **Generate new secret** and update environment
3. **Review audit logs** for unauthorized usage
4. **Scan git history** and purge exposed secrets
5. **Force re-authentication** if tokens affected
6. **Document incident** and prevention measures

### Breach Notification

If PII is exposed:
- Determine scope (how many users, what data)
- Notify affected users within 72 hours
- Report to authorities if legally required
- Offer remediation (credit monitoring, etc.)
- Publish incident summary transparently

---

## Compliance & Privacy

### Data Retention

- **Rescue cases**: 2 years after closure
- **Audit logs**: 1 year minimum
- **User accounts**: Delete on request (GDPR right to erasure)
- **Anonymize old data**: Remove PII from closed cases

### User Rights

Support user privacy rights:
- **Access**: Export user data on request
- **Rectification**: Allow profile updates
- **Erasure**: Delete account and data
- **Portability**: Provide data in machine-readable format

### AI Transparency

- Document AI usage in privacy policy
- Never claim AI can diagnose animals
- Explain triage priority reasoning
- Allow human override of AI decisions
- Log AI decisions for audit

---

## Security Testing

### Pre-Deployment Checklist

- [ ] All secrets loaded from environment variables
- [ ] No hardcoded credentials in code
- [ ] Secret scanning tool run (git-secrets, trufflehog)
- [ ] Dependency vulnerability scan (pip-audit, safety)
- [ ] HTTPS enforced
- [ ] CORS configured restrictively
- [ ] Rate limiting enabled
- [ ] JWT expiration tested
- [ ] Organization isolation tested
- [ ] Input validation tested
- [ ] Authentication tests passing
- [ ] Authorization tests passing
- [ ] Audit logging verified
- [ ] Error messages don't leak sensitive info

### Continuous Security

- Run secret scanner on every commit
- Automated dependency updates (Dependabot, Renovate)
- Regular security audits
- Penetration testing before production launch
- Bug bounty program (optional)

---

## Security Tools

### Recommended Tools

**Secret Scanning**:
- git-secrets
- trufflehog
- gitleaks

**Dependency Scanning**:
- pip-audit (Python)
- safety (Python)
- pub audit (Dart)

**Static Analysis**:
- bandit (Python security linting)
- semgrep (multi-language)
- dartanalyzer (Dart)

**Dynamic Testing**:
- OWASP ZAP
- Burp Suite
- sqlmap (SQL injection testing)

---

## Security Contacts

**Report Security Issues**:
- Email: security@animalcare.pk (create this)
- Do NOT open public GitHub issues for security vulnerabilities
- Use responsible disclosure: 90-day notice before public disclosure

---

**Review this file before deploying to production or handling real user data.**
