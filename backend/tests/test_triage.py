from app.models import Priority
from app.schemas import RescueCaseCreate
from app.triage import classify_priority


def payload(**overrides):
    data = dict(
        organization_id="org-1",
        species="dog",
        visible_condition="Animal needs assistance",
        consciousness="conscious",
        bleeding="none",
        mobility="mobile",
        breathing_difficulty="no",
        surrounding_danger="none",
        district="Islamabad",
    )
    data.update(overrides)
    return RescueCaseCreate(**data)


def test_severe_bleeding_is_critical():
    priority, reasons = classify_priority(payload(bleeding="severe"))
    assert priority is Priority.CRITICAL and "severe bleeding" in reasons


def test_immobile_is_urgent():
    priority, reasons = classify_priority(payload(mobility="immobile"))
    assert priority is Priority.URGENT and "animal unable to move" in reasons


def test_stable_report_is_routine():
    assert classify_priority(payload())[0] is Priority.ROUTINE
