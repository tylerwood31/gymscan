"""Workout generation service using Claude API."""

import json
import logging
from pathlib import Path

import anthropic

logger = logging.getLogger(__name__)

PROMPTS_DIR = Path(__file__).resolve().parent.parent.parent / "prompts"


def _load_prompt() -> str:
    """Load the workout generation prompt template from file."""
    prompt_path = PROMPTS_DIR / "workout_generation.txt"
    return prompt_path.read_text()


def _format_equipment_list(equipment: list[dict]) -> str:
    """Format equipment list into a readable string for the prompt."""
    lines = []
    for item in equipment:
        entry = f"- {item['type']}"
        if item.get("details"):
            entry += f" ({item['details']})"
        lines.append(entry)
    return "\n".join(lines) if lines else "- No specific equipment detected"


def generate_workout(
    equipment: list[dict],
    target_muscles: list[str],
    duration_minutes: int,
) -> list[dict]:
    """Generate a workout plan using Claude API.

    Args:
        equipment: List of equipment dicts from the gym scan.
        target_muscles: Target muscle groups (e.g., ["chest", "triceps"]).
        duration_minutes: How long the workout should take.

    Returns:
        List of exercise dicts with keys: name, equipment_type, sets, reps,
        rest_seconds, notes, order.

    Raises:
        anthropic.APIError: If the Claude API call fails.
        json.JSONDecodeError: If the model response is not valid JSON.
    """
    client = anthropic.Anthropic()

    prompt_template = _load_prompt()
    prompt = prompt_template.format(
        equipment_list=_format_equipment_list(equipment),
        target_muscles=", ".join(target_muscles),
        duration_minutes=duration_minutes,
    )

    logger.info(
        "Generating workout: muscles=%s, duration=%dm, equipment_count=%d",
        target_muscles,
        duration_minutes,
        len(equipment),
    )

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
    )

    raw_text = message.content[0].text.strip()
    logger.debug("Raw Claude response: %s", raw_text[:500])

    # Strip markdown code blocks if present
    if raw_text.startswith("```"):
        lines = raw_text.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        raw_text = "\n".join(lines).strip()

    result = json.loads(raw_text)

    # Handle both {"exercises": [...]} and bare [...] formats
    if isinstance(result, dict) and "exercises" in result:
        exercises = result["exercises"]
    elif isinstance(result, list):
        exercises = result
    else:
        raise ValueError(f"Unexpected workout response format: {type(result).__name__}")

    logger.info("Generated workout with %d exercises", len(exercises))
    return exercises
