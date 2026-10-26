"""Owner/farmer consultation requests and veterinarian appointment workflow."""

from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import DateTime, ForeignKey, String, Text, select
from sqlalchemy.orm import Mapped, Session, mapped_column

from app.database import Base, get_db
from app.dependencies import get_current_user
from app.models import Role, User
from app.models.entities import utcnow, uuid4_str
from app.schemas.contracts import Species

router = APIRouter(prefix="/api/v1/care", tags=["care"])


class Consultation(Base):
    __tablename__ = "consultations"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    organization_id: Mapped[str] = mapped_column(ForeignKey("organizations.id"), index=True)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    veterinarian_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    species: Mapped[str] = mapped_column(String(40))
    animal_name: Mapped[str] = mapped_column(String(120))
    concern: Mapped[str] = mapped_column(String(40))
    description: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(30), default="requested")
    appointment_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    vet_note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ConsultationCreate(BaseModel):
    veterinarian_id: str
    species: Species
    animal_name: str = Field(min_length=1, max_length=120)
    concern: Literal["general_health", "heat_cycle", "reproductive_health", "vaccination"]
    description: str = Field(min_length=5, max_length=2000)


class ConsultationRead(ConsultationCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str
    owner_id: str
    status: str
    appointment_at: datetime | None
    vet_note: str | None
    created_at: datetime


class ConsultationUpdate(BaseModel):
    status: Literal["scheduled", "completed"]
    appointment_at: datetime | None = None
    vet_note: str | None = Field(default=None, max_length=2000)


@router.get("/veterinarians")
def veterinarians(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return [
        {"id": vet.id, "full_name": vet.full_name}
        for vet in db.scalars(
            select(User).where(
                User.role == Role.VETERINARIAN.value,
                User.organization_id == user.organization_id,
                User.is_active.is_(True),
            )
        )
    ]


@router.post("/consultations", response_model=ConsultationRead, status_code=201)
def request_consultation(
    data: ConsultationCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    if user.role not in {Role.OWNER.value, Role.PUBLIC_REPORTER.value, Role.NGO_COORDINATOR.value}:
        raise HTTPException(403, "This role cannot request a consultation")
    vet = db.get(User, data.veterinarian_id)
    if (
        not vet
        or vet.role != Role.VETERINARIAN.value
        or not vet.is_active
        or vet.organization_id != user.organization_id
    ):
        raise HTTPException(422, "Choose an active veterinarian in your organization")
    item = Consultation(**data.model_dump(), owner_id=user.id, organization_id=user.organization_id)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/consultations", response_model=list[ConsultationRead])
def consultations(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    query = select(Consultation).where(Consultation.organization_id == user.organization_id)
    if user.role == Role.VETERINARIAN.value:
        query = query.where(Consultation.veterinarian_id == user.id)
    elif user.role not in {Role.NGO_COORDINATOR.value, Role.SYSTEM_ADMIN.value}:
        query = query.where(Consultation.owner_id == user.id)
    return list(db.scalars(query.order_by(Consultation.created_at.desc()).limit(100)))


@router.patch("/consultations/{consultation_id}", response_model=ConsultationRead)
def update_consultation(
    consultation_id: str,
    data: ConsultationUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    item = db.scalar(select(Consultation).where(Consultation.id == consultation_id).with_for_update())
    if not item:
        raise HTTPException(404, "Consultation not found")
    if (
        user.role != Role.VETERINARIAN.value
        or item.veterinarian_id != user.id
        or item.organization_id != user.organization_id
    ):
        raise HTTPException(403, "Only the assigned veterinarian can update this consultation")
    allowed = {"requested": "scheduled", "scheduled": "completed"}
    if allowed.get(item.status) != data.status:
        raise HTTPException(409, "Consultation status has changed; refresh first")
    if data.status == "scheduled":
        if not data.appointment_at or data.appointment_at.tzinfo is None or data.appointment_at <= utcnow():
            raise HTTPException(422, "Choose a future appointment with a timezone")
        item.appointment_at = data.appointment_at
    item.status = data.status
    item.vet_note = data.vet_note
    db.commit()
    db.refresh(item)
    return item
