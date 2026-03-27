"""Pydantic models for GymScan API request/response schemas."""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class EquipmentType(str, Enum):
    """All recognized gym equipment types."""

    DUMBBELL = "dumbbell"
    BARBELL = "barbell"
    CABLE_MACHINE = "cable_machine"
    SMITH_MACHINE = "smith_machine"
    BENCH_FLAT = "bench_flat"
    BENCH_INCLINE = "bench_incline"
    BENCH_ADJUSTABLE = "bench_adjustable"
    TREADMILL = "treadmill"
    ELLIPTICAL = "elliptical"
    ROWING_MACHINE = "rowing_machine"
    PULL_UP_BAR = "pull_up_bar"
    RESISTANCE_BANDS = "resistance_bands"
    KETTLEBELL = "kettlebell"
    LEG_PRESS = "leg_press"
    LAT_PULLDOWN = "lat_pulldown"
    PEC_DECK = "pec_deck"
    LEG_CURL = "leg_curl"
    LEG_EXTENSION = "leg_extension"
    SHOULDER_PRESS_MACHINE = "shoulder_press_machine"
    CHEST_PRESS_MACHINE = "chest_press_machine"
    SEATED_ROW = "seated_row"
    HACK_SQUAT = "hack_squat"
    PREACHER_CURL_BENCH = "preacher_curl_bench"
    AB_BENCH = "ab_bench"
    HYPEREXTENSION_BENCH = "hyperextension_bench"
    BATTLE_ROPES = "battle_ropes"
    TRX_SUSPENSION = "trx_suspension"
    MEDICINE_BALL = "medicine_ball"
    STABILITY_BALL = "stability_ball"
    FOAM_ROLLER = "foam_roller"
    YOGA_MAT = "yoga_mat"
    STAIR_CLIMBER = "stair_climber"
    STATIONARY_BIKE = "stationary_bike"
    SPIN_BIKE = "spin_bike"
    FUNCTIONAL_TRAINER = "functional_trainer"


class ConfidenceLevel(str, Enum):
    """Detection confidence levels."""

    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class MuscleGroup(str, Enum):
    """Target muscle groups for workout generation."""

    CHEST = "chest"
    BACK = "back"
    SHOULDERS = "shoulders"
    BICEPS = "biceps"
    TRICEPS = "triceps"
    LEGS = "legs"
    CORE = "core"
    FULL_BODY = "full_body"


# --- Scan Models ---


class ScanRequest(BaseModel):
    """Request body for POST /api/scan."""

    frames: list[str] = Field(
        ...,
        min_length=1,
        max_length=20,
        description="Base64-encoded images from gym video frames",
    )


class DetectedEquipment(BaseModel):
    """A single piece of detected equipment."""

    type: EquipmentType
    details: str = Field(default="", description="Weight range, quantity, adjustability")
    confidence: ConfidenceLevel


class ScanResponse(BaseModel):
    """Response body for POST /api/scan."""

    gym_id: str
    equipment: list[DetectedEquipment]


# --- Confirm Models ---


class EquipmentConfirmation(BaseModel):
    """A single equipment item with user confirmation status."""

    type: EquipmentType
    details: str = ""
    user_confirmed: bool = True


class ConfirmRequest(BaseModel):
    """Request body for POST /api/scan/{gym_id}/confirm."""

    equipment: list[EquipmentConfirmation]


class ConfirmResponse(BaseModel):
    """Response body for POST /api/scan/{gym_id}/confirm."""

    gym_id: str
    equipment_final: list[EquipmentConfirmation]


# --- Workout Generation Models ---


class WorkoutGenerateRequest(BaseModel):
    """Request body for POST /api/workout/generate."""

    gym_id: str
    target_muscles: list[MuscleGroup] = Field(..., min_length=1)
    duration_minutes: int = Field(..., ge=10, le=120)
    equipment: Optional[list[EquipmentConfirmation]] = Field(
        default=None,
        description="Optional inline equipment list. If provided, gym_id lookup is skipped.",
    )


class Exercise(BaseModel):
    """A single exercise in a workout."""

    name: str
    equipment_type: EquipmentType
    sets: int = Field(..., ge=1, le=10)
    reps: str = Field(..., description='Rep count or range, e.g. "10-12" or "to failure"')
    rest_seconds: int = Field(..., ge=0, le=300)
    notes: str = ""
    primary_muscles: list[str] = Field(default_factory=list, description="Target muscle groups for this exercise")
    order: int = Field(..., ge=1)


class WorkoutGenerateResponse(BaseModel):
    """Response body for POST /api/workout/generate."""

    workout_id: str
    exercises: list[Exercise]


# --- Workout Complete Models ---


class WorkoutCompleteRequest(BaseModel):
    """Request body for POST /api/workout/{workout_id}/complete."""

    completed_at: datetime
    exercises_completed: list[int] = Field(
        ..., description="Indices of completed exercises (0-based)"
    )


class WorkoutCompleteResponse(BaseModel):
    """Response body for POST /api/workout/{workout_id}/complete."""

    saved: bool


# --- Gym Retrieval Models ---


class GymResponse(BaseModel):
    """Response body for GET /api/gym/{gym_id}."""

    gym_id: str
    name: Optional[str] = None
    equipment: list[EquipmentConfirmation]
    created_at: datetime
    workouts: list[str] = Field(
        default_factory=list, description="List of workout IDs generated for this gym"
    )


# --- Workout Suggestion Models ---


class WorkoutSuggestion(BaseModel):
    """The suggested workout details."""

    target_muscles: list[str]
    reasoning: str
    exercise_count: int = Field(..., ge=1)
    estimated_minutes: int = Field(..., ge=1)


class SuggestResponse(BaseModel):
    """Response body for GET /api/workout/suggest."""

    suggestion: WorkoutSuggestion
    workout_id: Optional[str] = None


# --- Workout History Models ---


class MuscleCoverageEntry(BaseModel):
    """Coverage data for a single muscle group."""

    last_trained: Optional[str] = None
    days_ago: Optional[int] = None


class WorkoutHistoryEntry(BaseModel):
    """A single completed workout in the history."""

    workout_id: str
    target_muscles: list[str]
    completed_at: str
    exercise_count: int


class HistoryResponse(BaseModel):
    """Response body for GET /api/workout/history."""

    workouts: list[WorkoutHistoryEntry]
    muscle_coverage: dict[str, MuscleCoverageEntry]
    current_streak: int
