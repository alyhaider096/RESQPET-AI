"""Transparent, deterministic rescue priority rules."""

from app.models import Priority
from app.schemas import RescueCaseCreate


def classify_priority(data: RescueCaseCreate) -> tuple[Priority, list[str]]:
    critical: list[str] = []
    urgent: list[str] = []
    if data.bleeding == "severe":
        critical.append("severe bleeding")
    if data.breathing_difficulty == "yes":
        critical.append("breathing difficulty")
    if data.consciousness == "unconscious":
        critical.append("animal reported unconscious")
    if data.surrounding_danger in {"traffic", "fire", "electrical", "violence"}:
        critical.append(f"active {data.surrounding_danger} danger")
    if critical:
        return Priority.CRITICAL, critical
    if data.mobility == "immobile":
        urgent.append("animal unable to move")
    if data.mobility == "limping":
        urgent.append("possible mobility injury")
    if data.bleeding == "minor":
        urgent.append("visible bleeding")
    if data.consciousness == "unsure" or data.breathing_difficulty == "unsure":
        urgent.append("critical condition could not be confirmed")
    if urgent:
        return Priority.URGENT, urgent
    return Priority.ROUTINE, ["no critical or urgent signal reported"]
