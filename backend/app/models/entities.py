"""Core P0 relational models for rescue operations."""

import enum
import uuid
from datetime import UTC, datetime

from sqlalchemy import JSON, DateTime, ForeignKey, Index, LargeBinary, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def uuid4_str() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(UTC)


class Role(str, enum.Enum):
    PUBLIC_REPORTER = "public_reporter"
    OWNER = "owner"
    NGO_COORDINATOR = "ngo_coordinator"
    RESCUE_VOLUNTEER = "rescue_volunteer"
    VETERINARIAN = "veterinarian"
    SYSTEM_ADMIN = "system_admin"


class CaseStatus(str, enum.Enum):
    REPORTED = "reported"
    VERIFIED = "verified"
    ASSIGNED = "assigned"
    ACCEPTED = "accepted"
    EN_ROUTE = "en_route"
    ON_SCENE = "on_scene"
    RESCUED = "rescued"
    CLOSED = "closed"
    DUPLICATE = "duplicate"
    FALSE_REPORT = "false_report"


class Priority(str, enum.Enum):
    CRITICAL = "critical"
    URGENT = "urgent"
    ROUTINE = "routine"


class Organization(Base):
    __tablename__ = "organizations"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    name: Mapped[str] = mapped_column(String(160), unique=True, nullable=False)
    district: Mapped[str | None] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class User(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(160), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(40), nullable=False)
    organization_id: Mapped[str | None] = mapped_column(ForeignKey("organizations.id"), index=True)
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class RescueCase(Base):
    __tablename__ = "rescue_cases"
    __table_args__ = (
        UniqueConstraint("vapi_call_id", name="uq_rescue_cases_vapi_call_id"),
        Index("ix_rescue_cases_org_status", "organization_id", "status"),
        Index("ix_rescue_cases_priority_created", "priority", "created_at"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    case_reference: Mapped[str] = mapped_column(String(24), unique=True, index=True, nullable=False)
    organization_id: Mapped[str] = mapped_column(ForeignKey("organizations.id"), index=True, nullable=False)
    reporter_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    species: Mapped[str] = mapped_column(String(40), nullable=False)
    visible_condition: Mapped[str] = mapped_column(Text, nullable=False)
    consciousness: Mapped[str] = mapped_column(String(20), nullable=False)
    bleeding: Mapped[str] = mapped_column(String(20), nullable=False)
    mobility: Mapped[str] = mapped_column(String(20), nullable=False)
    breathing_difficulty: Mapped[str] = mapped_column(String(20), nullable=False)
    surrounding_danger: Mapped[str] = mapped_column(String(30), nullable=False)
    district: Mapped[str] = mapped_column(String(120), nullable=False)
    village: Mapped[str | None] = mapped_column(String(120))
    landmark: Mapped[str | None] = mapped_column(String(240))
    latitude: Mapped[str | None] = mapped_column(String(32))
    longitude: Mapped[str | None] = mapped_column(String(32))
    reporter_name_encrypted: Mapped[str | None] = mapped_column(Text)
    reporter_phone_encrypted: Mapped[str | None] = mapped_column(Text)
    reporter_phone_hash: Mapped[str | None] = mapped_column(String(64), index=True)
    priority: Mapped[str] = mapped_column(String(20), nullable=False)
    priority_reasons: Mapped[list] = mapped_column(JSON, default=list)
    status: Mapped[str] = mapped_column(String(30), default=CaseStatus.REPORTED.value, index=True)
    assigned_volunteer_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), index=True)
    vapi_call_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    version: Mapped[int] = mapped_column(default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)
    events: Mapped[list["CaseEvent"]] = relationship(
        back_populates="case", cascade="all, delete-orphan", order_by="CaseEvent.created_at"
    )
    photos: Mapped[list["CasePhoto"]] = relationship(cascade="all, delete-orphan")

    @property
    def photo_count(self) -> int:
        return len(self.photos)


class CasePhoto(Base):
    __tablename__ = "case_photos"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    case_id: Mapped[str] = mapped_column(ForeignKey("rescue_cases.id", ondelete="CASCADE"), unique=True)
    content_type: Mapped[str] = mapped_column(String(40))
    data: Mapped[bytes] = mapped_column(LargeBinary, deferred=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class CaseEvent(Base):
    __tablename__ = "case_events"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    case_id: Mapped[str] = mapped_column(ForeignKey("rescue_cases.id", ondelete="CASCADE"), index=True)
    actor_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    event_type: Mapped[str] = mapped_column(String(60), nullable=False)
    old_value: Mapped[str | None] = mapped_column(String(120))
    new_value: Mapped[str | None] = mapped_column(String(120))
    reason: Mapped[str | None] = mapped_column(Text)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    case: Mapped[RescueCase] = relationship(back_populates="events")


class CaseAssignment(Base):
    __tablename__ = "case_assignments"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    case_id: Mapped[str] = mapped_column(ForeignKey("rescue_cases.id", ondelete="CASCADE"), index=True)
    volunteer_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    assigned_by_user_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    active: Mapped[bool] = mapped_column(default=True, index=True)
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
