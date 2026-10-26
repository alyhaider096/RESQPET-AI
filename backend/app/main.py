"""
FastAPI Main Application

Application initialization, CORS, middleware, and routers for ResQPet AI.
"""

import logging
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.api import router as api_router
from app.assistant import router as assistant_router
from app.care import router as care_router
from app.config import settings
from app.database import get_db

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL), format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("Starting %s in %s mode", settings.APP_NAME, settings.APP_ENV)
    logger.info("API Base URL: %s", settings.API_BASE_URL)
    yield
    logger.info("Shutting down %s", settings.APP_NAME)


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version="0.1.0",
    description=(
        "ResQPet AI coordinates multi-species rescue reports across citizens, "
        "NGO coordinators, rescue volunteers, administrators, and Vapi voice intake."
    ),
    contact={"name": "ResQPet AI", "url": "https://github.com/alyhaider096/RESQPET-AI"},
    license_info={"name": "MIT", "identifier": "MIT"},
    openapi_tags=[
        {"name": "health", "description": "Deployment and uptime checks."},
        {"name": "auth", "description": "JWT login and current-user identity."},
        {"name": "users", "description": "Role-scoped rescue-team discovery."},
        {"name": "rescue", "description": "Report, verify, assign, and resolve rescue cases."},
        {"name": "voice", "description": "Bearer-authenticated Vapi tool endpoints."},
    ],
    servers=[{"url": settings.PUBLIC_API_URL or settings.API_BASE_URL}],
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
app.include_router(care_router)
app.include_router(assistant_router)


# Health Check Endpoint
@app.get("/health", tags=["health"])
async def health_check():
    """
    Health check endpoint for monitoring and load balancers.

    Returns:
        - status: "healthy" if application is running
        - environment: Current environment (development/staging/production)
        - version: Application version
    """
    return {
        "status": "healthy",
        "environment": settings.APP_ENV,
        "version": "0.1.0",
        "service": settings.APP_NAME,
    }


@app.get("/health/ready", tags=["health"], summary="Check API and database readiness")
def readiness_check(db: Session = Depends(get_db)):
    """Return healthy only after the configured database accepts a query."""
    db.execute(text("SELECT 1"))
    return {"status": "ready", "database": "reachable"}


# Root Endpoint
@app.get("/", tags=["root"])
async def root():
    """Root endpoint with API information."""
    return {
        "message": "ResQPet AI API",
        "version": "0.1.0",
        "docs": "/docs" if settings.DEBUG else "disabled",
        "health": "/health",
    }


# Exception Handlers
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unhandled errors."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An internal server error occurred" if not settings.DEBUG else str(exc),
                "timestamp": datetime.now(UTC).isoformat(),
            }
        },
    )


