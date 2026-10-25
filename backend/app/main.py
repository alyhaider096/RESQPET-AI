"""
FastAPI Main Application

Application initialization, CORS, middleware, and routers.
Original work for AnimalCare PK Hackathon (October 2026)
FastAPI structure adapted from: ai-hospital-voice-receptionist
"""

import logging
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api import router as api_router
from app.config import settings

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
    description="AI-Assisted Animal Welfare Operating System for Pakistan",
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


# Root Endpoint
@app.get("/", tags=["root"])
async def root():
    """Root endpoint with API information."""
    return {
        "message": "AnimalCare PK API",
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


