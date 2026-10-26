"""Pydantic request and response contracts."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

Species = Literal["dog", "cat", "cattle", "buffalo", "goat", "sheep", "poultry", "horse", "donkey", "other"]


class RescueCaseCreate(BaseModel):
    organization_id: str
    species: Species
    visible_condition: str = Field(min_length=3, max_length=500)
    consciousness: Literal["conscious", "unconscious", "unsure"]
    bleeding: Literal["none", "minor", "severe"]
    mobility: Literal["mobile", "limping", "immobile", "unsure"]
    breathing_difficulty: Literal["yes", "no", "unsure"]
    surrounding_danger: Literal["traffic", "fire", "water", "electrical", "violence", "none", "other"]
    district: str = Field(min_length=2, max_length=120)
    village: str | None = Field(default=None, max_length=120)
    landmark: str | None = Field(default=None, max_length=240)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    reporter_name: str | None = Field(default=None, max_length=160)
    reporter_phone: str | None = Field(default=None, max_length=30)
    vapi_call_id: str | None = Field(default=None, max_length=128)

    @field_validator("reporter_phone")
    @classmethod
    def validate_phone(cls, value: str | None) -> str | None:
        if value and not value.startswith("+"):
            raise ValueError("Phone number must use E.164 format, for example +923001234567")
        return value


class CaseEventRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    event_type: str
    old_value: str | None
    new_value: str | None
    reason: str | None
    created_at: datetime


class RescueCaseRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    case_reference: str
    organization_id: str
    species: str
    visible_condition: str
    consciousness: str
    bleeding: str
    mobility: str
    breathing_difficulty: str
    surrounding_danger: str
    district: str
    village: str | None
    landmark: str | None
    latitude: float | None
    longitude: float | None
    photo_count: int = 0
    priority: str
    priority_reasons: list[str]
    status: str
    assigned_volunteer_id: str | None
    version: int
    created_at: datetime
    updated_at: datetime
    events: list[CaseEventRead] = []


class CaseVerifyRequest(BaseModel):
    priority_override: Literal["critical", "urgent", "routine"] | None = None
    reason: str | None = Field(default=None, max_length=500)


class CaseAssignRequest(BaseModel):
    volunteer_id: str


class CaseStatusRequest(BaseModel):
    status: Literal["accepted", "en_route", "on_scene", "rescued", "closed", "duplicate", "false_report"]
    reason: str | None = Field(default=None, max_length=500)
    expected_version: int = Field(ge=1)


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    email: str
    full_name: str
    role: str
    organization_id: str | None
