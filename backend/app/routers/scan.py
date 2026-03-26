"""Scan endpoints -- equipment detection from gym video frames."""

import logging
import uuid

from fastapi import APIRouter, HTTPException

from app.models import (
    ConfirmRequest,
    ConfirmResponse,
    DetectedEquipment,
    EquipmentConfirmation,
    EquipmentType,
    ScanRequest,
    ScanResponse,
)
from app.services.equipment_detector import detect_equipment
from app.storage import gym_store

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/scan", tags=["scan"])


@router.post("", response_model=ScanResponse)
async def scan_gym(request: ScanRequest) -> ScanResponse:
    """Analyze gym video frames and detect equipment.

    Accepts base64-encoded images, sends them to Claude Vision,
    and returns a structured equipment list.
    """
    gym_id = str(uuid.uuid4())
    gym_store.create_gym(gym_id)

    try:
        raw_equipment = detect_equipment(request.frames)
    except Exception as e:
        logger.error("Equipment detection failed: %s", e, exc_info=True)
        raise HTTPException(
            status_code=502,
            detail=f"Equipment detection service error: {str(e)}",
        )

    # Validate and normalize equipment items from the LLM response
    validated_equipment: list[DetectedEquipment] = []
    for item in raw_equipment:
        try:
            eq = DetectedEquipment(
                type=EquipmentType(item["type"]),
                details=item.get("details", ""),
                confidence=item.get("confidence", "medium"),
            )
            validated_equipment.append(eq)
        except (ValueError, KeyError) as e:
            logger.warning("Skipping invalid equipment item %s: %s", item, e)
            continue

    # Store raw equipment in the gym record
    gym_store.set_equipment(
        gym_id,
        [eq.model_dump() for eq in validated_equipment],
        confirmed=False,
    )

    logger.info("Scan complete for gym %s: %d items detected", gym_id, len(validated_equipment))
    return ScanResponse(gym_id=gym_id, equipment=validated_equipment)


@router.post("/{gym_id}/confirm", response_model=ConfirmResponse)
async def confirm_equipment(gym_id: str, request: ConfirmRequest) -> ConfirmResponse:
    """Confirm or edit the detected equipment list.

    Users can add missed items, remove false positives, and
    correct details from the AI detection.
    """
    gym = gym_store.get_gym(gym_id)
    if gym is None:
        raise HTTPException(status_code=404, detail=f"Gym {gym_id} not found")

    # Store the user-confirmed equipment list
    confirmed = [eq.model_dump() for eq in request.equipment]
    gym_store.set_equipment(gym_id, confirmed, confirmed=True)

    logger.info(
        "Equipment confirmed for gym %s: %d items",
        gym_id,
        len(request.equipment),
    )

    return ConfirmResponse(
        gym_id=gym_id,
        equipment_final=request.equipment,
    )
