"""Create deterministic synthetic demo identities."""

from sqlalchemy import select

from app.config import settings
from app.database import SessionLocal
from app.models import Organization, Role, User
from app.security import hash_password

DEMO_ORGANIZATION_ID = "00000000-0000-0000-0000-000000000001"


def seed() -> None:
    db = SessionLocal()
    try:
        org = db.scalar(select(Organization).where(Organization.name == "ResQ Demo NGO"))
        if not org:
            org = Organization(
                id=DEMO_ORGANIZATION_ID,
                name="ResQ Demo NGO",
                district="Islamabad",
            )
            db.add(org)
            db.flush()
        users = [
            ("vet@resqpet.demo", "Demo Veterinarian", Role.VETERINARIAN.value, settings.DEMO_VET_PASSWORD),
            ("owner@resqpet.demo", "Demo Pet Owner / Farmer", Role.OWNER.value, settings.DEMO_OWNER_PASSWORD),
            (
                settings.ADMIN_BOOTSTRAP_EMAIL,
                "System Admin",
                Role.SYSTEM_ADMIN.value,
                settings.ADMIN_BOOTSTRAP_PASSWORD,
            ),
            (
                "coordinator@resqpet.demo",
                "Demo Coordinator",
                Role.NGO_COORDINATOR.value,
                "DemoCoordinator123!",
            ),
            (
                "volunteer@resqpet.demo",
                "Demo Volunteer",
                Role.RESCUE_VOLUNTEER.value,
                "DemoVolunteer123!",
            ),
            (
                "reporter@resqpet.demo",
                "Demo Reporter",
                Role.PUBLIC_REPORTER.value,
                "DemoReporter123!",
            ),
        ]
        for email, name, role, password in users:
            if not password:
                continue
            if not db.scalar(select(User).where(User.email == email)):
                db.add(
                    User(
                        email=email,
                        full_name=name,
                        role=role,
                        organization_id=org.id,
                        password_hash=hash_password(password),
                    )
                )
        db.commit()
        print(f"Seeded organization {org.id} and demo users")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
