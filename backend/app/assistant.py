"""Authenticated, bounded demo chat; credentials and provider errors stay server-side."""

import asyncio
from typing import Literal

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.config import settings
from app.dependencies import get_current_user
from app.models import User

router = APIRouter(prefix="/api/v1/assistant", tags=["assistant"])
_lock = asyncio.Lock()
_requests = 0
INSTRUCTIONS = """You are ResQ, the ResQPet AI animal welfare guide in Pakistan.
Be kind, practical and concise. Reply in the user's language (English, Urdu or Roman Urdu).
Help with cats, dogs and livestock including cattle, buffalo, goats and poultry.
Explain app actions: report with photo and location, coordinator verifies and assigns,
volunteer progresses rescue, owner requests a vet consultation for health or heat-cycle concerns.
For routine care or vaccination: tap the medical-services icon (Vet and animal care) in
the Home app bar, tap Request care, select the veterinarian, animal species/name and concern
(Vaccination, General health, Heat cycle or Reproductive health), describe the concern and
submit the request. The assigned veterinarian then schedules the appointment; the owner
sees its status and date in this care screen. Do not send routine care requests through
Report and do not say they require a rescue coordinator or volunteer. Report is for rescue
emergencies. These navigation steps are authoritative; never invent alternative workflows.
You cannot create reports, book appointments, contact NGOs or read case records from chat;
direct the user to the relevant screen and never claim an action has happened.
For animal distress prioritize human safety and professional veterinary care.
Give general welfare guidance only; do not diagnose, prescribe medication/doses, or suggest
forced mating. For bleeding, collapse, breathing trouble or difficult birth recommend urgent
veterinary help. Never invent a phone number or a nearby clinic. Ask one useful follow-up
question if necessary. Do not request names, passwords, contact details or exact addresses.
"""


class Message(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=1500)


class ChatRequest(BaseModel):
    messages: list[Message] = Field(min_length=1, max_length=8)


class ChatResponse(BaseModel):
    reply: str


async def provider_reply(messages: list[Message]) -> str:
    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.post(
            "https://api.openai.com/v1/responses",
            headers={"Authorization": f"Bearer {settings.OPENAI_API_KEY}"},
            json={
                "model": settings.OPENAI_MODEL,
                "instructions": INSTRUCTIONS,
                "input": [message.model_dump() for message in messages],
                "max_output_tokens": 300,
                "store": False,
            },
        )
        response.raise_for_status()
        result = response.json()
        reply = "\n".join(
            part["text"]
            for item in result.get("output", [])
            if item.get("type") == "message"
            for part in item.get("content", [])
            if part.get("type") == "output_text" and part.get("text")
        )
        if not reply:
            raise ValueError("Empty assistant response")
        return reply


@router.post("/chat", response_model=ChatResponse)
async def chat(data: ChatRequest, user: User = Depends(get_current_user)):
    global _requests
    if not settings.OPENAI_API_KEY:
        raise HTTPException(503, "AI chat is not configured. You can still report or request vet care.")
    if data.messages[-1].role != "user":
        raise HTTPException(422, "The last message must be from the user.")
    async with _lock:
        if _requests >= settings.AI_DEMO_REQUEST_LIMIT:
            raise HTTPException(429, "The demo AI allowance has been reached. Please use vet care.")
        _requests += 1
    try:
        return ChatResponse(reply=await provider_reply(data.messages))
    except (httpx.HTTPError, ValueError, KeyError, TypeError):
        raise HTTPException(
            503, "AI chat is temporarily unavailable. You can still report or request vet care."
        ) from None
