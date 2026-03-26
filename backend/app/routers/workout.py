"""Workout endpoints -- generation and completion tracking."""

import logging
import uuid

from fastapi import APIRouter, HTTPException

from app.models import (
    Exercise,
    EquipmentType,
    WorkoutCompleteRequest,
    WorkoutCompleteResponse,
    WorkoutGenerateRequest,
    WorkoutGenerateResponse,
)
from app.services.workout_generator import generate_workout
from app.storage import gym_store, workout_store

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/workout", tags=["workout"])


@router.post("/generate", response_model=WorkoutGenerateResponse)
async def generate_workout_endpoint(
    request: WorkoutGenerateRequest,
) -> WorkoutGenerateResponse:
    """Generate a workout plan based on available equipment and preferences.

    Uses the confirmed equipment list for the given gym along with the
    user's target muscles and time constraint to produce a structured workout.
    """
    gym = gym_store.get_gym(request.gym_id)
    if gym is None:
        raise HTTPException(status_code=404, detail=f"Gym {request.gym_id} not found")

    equipment = gym.get("equipment", [])
    if not equipment:
        raise HTTPException(
            status_code=400,
            detail="No equipment found for this gym. Scan and confirm equipment first.",
        )

    target_muscles = [m.value for m in request.target_muscles]

    try:
        raw_exercises = generate_workout(
            equipment=equipment,
            target_muscles=target_muscles,
            duration_minutes=request.duration_minutes,
        )
    except Exception as e:
        logger.error("Workout generation failed: %s", e, exc_info=True)
        raise HTTPException(
            status_code=502,
            detail=f"Workout generation service error: {str(e)}",
        )

    # Validate exercises from the LLM response
    validated_exercises: list[Exercise] = []
    for i, ex in enumerate(raw_exercises):
        try:
            exercise = Exercise(
                name=ex["name"],
                equipment_type=EquipmentType(ex["equipment_type"]),
                sets=ex["sets"],
                reps=str(ex["reps"]),
                rest_seconds=ex["rest_seconds"],
                notes=ex.get("notes", ""),
                order=ex.get("order", i + 1),
            )
            validated_exercises.append(exercise)
        except (ValueError, KeyError) as e:
            logger.warning("Skipping invalid exercise %s: %s", ex, e)
            continue

    if not validated_exercises:
        raise HTTPException(
            status_code=502,
            detail="Workout generation produced no valid exercises. Try again.",
        )

    workout_id = str(uuid.uuid4())
    workout_store.create_workout(
        workout_id=workout_id,
        gym_id=request.gym_id,
        target_muscles=target_muscles,
        duration_minutes=request.duration_minutes,
        exercises=[ex.model_dump() for ex in validated_exercises],
    )
    gym_store.add_workout(request.gym_id, workout_id)

    logger.info(
        "Generated workout %s for gym %s: %d exercises",
        workout_id,
        request.gym_id,
        len(validated_exercises),
    )

    return WorkoutGenerateResponse(
        workout_id=workout_id,
        exercises=validated_exercises,
    )


@router.post("/{workout_id}/complete", response_model=WorkoutCompleteResponse)
async def complete_workout(
    workout_id: str, request: WorkoutCompleteRequest
) -> WorkoutCompleteResponse:
    """Mark a workout as completed.

    Records which exercises were completed and the completion timestamp.
    """
    workout = workout_store.get_workout(workout_id)
    if workout is None:
        raise HTTPException(status_code=404, detail=f"Workout {workout_id} not found")

    if workout["completed"]:
        raise HTTPException(status_code=400, detail="Workout already completed")

    workout_store.complete_workout(
        workout_id=workout_id,
        completed_at=request.completed_at.isoformat(),
        exercises_completed=request.exercises_completed,
    )

    logger.info(
        "Workout %s completed: %d/%d exercises",
        workout_id,
        len(request.exercises_completed),
        len(workout["exercises"]),
    )

    return WorkoutCompleteResponse(saved=True)
