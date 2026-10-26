# ResQPet AI

**AI-Assisted Animal Welfare Operating System for Pakistan**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Built with Kiro](https://img.shields.io/badge/Built%20with-Kiro-purple)](https://kiro.ai)

---

## 🚀 Project Overview

ResQ Pet AI is an open-source animal welfare coordination platform connecting citizens, pet owners, livestock farmers, NGOs, rescue teams, veterinarians, and adopters across Pakistan.

**Hackathon Project**: Built during Hacktoberfest Hack Day (Oct 25-26, 2026)

### Feature Status

#### ✅ Implemented hackathon MVP
- 📁 **Project Structure** - Monorepo with backend, mobile, ml, docs, infra
- 🛠️ **Rescue API** - FastAPI case creation, verification, assignment, and tracked status transitions
- 🔐 **Role-Based Login** - Admin, NGO coordinator, rescue volunteer, and public reporter roles
- 🗄️ **Database Setup** - PostgreSQL/SQLite support with SQLAlchemy and Alembic migration
- 📞 **Vapi-Ready Intake** - Authenticated native tool-call webhook with retry-safe case creation
- 📱 **Flutter MVP** - Login, citizen reporting, NGO operations, and volunteer status flow
- 🗺️ **Rescue Paw Map** - GPS or tap-to-place locations and organization-scoped active rescue markers
- 📷 **Rescue Photos** - Camera/gallery reporting with authenticated photo storage and viewing
- 🩺 **Vet Care Requests** - Owner/farmer requests, veterinarian scheduling, and follow-up notes
- 🐄 **Heat-Cycle Concerns** - Reproductive-health consultation requests for pets and livestock
- 🎯 **Explainable Triage** - Critical/Urgent/Routine rules with recorded reasons
- 🔄 **Real-Time Events** - Organization-scoped WebSocket case updates
- 🐄 **Multi-Species Reports** - Pets, livestock, poultry, and working animals
- 📋 **Kiro Specifications** - Product, tech, structure, security steering
- 📝 **Rescue Operations Spec** - Requirements, design, and implementation tasks
- 🐳 **Docker Compose** - Local development environment
- ☁️ **Render Blueprint** - Reproducible HTTPS API and PostgreSQL demo deployment
- 🧪 **Automated Checks** - Backend API tests, coverage, Ruff, Flutter analysis, and widget test

#### 🔌 Needs deployment credentials

- A public HTTPS backend URL
- A Vapi assistant, phone number, and tool secret configured from `docs/VAPI_SETUP.md`
- Production secrets and PostgreSQL credentials

#### 📅 Planned (P1/P2 - Post-Hackathon)
- 🐾 **Adoption System** - Recovered animal listing and applications
- 📊 **Longitudinal Health Records** - Vaccination history and herd tracking
- 🤖 **ML Triage Model** - Machine learning enhancement (after rule-based system)

---

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Flutter   │◄────►│   FastAPI    │◄────►│ PostgreSQL  │
│  Mobile App │      │   Backend    │      │  Database   │
└─────────────┘      └──────────────┘      └─────────────┘
                            ▲
                            │
                     ┌──────┴──────┐
                     │   Vapi AI   │
                     │ Voice Agent │
                     └─────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile** | Flutter, Dart |
| **Backend** | FastAPI, Python 3.11+ |
| **Database** | PostgreSQL 15+ |
| **ORM** | SQLAlchemy, Alembic |
| **Voice AI** | Vapi |
| **Real-Time** | WebSocket |
| **Container** | Docker Compose |
| **Testing** | pytest, flutter_test |

Authentication is handled by the FastAPI backend with signed JWTs stored in
Flutter secure storage. Firebase is not used. PostgreSQL is the deployment
database; SQLite is supported only for a fast local hackathon demo.

---

## 📁 Repository Structure

```
resqpet-ai/
├── backend/           # FastAPI backend
├── mobile/            # Flutter mobile app
├── ml/                # ML models and training scripts
├── docs/              # Documentation
├── infra/             # Infrastructure and deployment configs
├── .kiro/             # Kiro specifications and steering
│   ├── steering/      # Project-wide guidance
│   └── specs/         # Feature specifications
├── docker-compose.yml
├── .env.example
├── LICENSE
└── README.md
```

---

## 🚦 Getting Started

### Prerequisites

- **Docker & Docker Compose** (recommended)
- **Python 3.11+** (for local backend development)
- **Flutter SDK 3.10+** (for mobile development)
- **PostgreSQL 15+** (if running without Docker)

### Quick Start with Docker

```bash
# 1. Clone the repository
git clone https://github.com/alyhaider096/RESQPET-AI.git
cd RESQPET-AI

# 2. Copy environment template
cp .env.example .env

# 3. Start services
docker compose up -d

# 4. Run migrations
docker compose exec backend alembic upgrade head

# 5. Seed demo data
docker compose exec backend python -m scripts.seed_data

# 6. Verify health
curl http://localhost:8000/health
```

### Backend Development (Local)

```bash
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
alembic upgrade head

# Start server
uvicorn app.main:app --reload

# In a second terminal, create the demo organization and users
python -m scripts.seed_data
```

### Mobile Development

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Build release APK
flutter build apk --release
```

---

## 🎯 Demo Workflow (P0 - Hackathon Scope)

1. **Citizen calls** the rescue hotline (Vapi voice assistant)
2. **Voice assistant collects** structured rescue information
3. **Backend creates** rescue case in PostgreSQL
4. **Triage system** assigns priority (Critical/Urgent/Routine)
5. **NGO dashboard** receives real-time case via WebSocket
6. **Coordinator assigns** rescue volunteer
7. **Volunteer accepts** and updates status through mobile app
8. **Status transitions** tracked with audit trail

---

## 🔐 Security

- ✅ No API keys in client applications
- ✅ Environment-based secret management
- ✅ Role-based access control (RBAC)
- ✅ Organization-scoped data isolation
- ✅ Short-lived JWT authentication
- ✅ Strict request validation and optimistic concurrency checks
- ✅ Audit logging for sensitive operations

Production refresh tokens and rate limiting are planned hardening work, not
part of the hackathon build.

All provider credentials are managed server-side through environment variables.

---

## 🧪 Testing

```bash
# Backend tests
cd backend
pytest tests/ -v --cov=app

# Mobile tests
cd mobile
flutter test
flutter analyze
```

The verified local baseline is documented in
[`HACKATHON_CONTRIBUTIONS.md`](HACKATHON_CONTRIBUTIONS.md).

### Demo accounts

Run `python -m scripts.seed_data` from `backend/` before signing in.

| Role | Email | Demo password |
|---|---|---|
| System admin | `admin@resqpet.ai` | value of `ADMIN_BOOTSTRAP_PASSWORD` |
| NGO coordinator | `coordinator@resqpet.demo` | `DemoCoordinator123!` |
| Rescue volunteer | `volunteer@resqpet.demo` | `DemoVolunteer123!` |
| Public reporter | `reporter@resqpet.demo` | `DemoReporter123!` |

Change every demo password and secret before any public deployment.

---

## 📊 Animals Supported

This is not just a "cute cats-and-dogs" app. We support:

- **Pets**: Dogs, cats
- **Livestock**: Cattle, buffaloes, goats, sheep, poultry
- **Working animals**: Horses, donkeys

---

## 🌍 Built for Pakistan

- 📍 **Manual location entry**: Village and district support
- 🐄 **Multi-species intake**: Pets, livestock, poultry, and working animals

Photos are resized/compressed by the Android picker before upload, with a 5 MB server limit.
Urdu interface localization, voice-note uploads, video uploads, and SMS
fallback are planned. They are not part of the implemented demo.

### Android demo

The ARM64 release-mode APK uses the development signing key. The hackathon demo
backend runs on a laptop through a free Cloudflare HTTPS tunnel; keep PostgreSQL,
FastAPI, and the tunnel running. A tunnel restart may change the hostname and
require updating Vapi and rebuilding the APK.

The Vapi dashboard conversation created a rescue case successfully. Incoming
PSTN calling remains unverified; the free US number cannot place international
outbound calls. Voice usage consumes provider credits separately from number allocation.

Backend validation: 23 tests passed, 85.96% coverage. Flutter analysis and two widget
tests passed, including coordinator verification/refresh regression coverage.

The app's top bar provides Rescue paw map and Vet and animal care buttons.
Reporters see organization rescue pins without reporter contact details.
Veterinarians manage appointments assigned to them. This records requests,
schedules, and follow-up notes; video calls, automatic diagnosis, prescriptions,
breeding-partner matching, and an in-app generative chatbot are not implemented.

---

## 🤝 Contributing

See [HACKATHON_CONTRIBUTIONS.md](HACKATHON_CONTRIBUTIONS.md) for details on what was built during the hackathon and how to contribute.

### Development Workflow

1. Check `.kiro/specs/` for feature specifications
2. Create feature branch from `main`
3. Write tests first
4. Implement feature
5. Ensure tests pass
6. Submit pull request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/alyhaider096/RESQPET-AI/issues)
- **Discussions**: [GitHub Discussions](https://github.com/alyhaider096/RESQPET-AI/discussions)

---

**Built with ❤️ for Pakistan's animals**
