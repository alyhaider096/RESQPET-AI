"""
Configuration Management

Load and validate environment variables.
ResQPet AI hackathon configuration (October 2026)
"""

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    APP_NAME: str = "ResQPet AI"
    APP_ENV: str = "development"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"

    # Server
    API_BASE_URL: str = "http://localhost:8000"
    WS_BASE_URL: str = "ws://localhost:8000"
    FRONTEND_URL: str = "http://localhost:3000"
    PUBLIC_API_URL: str | None = None  # For Vapi tunnel

    # Database
    DATABASE_URL: str = "sqlite:///./animalcare_dev.db"
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_TIMEOUT: int = 30

    # Security & Authentication
    APP_SECRET_KEY: str = "development-only-app-secret-change-before-demo"
    JWT_SECRET_KEY: str = "development-only-jwt-secret-change-before-demo"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    PII_ENCRYPTION_KEY: str = "development-only-pii-secret-change-before-demo"
    PHONE_HASH_SALT: str = "development-only-phone-salt-change-before-demo"

    # Vapi AI
    VAPI_API_KEY: str | None = None
    VAPI_PHONE_NUMBER_ID: str | None = None
    VAPI_ASSISTANT_ID: str | None = None
    VAPI_TOOL_SECRET: str = "development-only-vapi-secret-change-before-demo"

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_BURST: int = 10

    # File Upload Limits (in MB)
    MAX_IMAGE_SIZE_MB: int = 5
    MAX_VIDEO_SIZE_MB: int = 30
    MAX_AUDIO_SIZE_MB: int = 10

    # Admin Bootstrap
    ADMIN_BOOTSTRAP_EMAIL: str = "admin@resqpet.ai"
    ADMIN_BOOTSTRAP_PASSWORD: str = "ChangeMeBeforeDemo123!"

    # WebSocket
    WS_HEARTBEAT_INTERVAL: int = 30
    WS_CONNECTION_TIMEOUT: int = 300

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:8000"]

    # Feature Flags
    ENABLE_VETERINARY_CONSULTATIONS: bool = False
    ENABLE_ADOPTION_SYSTEM: bool = False
    ENABLE_REPRODUCTIVE_HEALTH: bool = False
    ENABLE_ML_TRIAGE_MODEL: bool = False

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
        """Parse comma-separated CORS origins into list."""
        if isinstance(v, list):
            return v
        return [origin.strip() for origin in v.split(",") if origin.strip()]

    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        case_sensitive=True,
        extra="ignore",
    )


# Global settings instance
settings = Settings()


def validate_required_secrets():
    """Validate that critical secrets are not using default values."""
    if settings.APP_ENV == "production":
        if len(settings.JWT_SECRET_KEY) < 32:
            raise ValueError("JWT_SECRET_KEY must be at least 32 characters")

        if len(settings.PII_ENCRYPTION_KEY) < 32:
            raise ValueError("PII_ENCRYPTION_KEY must be at least 32 characters")

        if len(settings.PHONE_HASH_SALT) < 32:
            raise ValueError("PHONE_HASH_SALT must be at least 32 characters")

        if settings.VAPI_TOOL_SECRET.startswith("development-only"):
            raise ValueError("VAPI_TOOL_SECRET must be changed in production")


# Validate on import
if settings.APP_ENV != "test":
    validate_required_secrets()
