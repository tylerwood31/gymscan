"""GymScan API -- FastAPI application entry point."""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import gym, scan, workout

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="GymScan API",
    description=(
        "Backend API for the GymScan iOS app. "
        "Scan hotel gyms, detect equipment via AI, and generate custom workouts."
    ),
    version="0.1.0",
)

# CORS -- allow all origins for development. Lock this down for production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(scan.router)
app.include_router(workout.router)
app.include_router(gym.router)


@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint for monitoring and deployment readiness."""
    return {"status": "healthy", "service": "gymscan-api", "version": "0.1.0"}
