"""Equipment detection service using Claude Vision API."""

import json
import logging
from pathlib import Path

import anthropic

logger = logging.getLogger(__name__)

PROMPTS_DIR = Path(__file__).resolve().parent.parent.parent / "prompts"


def _load_prompt() -> str:
    """Load the equipment detection prompt from file."""
    prompt_path = PROMPTS_DIR / "equipment_detection.txt"
    return prompt_path.read_text()


def _build_image_content(frames: list[str]) -> list[dict]:
    """Build Claude API content blocks from base64 frames.

    Each frame becomes an image content block. We send all frames in a single
    message so the model can cross-reference equipment across angles.
    """
    content: list[dict] = []
    for i, frame_b64 in enumerate(frames):
        # Strip data URI prefix if present (e.g., "data:image/jpeg;base64,...")
        if "," in frame_b64 and frame_b64.index(",") < 100:
            frame_b64 = frame_b64.split(",", 1)[1]

        content.append(
            {
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": frame_b64,
                },
            }
        )
        logger.debug("Added frame %d (%d chars base64)", i, len(frame_b64))

    content.append({"type": "text", "text": _load_prompt()})
    return content


def detect_equipment(frames: list[str]) -> list[dict]:
    """Send gym frames to Claude Vision and return detected equipment.

    Args:
        frames: List of base64-encoded JPEG images.

    Returns:
        List of equipment dicts with keys: type, details, confidence.

    Raises:
        anthropic.APIError: If the Claude API call fails.
        json.JSONDecodeError: If the model response is not valid JSON.
    """
    client = anthropic.Anthropic()

    content = _build_image_content(frames)

    logger.info("Sending %d frames to Claude Vision for equipment detection", len(frames))

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[
            {
                "role": "user",
                "content": content,
            }
        ],
    )

    raw_text = message.content[0].text.strip()
    logger.debug("Raw Claude response: %s", raw_text[:500])

    # The model may wrap JSON in markdown code blocks -- strip them
    if raw_text.startswith("```"):
        lines = raw_text.split("\n")
        # Remove first line (```json or ```) and last line (```)
        lines = [l for l in lines if not l.strip().startswith("```")]
        raw_text = "\n".join(lines).strip()

    equipment = json.loads(raw_text)

    if not isinstance(equipment, list):
        raise ValueError(f"Expected JSON array from model, got {type(equipment).__name__}")

    logger.info("Detected %d pieces of equipment", len(equipment))
    return equipment
