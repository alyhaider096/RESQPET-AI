"""P0 authentication, rescue, Vapi tool, and WebSocket routes."""

import json
import secrets
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Header, HTTPException, Query, WebSocket, WebSocketDisconnect
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user, require_roles
from app.models import CaseAssignment, CaseEvent, CaseStatus, RescueCase, Role, User
from app.privacy import encrypt_optional, hash_phone
from app.realtime import manager
from app.schemas import (
    CaseAssignRequest,
    CaseStatusRequest,
    CaseVerifyRequest,
    LoginRequest,
    RescueCaseCreate,
    RescueCaseRead,
    TokenResponse,
    UserRead,
)
from app.security import create_access_token, decode_access_token, verify_password
from app.triage import classify_priority

router = APIRouter(prefix="/api/v1")

TRANSITIONS = {
    "reported": {"verified", "duplicate", "false_report"},
    "verified": {"assigned", "duplicate", "false_report"},
    "assigned": {"accepted"},
    "accepted": {"en_route"},
    "en_route": {"on_scene"},
    "on_scene": {"rescued"},
    "rescued": {"closed"},
}


def case_reference() -> str:
    return f"RQP-{datetime.now(UTC):%y%m%d}-{secrets.token_hex(3).upper()}"


def public_event(event_type: str, case: RescueCase) -> dict:
    return {
        "schema_version": 1,
        "type": event_type,
        "case": {
            "id": case.id,
            "case_reference": case.case_reference,
            "species": case.species,
            "district": case.district,
            "priority": case.priority,
            "status": case.status,
            "assigned_volunteer_id": case.assigned_volunteer_id,
            "version": case.version,
            "updated_at": case.updated_at.isoformat(),
        },
    }


def ensure_case_access(case: RescueCase, user: User) -> None:
    if user.role != Role.SYSTEM_ADMIN.value and case.organization_id != user.organization_id:
        raise HTTPException(status_code=403, detail="Case belongs to another organization")
    if user.role == Role.PUBLIC_REPORTER.value and case.reporter_user_id != user.id:
        raise HTTPException(status_code=403, detail="Case belongs to another reporter")


def create_case_record(
    db: Session, data: RescueCaseCreate, reporter_user_id: str | None = None
) -> tuple[RescueCase, bool]:
    if data.vapi_call_id:
        existing = db.scalar(select(RescueCase).where(RescueCase.vapi_call_id == data.vapi_call_id))
        if existing:
            return existing, False
    priority, reasons = classify_priority(data)
    case = RescueCase(
        case_reference=case_reference(),
        organization_id=data.organization_id,
        reporter_user_id=reporter_user_id,
        species=data.species,
        visible_condition=data.visible_condition,
        consciousness=data.consciousness,
        bleeding=data.bleeding,
        mobility=data.mobility,
        breathing_difficulty=data.breathing_difficulty,
        surrounding_danger=data.surrounding_danger,
        district=data.district,
        village=data.village,
        landmark=data.landmark,
        latitude=str(data.latitude) if data.latitude is not None else None,
        longitude=str(data.longitude) if data.longitude is not None else None,
        reporter_name_encrypted=encrypt_optional(data.reporter_name),
        reporter_phone_encrypted=encrypt_optional(data.reporter_phone),
        reporter_phone_hash=hash_phone(data.reporter_phone),
        priority=priority.value,
        priority_reasons=reasons,
        vapi_call_id=data.vapi_call_id,
    )
    db.add(case)
    db.flush()
    db.add(
        CaseEvent(
            case_id=case.id, actor_user_id=reporter_user_id, event_type="case.created", new_value=case.status
        )
    )
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if data.vapi_call_id:
            existing = db.scalar(select(RescueCase).where(RescueCase.vapi_call_id == data.vapi_call_id))
            if existing:
                return existing, False
        raise
    db.refresh(case)
    return case, True


def voice_result(case: RescueCase, created: bool) -> dict:
    return {
        "created": created,
        "case_id": case.id,
        "case_reference": case.case_reference,
        "priority": case.priority,
        "priority_reasons": case.priority_reasons,
        "status": case.status,
        "message": f"Rescue case {case.case_reference} has been recorded.",
    }


def verify_vapi_secret(authorization: str | None) -> None:
    expected = f"Bearer {settings.VAPI_TOOL_SECRET}"
    if not authorization or not secrets.compare_digest(authorization, expected):
        raise HTTPException(status_code=401, detail="Invalid Vapi tool credential")


@router.post("/auth/login", response_model=TokenResponse, tags=["auth"])
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == data.email.lower()))
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(user.id, user.role, user.organization_id)
    return TokenResponse(access_token=token, expires_in=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60)


@router.get("/auth/me", response_model=UserRead, tags=["auth"])
def me(user: User = Depends(get_current_user)):
    return user


@router.get("/users/volunteers", response_model=list[UserRead], tags=["users"])
def list_volunteers(
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(Role.NGO_COORDINATOR.value, Role.SYSTEM_ADMIN.value)),
):
    query = select(User).where(User.role == Role.RESCUE_VOLUNTEER.value, User.is_active.is_(True))
    if user.role != Role.SYSTEM_ADMIN.value:
        query = query.where(User.organization_id == user.organization_id)
    return list(db.scalars(query.order_by(User.full_name)))


@router.post("/cases", response_model=RescueCaseRead, status_code=201, tags=["rescue"])
async def create_case(
    data: RescueCaseCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    if user.role != Role.SYSTEM_ADMIN.value and data.organization_id != user.organization_id:
        raise HTTPException(status_code=403, detail="Cannot create case for another organization")
    case, created = create_case_record(db, data, user.id)
    if created:
        await manager.broadcast(case.organization_id, public_event("case.created", case))
    return case


@router.get("/cases", response_model=list[RescueCaseRead], tags=["rescue"])
def list_cases(
    case_status: str | None = Query(default=None, alias="status"),
    priority: str | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    query = select(RescueCase).order_by(RescueCase.created_at.desc()).limit(100)
    if user.role != Role.SYSTEM_ADMIN.value:
        query = query.where(RescueCase.organization_id == user.organization_id)
    if user.role == Role.PUBLIC_REPORTER.value:
        query = query.where(RescueCase.reporter_user_id == user.id)
    if case_status:
        query = query.where(RescueCase.status == case_status)
    if priority:
        query = query.where(RescueCase.priority == priority)
    return list(db.scalars(query).unique())


@router.get("/cases/{case_id}", response_model=RescueCaseRead, tags=["rescue"])
def get_case(case_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    case = db.get(RescueCase, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    ensure_case_access(case, user)
    return case


@router.post("/cases/{case_id}/verify", response_model=RescueCaseRead, tags=["rescue"])
async def verify_case(
    case_id: str,
    data: CaseVerifyRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(Role.NGO_COORDINATOR.value, Role.SYSTEM_ADMIN.value)),
):
    case = db.get(RescueCase, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    ensure_case_access(case, user)
    if case.status != CaseStatus.REPORTED.value:
        raise HTTPException(status_code=409, detail="Only reported cases can be verified")
    old_priority = case.priority
    if data.priority_override:
        if not data.reason:
            raise HTTPException(status_code=422, detail="Priority override requires a reason")
        case.priority = data.priority_override
    case.status = CaseStatus.VERIFIED.value
    case.version += 1
    db.add(
        CaseEvent(
            case_id=case.id,
            actor_user_id=user.id,
            event_type="case.verified",
            old_value=old_priority,
            new_value=case.priority,
            reason=data.reason,
        )
    )
    db.commit()
    db.refresh(case)
    await manager.broadcast(case.organization_id, public_event("case.updated", case))
    return case


@router.post("/cases/{case_id}/assign", response_model=RescueCaseRead, tags=["rescue"])
async def assign_case(
    case_id: str,
    data: CaseAssignRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(Role.NGO_COORDINATOR.value, Role.SYSTEM_ADMIN.value)),
):
    case = db.scalar(select(RescueCase).where(RescueCase.id == case_id).with_for_update())
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    ensure_case_access(case, user)
    if case.status != CaseStatus.VERIFIED.value or case.assigned_volunteer_id:
        raise HTTPException(status_code=409, detail="Case is not available for assignment")
    volunteer = db.get(User, data.volunteer_id)
    if (
        not volunteer
        or volunteer.role != Role.RESCUE_VOLUNTEER.value
        or volunteer.organization_id != case.organization_id
    ):
        raise HTTPException(status_code=422, detail="Volunteer is invalid for this organization")
    case.assigned_volunteer_id = volunteer.id
    case.status = CaseStatus.ASSIGNED.value
    case.version += 1
    db.add(CaseAssignment(case_id=case.id, volunteer_id=volunteer.id, assigned_by_user_id=user.id))
    db.add(
        CaseEvent(case_id=case.id, actor_user_id=user.id, event_type="case.assigned", new_value=volunteer.id)
    )
    db.commit()
    db.refresh(case)
    await manager.broadcast(case.organization_id, public_event("case.assigned", case))
    return case


@router.patch("/cases/{case_id}/status", response_model=RescueCaseRead, tags=["rescue"])
async def update_status(
    case_id: str,
    data: CaseStatusRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    case = db.scalar(select(RescueCase).where(RescueCase.id == case_id).with_for_update())
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    ensure_case_access(case, user)
    if user.role == Role.RESCUE_VOLUNTEER.value and case.assigned_volunteer_id != user.id:
        raise HTTPException(status_code=403, detail="Case is assigned to another volunteer")
    if user.role not in {Role.RESCUE_VOLUNTEER.value, Role.NGO_COORDINATOR.value, Role.SYSTEM_ADMIN.value}:
        raise HTTPException(status_code=403, detail="Role not permitted")
    if case.version != data.expected_version:
        raise HTTPException(status_code=409, detail="Case changed; refresh before updating")
    if data.status not in TRANSITIONS.get(case.status, set()):
        raise HTTPException(status_code=409, detail=f"Invalid transition from {case.status} to {data.status}")
    old = case.status
    case.status = data.status
    case.version += 1
    db.add(
        CaseEvent(
            case_id=case.id,
            actor_user_id=user.id,
            event_type="case.status_changed",
            old_value=old,
            new_value=data.status,
            reason=data.reason,
        )
    )
    db.commit()
    db.refresh(case)
    event_type = "case.resolved" if data.status in {"closed", "duplicate", "false_report"} else "case.updated"
    await manager.broadcast(case.organization_id, public_event(event_type, case))
    return case


@router.post("/voice/create-rescue-case", tags=["voice"])
async def voice_create_case(
    data: RescueCaseCreate, authorization: str | None = Header(default=None), db: Session = Depends(get_db)
):
    verify_vapi_secret(authorization)
    if not data.vapi_call_id:
        raise HTTPException(status_code=422, detail="vapi_call_id is required")
    case, created = create_case_record(db, data)
    if created:
        await manager.broadcast(case.organization_id, public_event("case.created", case))
    return voice_result(case, created)


@router.post("/voice/vapi-webhook", tags=["voice"])
async def vapi_webhook(
    payload: dict, authorization: str | None = Header(default=None), db: Session = Depends(get_db)
):
    """Handle Vapi's native `tool-calls` server-message envelope."""
    verify_vapi_secret(authorization)
    message = payload.get("message") or {}
    static_organization_id = payload.get("organization_id")
    if message.get("type") != "tool-calls":
        return {"received": True}

    call_id = (message.get("call") or {}).get("id")
    results = []
    for tool_call in message.get("toolCallList") or []:
        tool_call_id = str(tool_call.get("id", ""))
        function = tool_call.get("function") or {}
        name = function.get("name")
        if name != "create_rescue_case":
            results.append({"toolCallId": tool_call_id, "error": f"Unknown tool: {name}"})
            continue
        try:
            arguments = function.get("arguments") or {}
            if isinstance(arguments, str):
                arguments = json.loads(arguments)
            if static_organization_id:
                arguments["organization_id"] = static_organization_id
            arguments["vapi_call_id"] = call_id or arguments.get("vapi_call_id")
            data = RescueCaseCreate.model_validate(arguments)
            if not data.vapi_call_id:
                raise ValueError("Vapi call id is missing")
            case, created = create_case_record(db, data)
            if created:
                await manager.broadcast(case.organization_id, public_event("case.created", case))
            results.append(
                {
                    "toolCallId": tool_call_id,
                    "result": json.dumps(voice_result(case, created), separators=(",", ":")),
                }
            )
        except (ValidationError, ValueError, TypeError, json.JSONDecodeError) as exc:
            results.append({"toolCallId": tool_call_id, "error": str(exc).replace("\n", " ")})
    return {"results": results}


@router.websocket("/ws/cases")
async def cases_websocket(websocket: WebSocket, token: str = Query(...)):
    try:
        payload = decode_access_token(token)
        organization_id = payload.get("organization_id")
        if not organization_id:
            await websocket.close(code=4403)
            return
    except ValueError:
        await websocket.close(code=4401)
        return
    await manager.connect(organization_id, websocket)
    try:
        while True:
            if await websocket.receive_text() == "ping":
                await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        manager.disconnect(organization_id, websocket)
