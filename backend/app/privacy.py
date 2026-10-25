"""PII protection helpers for the prototype."""

import base64
import hashlib
import hmac

from cryptography.fernet import Fernet

from app.config import settings


def _fernet() -> Fernet:
    key = base64.urlsafe_b64encode(hashlib.sha256(settings.PII_ENCRYPTION_KEY.encode()).digest())
    return Fernet(key)


def encrypt_optional(value: str | None) -> str | None:
    return _fernet().encrypt(value.encode()).decode() if value else None


def hash_phone(value: str | None) -> str | None:
    if not value:
        return None
    return hmac.new(settings.PHONE_HASH_SALT.encode(), value.encode(), hashlib.sha256).hexdigest()
