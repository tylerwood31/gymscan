"""Mock data for demo/testing when Anthropic API key is not available."""

import logging

logger = logging.getLogger(__name__)

MOCK_EQUIPMENT = [
    {"type": "dumbbell", "details": "5-50 lbs, pairs", "confidence": "high"},
    {"type": "bench_adjustable", "details": "Adjustable flat/incline", "confidence": "high"},
    {"type": "cable_machine", "details": "Dual cable stack, 200 lbs per side", "confidence": "high"},
    {"type": "treadmill", "details": "2 units, Life Fitness", "confidence": "high"},
    {"type": "stationary_bike", "details": "1 upright bike", "confidence": "medium"},
    {"type": "rowing_machine", "details": "Concept2 Model D", "confidence": "medium"},
    {"type": "pull_up_bar", "details": "Wall-mounted", "confidence": "high"},
    {"type": "resistance_bands", "details": "Set of 5, various tensions", "confidence": "medium"},
    {"type": "kettlebell", "details": "15, 25, 35 lbs", "confidence": "high"},
    {"type": "yoga_mat", "details": "3 available", "confidence": "high"},
    {"type": "foam_roller", "details": "Standard length", "confidence": "medium"},
    {"type": "smith_machine", "details": "With safety stops", "confidence": "high"},
]


def mock_detect_equipment(frames: list[str]) -> list[dict]:
    """Return realistic mock equipment data for demo mode."""
    logger.info(
        "DEMO MODE: Returning mock equipment data (%d frames received, %d items returned)",
        len(frames),
        len(MOCK_EQUIPMENT),
    )
    return MOCK_EQUIPMENT


WORKOUT_TEMPLATES = {
    "chest": [
        {"name": "Dumbbell Bench Press", "equipment_type": "dumbbell", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": "Control the descent, press explosively.", "primary_muscles": ["chest", "triceps"]},
        {"name": "Incline Dumbbell Press", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 75, "notes": "Set bench to 30-45 degrees.", "primary_muscles": ["chest", "shoulders"]},
        {"name": "Cable Chest Fly", "equipment_type": "cable_machine", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Slight bend in elbows, squeeze at the top.", "primary_muscles": ["chest"]},
    ],
    "back": [
        {"name": "Cable Row", "equipment_type": "cable_machine", "sets": 4, "reps": "10-12", "rest_seconds": 75, "notes": "Pull to lower chest, squeeze shoulder blades.", "primary_muscles": ["back", "biceps"]},
        {"name": "Pull-ups", "equipment_type": "pull_up_bar", "sets": 3, "reps": "6-10", "rest_seconds": 90, "notes": "Full dead hang to chin over bar.", "primary_muscles": ["back", "biceps"]},
        {"name": "Dumbbell Row", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": "One arm at a time, drive elbow back.", "primary_muscles": ["back"]},
    ],
    "shoulders": [
        {"name": "Dumbbell Overhead Press", "equipment_type": "dumbbell", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": "Seated or standing. No arching back.", "primary_muscles": ["shoulders", "triceps"]},
        {"name": "Cable Lateral Raise", "equipment_type": "cable_machine", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Single arm, control the negative.", "primary_muscles": ["shoulders"]},
        {"name": "Dumbbell Front Raise", "equipment_type": "dumbbell", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Alternate arms, shoulder height max.", "primary_muscles": ["shoulders"]},
    ],
    "biceps": [
        {"name": "Dumbbell Curl", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": "Supinate wrist at the top. No swinging.", "primary_muscles": ["biceps"]},
        {"name": "Cable Curl", "equipment_type": "cable_machine", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Constant tension throughout ROM.", "primary_muscles": ["biceps"]},
    ],
    "triceps": [
        {"name": "Cable Tricep Pushdown", "equipment_type": "cable_machine", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Keep elbows pinned to sides.", "primary_muscles": ["triceps"]},
        {"name": "Overhead Dumbbell Tricep Extension", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": "Both hands, elbows close to head.", "primary_muscles": ["triceps"]},
    ],
    "legs": [
        {"name": "Smith Machine Squat", "equipment_type": "smith_machine", "sets": 4, "reps": "8-10", "rest_seconds": 120, "notes": "Feet slightly forward, parallel or below.", "primary_muscles": ["legs"]},
        {"name": "Dumbbell Romanian Deadlift", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 90, "notes": "Hinge at hips, feel hamstring stretch.", "primary_muscles": ["legs", "back"]},
        {"name": "Dumbbell Walking Lunges", "equipment_type": "dumbbell", "sets": 3, "reps": "12 per leg", "rest_seconds": 75, "notes": "Long stride, torso upright.", "primary_muscles": ["legs"]},
        {"name": "Kettlebell Goblet Squat", "equipment_type": "kettlebell", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Hold at chest, push knees out.", "primary_muscles": ["legs", "core"]},
    ],
    "core": [
        {"name": "Cable Woodchop", "equipment_type": "cable_machine", "sets": 3, "reps": "12 per side", "rest_seconds": 45, "notes": "Rotate through core, not arms.", "primary_muscles": ["core"]},
        {"name": "Dumbbell Side Bend", "equipment_type": "dumbbell", "sets": 3, "reps": "15 per side", "rest_seconds": 30, "notes": "One hand, bend to that side.", "primary_muscles": ["core"]},
    ],
    "full_body": [
        {"name": "Dumbbell Bench Press", "equipment_type": "dumbbell", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": "Compound push for chest and triceps.", "primary_muscles": ["chest", "triceps"]},
        {"name": "Cable Row", "equipment_type": "cable_machine", "sets": 4, "reps": "10-12", "rest_seconds": 75, "notes": "Compound pull for back and biceps.", "primary_muscles": ["back", "biceps"]},
        {"name": "Dumbbell Overhead Press", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 90, "notes": "Seated, full range of motion.", "primary_muscles": ["shoulders", "triceps"]},
        {"name": "Smith Machine Squat", "equipment_type": "smith_machine", "sets": 4, "reps": "8-10", "rest_seconds": 120, "notes": "Primary lower body compound.", "primary_muscles": ["legs"]},
        {"name": "Dumbbell Romanian Deadlift", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 90, "notes": "Hinge at hips, hamstring focus.", "primary_muscles": ["legs", "back"]},
        {"name": "Pull-ups", "equipment_type": "pull_up_bar", "sets": 3, "reps": "6-10", "rest_seconds": 90, "notes": "Full dead hang to chin over bar.", "primary_muscles": ["back", "biceps"]},
        {"name": "Cable Lateral Raise", "equipment_type": "cable_machine", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Single arm, control the negative.", "primary_muscles": ["shoulders"]},
        {"name": "Dumbbell Curl", "equipment_type": "dumbbell", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": "Supinate wrist at top, no swinging.", "primary_muscles": ["biceps"]},
        {"name": "Cable Tricep Pushdown", "equipment_type": "cable_machine", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Elbows pinned, full extension.", "primary_muscles": ["triceps"]},
        {"name": "Kettlebell Goblet Squat", "equipment_type": "kettlebell", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": "Hold at chest, knees out.", "primary_muscles": ["legs", "core"]},
        {"name": "Cable Woodchop", "equipment_type": "cable_machine", "sets": 3, "reps": "12 per side", "rest_seconds": 45, "notes": "Rotate through core, not arms.", "primary_muscles": ["core"]},
        {"name": "Dumbbell Walking Lunges", "equipment_type": "dumbbell", "sets": 3, "reps": "12 per leg", "rest_seconds": 75, "notes": "Long stride, torso upright.", "primary_muscles": ["legs"]},
    ],
}


def mock_generate_workout(
    equipment: list[dict],
    target_muscles: list[str],
    duration_minutes: int,
) -> list[dict]:
    """Return a realistic mock workout for demo mode."""
    exercises: list[dict] = []

    for muscle in target_muscles:
        template = WORKOUT_TEMPLATES.get(muscle, WORKOUT_TEMPLATES["full_body"])
        exercises.extend(template)

    # Calculate total time: each set = 45s work + rest_seconds
    # Trim or keep exercises to fill the requested duration
    working_seconds = (duration_minutes - 3) * 60  # subtract warmup
    selected: list[dict] = []
    total_seconds = 0
    for ex in exercises:
        ex_time = ex["sets"] * (45 + ex["rest_seconds"])
        if total_seconds + ex_time <= working_seconds or len(selected) < 3:
            selected.append(dict(ex))  # copy to avoid mutating template
            total_seconds += ex_time

    # Add order field
    for i, ex in enumerate(selected):
        ex["order"] = i + 1

    logger.info(
        "DEMO MODE: Generated mock workout with %d exercises (~%dm) for muscles=%s, duration=%dm",
        len(selected),
        (total_seconds // 60) + 3,
        target_muscles,
        duration_minutes,
    )
    return selected
