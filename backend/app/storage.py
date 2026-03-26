"""In-memory storage for MVP.

Simple dict-based storage. Replace with Supabase post-MVP.
"""

import logging
from datetime import datetime, timezone
from typing import Any

logger = logging.getLogger(__name__)


class GymStore:
    """In-memory gym data storage."""

    def __init__(self) -> None:
        self._gyms: dict[str, dict[str, Any]] = {}

    def create_gym(self, gym_id: str) -> dict[str, Any]:
        """Create a new gym entry."""
        gym = {
            "gym_id": gym_id,
            "name": None,
            "equipment": [],
            "equipment_confirmed": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "workouts": [],
        }
        self._gyms[gym_id] = gym
        logger.info("Created gym %s", gym_id)
        return gym

    def get_gym(self, gym_id: str) -> dict[str, Any] | None:
        """Retrieve a gym by ID."""
        return self._gyms.get(gym_id)

    def set_equipment(
        self, gym_id: str, equipment: list[dict[str, Any]], confirmed: bool = False
    ) -> None:
        """Set or update equipment list for a gym."""
        gym = self._gyms.get(gym_id)
        if gym is None:
            raise KeyError(f"Gym {gym_id} not found")
        gym["equipment"] = equipment
        gym["equipment_confirmed"] = confirmed
        logger.info(
            "Updated equipment for gym %s (%d items, confirmed=%s)",
            gym_id,
            len(equipment),
            confirmed,
        )

    def add_workout(self, gym_id: str, workout_id: str) -> None:
        """Track a workout ID under a gym."""
        gym = self._gyms.get(gym_id)
        if gym is None:
            raise KeyError(f"Gym {gym_id} not found")
        gym["workouts"].append(workout_id)


class WorkoutStore:
    """In-memory workout data storage."""

    def __init__(self) -> None:
        self._workouts: dict[str, dict[str, Any]] = {}

    def create_workout(
        self,
        workout_id: str,
        gym_id: str,
        target_muscles: list[str],
        duration_minutes: int,
        exercises: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """Store a generated workout."""
        workout = {
            "workout_id": workout_id,
            "gym_id": gym_id,
            "target_muscles": target_muscles,
            "duration_minutes": duration_minutes,
            "exercises": exercises,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "completed": False,
            "completed_at": None,
            "exercises_completed": [],
        }
        self._workouts[workout_id] = workout
        logger.info("Created workout %s for gym %s", workout_id, gym_id)
        return workout

    def get_workout(self, workout_id: str) -> dict[str, Any] | None:
        """Retrieve a workout by ID."""
        return self._workouts.get(workout_id)

    def complete_workout(
        self, workout_id: str, completed_at: str, exercises_completed: list[int]
    ) -> None:
        """Mark a workout as completed."""
        workout = self._workouts.get(workout_id)
        if workout is None:
            raise KeyError(f"Workout {workout_id} not found")
        workout["completed"] = True
        workout["completed_at"] = completed_at
        workout["exercises_completed"] = exercises_completed
        logger.info("Completed workout %s", workout_id)


# Singleton instances used across the application
gym_store = GymStore()
workout_store = WorkoutStore()
