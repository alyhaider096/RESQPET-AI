# Repository Structure & Organization

## Monorepo Layout

```
resqpet-ai/
├── backend/              # FastAPI backend application
├── mobile/               # Flutter mobile application
├── ml/                   # Machine learning models and training
├── docs/                 # Project documentation
├── infra/                # Infrastructure and deployment configs
├── .kiro/                # Kiro specifications and steering
│   ├── steering/         # Project-wide guidance documents
│   └── specs/            # Feature specifications
├── docker-compose.yml    # Local development services
├── .env.example          # Environment variable template
├── .gitignore            # Git ignore patterns
├── LICENSE               # MIT License
├── README.md             # Project overview and setup
└── HACKATHON_CONTRIBUTIONS.md  # Attribution and timeline
```

---

## Backend Structure (`backend/`)

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app initialization
│   ├── config.py                  # Environment configuration
│   ├── database.py                # Database connection and session
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py                # Dependency injection (get_db, get_current_user)
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── router.py          # Main API router
│   │       ├── auth.py            # Authentication endpoints
│   │       ├── cases.py           # Rescue case endpoints
│   │       ├── organizations.py   # Organization management
│   │       ├── users.py           # User management
│   │       ├── voice.py           # Vapi tool endpoints
│   │       └── websocket.py       # WebSocket endpoint
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py                # User SQLAlchemy model
│   │   ├── organization.py        # Organization model
│   │   ├── case.py                # Rescue case model
│   │   ├── animal.py              # Animal profile model
│   │   ├── assignment.py          # Case assignment model
│   │   ├── audit_log.py           # Audit trail model
│   │   └── ...                    # Other domain models
│   │
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user.py                # User Pydantic schemas
│   │   ├── organization.py        # Organization schemas
│   │   ├── case.py                # Rescue case schemas
│   │   ├── auth.py                # Authentication schemas
│   │   ├── voice.py               # Vapi tool schemas
│   │   └── ...                    # Other request/response schemas
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth_service.py        # Authentication logic
│   │   ├── case_service.py        # Rescue case business logic
│   │   ├── triage_service.py      # Priority classification
│   │   ├── notification_service.py # WebSocket events
│   │   ├── encryption_service.py  # PII encryption
│   │   └── ...                    # Other business logic
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py            # JWT, hashing, encryption
│   │   ├── exceptions.py          # Custom exceptions
│   │   ├── middleware.py          # Custom middleware
│   │   └── events.py              # WebSocket event definitions
│   │
│   └── utils/
│       ├── __init__.py
│       ├── validators.py          # Custom validators
│       ├── helpers.py             # Utility functions
│       └── constants.py           # Application constants
│
├── alembic/
│   ├── versions/                  # Database migrations
│   ├── env.py                     # Alembic environment
│   └── script.py.mako             # Migration template
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py                # pytest fixtures
│   ├── test_auth.py               # Authentication tests
│   ├── test_cases.py              # Rescue case tests
│   ├── test_voice.py              # Vapi tool tests
│   ├── test_websocket.py          # WebSocket tests
│   └── ...                        # Other test modules
│
├── scripts/
│   ├── seed_data.py               # Demo data seeding
│   ├── create_admin.py            # Admin user creation
│   └── ...                        # Other utility scripts
│
├── requirements.txt               # Production dependencies
├── requirements-dev.txt           # Development dependencies
├── alembic.ini                    # Alembic configuration
├── pytest.ini                     # pytest configuration
├── .env.example                   # Environment template
└── README.md                      # Backend-specific docs
```

### Backend Module Responsibilities

**`app/main.py`**: FastAPI app initialization, CORS, middleware, routers  
**`app/config.py`**: Load and validate environment variables  
**`app/database.py`**: SQLAlchemy engine, session maker, base model  

**`app/api/`**: HTTP endpoints organized by resource  
**`app/models/`**: SQLAlchemy ORM models (database tables)  
**`app/schemas/`**: Pydantic models (request/response validation)  
**`app/services/`**: Business logic, separate from HTTP layer  
**`app/core/`**: Security, exceptions, shared infrastructure  

**`alembic/`**: Database schema migrations  
**`tests/`**: pytest test suite  
**`scripts/`**: One-off utility scripts  

### Backend Naming Conventions

- **Files**: `snake_case.py`
- **Classes**: `PascalCase`
- **Functions**: `snake_case()`
- **Constants**: `UPPER_SNAKE_CASE`
- **Private methods**: `_leading_underscore()`
- **Async functions**: `async def get_user()` (no special prefix)

---

## Mobile Structure (`mobile/`)

```
mobile/
├── android/                       # Android-specific configuration
├── ios/                           # iOS-specific configuration
├── lib/
│   ├── main.dart                  # App entry point
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart    # Environment configuration
│   │   │   └── routes.dart        # App routing
│   │   ├── constants/
│   │   │   ├── api_constants.dart # API endpoints
│   │   │   ├── app_colors.dart    # Color palette
│   │   │   └── app_strings.dart   # String constants
│   │   ├── services/
│   │   │   ├── api_service.dart   # HTTP client wrapper
│   │   │   ├── auth_service.dart  # Authentication logic
│   │   │   ├── websocket_service.dart # WebSocket client
│   │   │   └── storage_service.dart   # Secure local storage
│   │   └── utils/
│   │       ├── validators.dart    # Input validation
│   │       ├── formatters.dart    # Date, phone formatting
│   │       └── helpers.dart       # Utility functions
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── models/        # Data models
│   │   │   │   └── repositories/  # Data layer
│   │   │   ├── presentation/
│   │   │   │   ├── screens/       # Login, register screens
│   │   │   │   ├── widgets/       # Reusable widgets
│   │   │   │   └── providers/     # State management
│   │   │   └── domain/
│   │   │       └── entities/      # Business entities
│   │   │
│   │   ├── rescue/
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── case_list_screen.dart
│   │   │   │   │   ├── case_detail_screen.dart
│   │   │   │   │   ├── report_screen.dart
│   │   │   │   │   └── status_update_screen.dart
│   │   │   │   └── widgets/
│   │   │   └── domain/
│   │   │
│   │   ├── volunteer/
│   │   │   └── ...
│   │   │
│   │   └── profile/
│   │       └── ...
│   │
│   ├── shared/
│   │   ├── widgets/               # Common widgets
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_widget.dart
│   │   └── models/                # Shared data models
│   │
│   └── l10n/                      # Localization (English/Urdu)
│       ├── app_en.arb
│       └── app_ur.arb
│
├── test/
│   ├── widget_test.dart           # Widget tests
│   ├── unit_test.dart             # Unit tests
│   └── ...
│
├── assets/
│   ├── images/                    # Image assets
│   ├── icons/                     # Icon assets
│   └── fonts/                     # Custom fonts (if any)
│
├── pubspec.yaml                   # Flutter dependencies
├── analysis_options.yaml          # Linter configuration
└── README.md                      # Mobile-specific docs
```

### Mobile Architecture Pattern

**Clean Architecture with Feature-First Organization**:
- **Data Layer**: Models, repositories, API clients
- **Domain Layer**: Business entities, use cases
- **Presentation Layer**: Screens, widgets, state management

### Mobile Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Functions**: `camelCase()`
- **Constants**: `camelCase` or `UPPER_SNAKE_CASE`
- **Private members**: `_leadingUnderscore`
- **Widgets**: End with `Widget` suffix (e.g., `CaseListWidget`)

---

## ML Structure (`ml/`)

```
ml/
├── notebooks/
│   ├── exploratory_data_analysis.ipynb
│   ├── model_training.ipynb
│   └── model_evaluation.ipynb
│
├── data/
│   ├── raw/                       # Original datasets
│   ├── processed/                 # Cleaned datasets
│   └── .gitkeep
│
├── models/
│   ├── triage_classifier/
│   │   ├── model.py               # Model definition
│   │   ├── train.py               # Training script
│   │   ├── evaluate.py            # Evaluation script
│   │   └── inference.py           # Inference wrapper
│   └── .gitkeep
│
├── scripts/
│   ├── preprocess_data.py
│   ├── train_model.py
│   └── export_model.py
│
├── requirements.txt               # ML-specific dependencies
└── README.md                      # ML documentation
```

**Note**: ML work is P1/P2. Focus on P0 rule-based triage first.

---

## Docs Structure (`docs/`)

```
docs/
├── architecture/
│   ├── system_overview.md
│   ├── database_schema.md
│   ├── api_contracts.md
│   └── websocket_events.md
│
├── guides/
│   ├── setup_guide.md
│   ├── deployment_guide.md
│   └── testing_guide.md
│
├── security/
│   ├── security_risk_register.md
│   ├── authentication.md
│   └── data_protection.md
│
└── api/
    └── openapi.yaml                # Auto-generated from FastAPI
```

---

## Infra Structure (`infra/`)

```
infra/
├── docker/
│   ├── backend.Dockerfile
│   └── postgres.Dockerfile
│
├── kubernetes/                     # P2 - production deployment
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
└── scripts/
    ├── deploy.sh
    └── rollback.sh
```

---

## Kiro Structure (`.kiro/`)

```
.kiro/
├── steering/
│   ├── product.md                 # Product vision and priorities
│   ├── tech.md                    # Technology stack and constraints
│   ├── structure.md               # This file - repository organization
│   └── security.md                # Security requirements
│
└── specs/
    ├── rescue-operations/
    │   ├── requirements.md        # User stories and acceptance criteria
    │   ├── design.md              # Architecture and technical design
    │   ├── tasks.md               # Implementation checklist
    │   └── .config.kiro           # Spec metadata
    │
    ├── auth-and-organizations/
    │   ├── requirements.md
    │   ├── design.md
    │   └── tasks.md
    │
    ├── voice-intake/
    │   ├── requirements.md
    │   ├── design.md
    │   └── tasks.md
    │
    └── realtime-case-updates/
        ├── requirements.md
        ├── design.md
        └── tasks.md
```

### Kiro Spec Workflow

1. **Start with requirements**: User stories, acceptance criteria
2. **Create design**: Architecture, data models, API contracts
3. **Break into tasks**: Small, testable implementation steps
4. **Implement incrementally**: Check off tasks as you complete them
5. **Update specs**: If requirements or design change during implementation

---

## Docker Compose Services

```yaml
services:
  postgres:     # PostgreSQL database
  backend:      # FastAPI application
  # frontend:   # Optional - if we add web dashboard
```

---

## File Naming Patterns

### Python Backend
- Models: `{domain}.py` (e.g., `user.py`, `case.py`)
- Schemas: `{domain}.py` (e.g., `user.py`, `case.py`)
- Services: `{domain}_service.py` (e.g., `auth_service.py`)
- Tests: `test_{feature}.py` (e.g., `test_auth.py`)
- Migrations: `{timestamp}_{description}.py` (auto-generated by Alembic)

### Flutter Mobile
- Screens: `{name}_screen.dart` (e.g., `login_screen.dart`)
- Widgets: `{name}_widget.dart` (e.g., `case_card_widget.dart`)
- Models: `{name}_model.dart` (e.g., `case_model.dart`)
- Services: `{name}_service.dart` (e.g., `api_service.dart`)
- Providers: `{name}_provider.dart` (e.g., `case_provider.dart`)

### Documentation
- Use descriptive names: `database_schema.md`, `api_contracts.md`
- Prefix with category if helpful: `guide_setup.md`, `arch_overview.md`

---

## Import Organization

### Python
```python
# Standard library
import os
from datetime import datetime

# Third-party
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session

# Local application
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import get_password_hash
```

Use `isort` to auto-format imports.

### Dart
```dart
// Dart SDK
import 'dart:async';

// Flutter
import 'package:flutter/material.dart';

// Third-party packages
import 'package:provider/provider.dart';

// Local
import '../models/case_model.dart';
import '../services/api_service.dart';
```

---

## Code Organization Best Practices

1. **Keep files focused**: Each file should have a single responsibility
2. **Separate concerns**: API logic ≠ Business logic ≠ Data access
3. **Use dependency injection**: Pass dependencies explicitly
4. **Group related code**: Features > Layers for mobile
5. **Avoid circular imports**: Use interfaces or forward declarations
6. **Test alongside code**: `tests/` mirrors `app/` structure
7. **Document public APIs**: Docstrings for all public functions/classes

---

## Adding New Features

### Backend Feature Checklist
1. Create spec in `.kiro/specs/{feature}/`
2. Add model in `app/models/{domain}.py`
3. Add schemas in `app/schemas/{domain}.py`
4. Create service in `app/services/{domain}_service.py`
5. Add API endpoints in `app/api/v1/{domain}.py`
6. Create migration with `alembic revision --autogenerate -m "..."`
7. Write tests in `tests/test_{feature}.py`
8. Update API documentation
9. Run tests and verify

### Mobile Feature Checklist
1. Create feature directory in `lib/features/{feature}/`
2. Add data models in `data/models/`
3. Create repository in `data/repositories/`
4. Add screens in `presentation/screens/`
5. Create reusable widgets in `presentation/widgets/`
6. Set up state management in `presentation/providers/`
7. Add routes in `core/config/routes.dart`
8. Write widget and unit tests
9. Test on physical device

---

## Version Control

### Branch Strategy
- `main`: Stable, deployable code
- `develop`: Integration branch for features
- `feature/{name}`: Individual features
- `bugfix/{name}`: Bug fixes
- `hotfix/{name}`: Urgent production fixes

### Commit Message Format
```
{type}({scope}): {subject}

{body}

{footer}
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`  
**Example**: `feat(rescue): add case assignment endpoint`

---

## Configuration Management

- **Development**: `.env` (local, not committed)
- **CI/CD**: Environment variables in pipeline
- **Production**: Secret manager (AWS Secrets Manager, etc.)

Never commit:
- `.env` files
- API keys
- Database credentials
- JWT secrets
- Private keys

---

This structure supports:
- ✅ Clear separation of concerns
- ✅ Scalability (easy to add features)
- ✅ Team collaboration (minimal conflicts)
- ✅ Testing (isolated, mockable components)
- ✅ Documentation (self-documenting structure)
