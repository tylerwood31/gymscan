"""Shared test fixtures."""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.storage import gym_store, workout_store


@pytest.fixture
def client():
    """FastAPI test client."""
    return TestClient(app)


@pytest.fixture(autouse=True)
def reset_storage():
    """Clear in-memory storage between tests."""
    gym_store._gyms.clear()
    workout_store._workouts.clear()
    yield
    gym_store._gyms.clear()
    workout_store._workouts.clear()


@pytest.fixture
def sample_equipment():
    """Sample equipment list as returned by the detector."""
    return [
        {"type": "dumbbell", "details": "5-50 lbs, pairs", "confidence": "high"},
        {"type": "bench_adjustable", "details": "1 adjustable bench", "confidence": "high"},
        {"type": "cable_machine", "details": "single stack", "confidence": "medium"},
        {"type": "treadmill", "details": "2 treadmills", "confidence": "high"},
        {"type": "yoga_mat", "details": "3 mats", "confidence": "low"},
    ]


@pytest.fixture
def sample_exercises():
    """Sample exercise list as returned by the workout generator."""
    return [
        {
            "name": "Dumbbell Bench Press",
            "equipment_type": "dumbbell",
            "sets": 4,
            "reps": "8-10",
            "rest_seconds": 90,
            "notes": "Control the negative for 2 seconds",
            "order": 1,
        },
        {
            "name": "Cable Flyes",
            "equipment_type": "cable_machine",
            "sets": 3,
            "reps": "12-15",
            "rest_seconds": 60,
            "notes": "Squeeze at the top, slight bend in elbows",
            "order": 2,
        },
        {
            "name": "Overhead Dumbbell Tricep Extension",
            "equipment_type": "dumbbell",
            "sets": 3,
            "reps": "10-12",
            "rest_seconds": 60,
            "notes": "Keep elbows tucked, full stretch at bottom",
            "order": 3,
        },
    ]


@pytest.fixture
def seeded_gym(sample_equipment):
    """Create a gym with confirmed equipment and return its ID."""
    import uuid

    gym_id = str(uuid.uuid4())
    gym_store.create_gym(gym_id)
    confirmed = [
        {**eq, "user_confirmed": True} for eq in sample_equipment
    ]
    gym_store.set_equipment(gym_id, confirmed, confirmed=True)
    return gym_id
