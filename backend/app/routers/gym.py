"""Gym retrieval endpoint."""

import logging

from fastapi import APIRouter, HTTPException

from app.models import EquipmentConfirmation, GymResponse
from app.storage import gym_store

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/gym", tags=["gym"])


@router.get("/{gym_id}", response_model=GymResponse)
async def get_gym(gym_id: str) -> GymResponse:
    """Retrieve a previously scanned gym and its equipment list.

    Returns gym details including the confirmed equipment list and
    a list of workout IDs generated for this gym.
    """
    gym = gym_store.get_gym(gym_id)
    if gym is None:
        raise HTTPException(status_code=404, detail=f"Gym {gym_id} not found")

    equipment = [
        EquipmentConfirmation(
            type=eq["type"],
            details=eq.get("details", ""),
            user_confirmed=eq.get("user_confirmed", False),
        )
        for eq in gym.get("equipment", [])
    ]

    return GymResponse(
        gym_id=gym["gym_id"],
        name=gym.get("name"),
        equipment=equipment,
        created_at=gym["created_at"],
        workouts=gym.get("workouts", []),
    )
