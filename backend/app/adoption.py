"""Rescued-animal listings, citizen applications and NGO placement decisions."""

from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import DateTime, ForeignKey, String, Text, UniqueConstraint, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Mapped, Session, mapped_column

from app.database import Base, get_db
from app.dependencies import get_current_user
from app.models import Organization, RescueCase, Role, User
from app.models.entities import utcnow, uuid4_str

router = APIRouter(prefix="/api/v1/adoption", tags=["adoption"])
REVIEWERS = {Role.SYSTEM_ADMIN.value, Role.NGO_COORDINATOR.value}


class AdoptionListing(Base):
    __tablename__ = "adoption_listings"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    case_id: Mapped[str] = mapped_column(ForeignKey("rescue_cases.id"), unique=True)
    organization_id: Mapped[str] = mapped_column(ForeignKey("organizations.id"), index=True)
    created_by: Mapped[str] = mapped_column(ForeignKey("users.id"))
    animal_name: Mapped[str] = mapped_column(String(120))
    description: Mapped[str] = mapped_column(Text)
    species: Mapped[str] = mapped_column(String(40))
    district: Mapped[str] = mapped_column(String(120))
    case_reference: Mapped[str] = mapped_column(String(24))
    shelter_name: Mapped[str] = mapped_column(String(160))
    status: Mapped[str] = mapped_column(String(30), default="available")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AdoptionApplication(Base):
    __tablename__ = "adoption_applications"
    __table_args__ = (UniqueConstraint("listing_id", "applicant_id", name="uq_adoption_applicant"),)
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid4_str)
    listing_id: Mapped[str] = mapped_column(ForeignKey("adoption_listings.id"), index=True)
    applicant_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    message: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(30), default="pending")
    review_note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ListingCreate(BaseModel):
    case_id: str
    animal_name: str = Field(min_length=1, max_length=120)
    description: str = Field(min_length=10, max_length=2000)


class ListingRead(ListingCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str
    species: str
    district: str
    case_reference: str
    shelter_name: str
    status: str


class ApplicationCreate(BaseModel):
    message: str = Field(min_length=10, max_length=2000)


class ApplicationRead(ApplicationCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str
    listing_id: str
    applicant_id: str
    status: str
    review_note: str | None


class Decision(BaseModel):
    status: Literal["approved", "rejected"]
    review_note: str = Field(min_length=3, max_length=2000)


def get_listing(db: Session, listing_id: str, user: User, lock=False):
    query = select(AdoptionListing).where(AdoptionListing.id == listing_id)
    if lock:
        query = query.with_for_update()
    item = db.scalar(query)
    if not item or (user.role != Role.SYSTEM_ADMIN.value and item.organization_id != user.organization_id):
        raise HTTPException(404, "Adoption listing not found")
    return item


@router.get("/listings", response_model=list[ListingRead])
def listings(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    query = select(AdoptionListing)
    if user.role != Role.SYSTEM_ADMIN.value:
        query = query.where(AdoptionListing.organization_id == user.organization_id)
    return list(db.scalars(query.order_by(AdoptionListing.created_at.desc()).limit(100)))


@router.post("/listings", response_model=ListingRead, status_code=201)
def publish_listing(
    data: ListingCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    if user.role not in REVIEWERS | {Role.RESCUE_VOLUNTEER.value}:
        raise HTTPException(403, "Only the rescue team can publish an animal")
    case = db.get(RescueCase, data.case_id)
    if not case or (user.role != Role.SYSTEM_ADMIN.value and case.organization_id != user.organization_id):
        raise HTTPException(404, "Rescue case not found")
    if user.role == Role.RESCUE_VOLUNTEER.value and case.assigned_volunteer_id != user.id:
        raise HTTPException(403, "Only your assigned rescued animals can be listed")
    if case.status not in {"rescued", "closed"}:
        raise HTTPException(409, "Rescue the animal before publishing an adoption listing")
    org = db.get(Organization, case.organization_id)
    item = AdoptionListing(
        **data.model_dump(),
        organization_id=case.organization_id,
        created_by=user.id,
        species=case.species,
        district=case.district,
        case_reference=case.case_reference,
        shelter_name=org.name,
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "This animal already has an adoption listing") from None
    db.refresh(item)
    return item


@router.post("/listings/{listing_id}/applications", response_model=ApplicationRead, status_code=201)
def apply(
    listing_id: str,
    data: ApplicationCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role not in {Role.PUBLIC_REPORTER.value, Role.OWNER.value}:
        raise HTTPException(403, "Citizen and owner accounts can apply for adoption")
    listing = get_listing(db, listing_id, user, lock=True)
    if listing.status != "available":
        raise HTTPException(409, "This animal is no longer accepting applications")
    item = AdoptionApplication(listing_id=listing_id, applicant_id=user.id, message=data.message)
    db.add(item)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "You already applied for this animal") from None
    db.refresh(item)
    return item


@router.get("/applications", response_model=list[ApplicationRead])
def applications(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    query = select(AdoptionApplication).join(AdoptionListing)
    if user.role in REVIEWERS:
        if user.role != Role.SYSTEM_ADMIN.value:
            query = query.where(AdoptionListing.organization_id == user.organization_id)
    else:
        query = query.where(AdoptionApplication.applicant_id == user.id)
    return list(db.scalars(query.order_by(AdoptionApplication.created_at.desc()).limit(100)))


@router.patch("/applications/{application_id}", response_model=ApplicationRead)
def review(
    application_id: str, data: Decision, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    if user.role not in REVIEWERS:
        raise HTTPException(403, "Only an NGO coordinator or admin can review applications")
    item = db.get(AdoptionApplication, application_id)
    if not item:
        raise HTTPException(404, "Application not found")
    listing = get_listing(db, item.listing_id, user, lock=True)
    db.refresh(item)
    if item.status != "pending" or listing.status != "available":
        raise HTTPException(409, "Application or animal status has changed; refresh first")
    item.status, item.review_note = data.status, data.review_note
    if data.status == "approved":
        listing.status = "reserved"
        for other in db.scalars(
            select(AdoptionApplication).where(
                AdoptionApplication.listing_id == listing.id,
                AdoptionApplication.id != item.id,
                AdoptionApplication.status == "pending",
            )
        ):
            other.status, other.review_note = (
                "rejected",
                "Another application was selected by the rescue team.",
            )
    db.commit()
    db.refresh(item)
    return item


@router.post("/listings/{listing_id}/complete", response_model=ListingRead)
def complete(listing_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if user.role not in REVIEWERS:
        raise HTTPException(403, "Only the NGO coordinator or admin can confirm handover")
    listing = get_listing(db, listing_id, user, lock=True)
    if listing.status != "reserved":
        raise HTTPException(409, "Approve an application before confirming handover")
    listing.status = "adopted"
    db.commit()
    db.refresh(listing)
    return listing
