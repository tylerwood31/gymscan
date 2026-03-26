"""Tests for scan endpoints."""

import base64
from unittest.mock import patch

import pytest


# Tiny valid JPEG (1x1 pixel) for testing base64 handling
TINY_JPEG_B64 = base64.b64encode(
    bytes.fromhex(
        "ffd8ffe000104a46494600010100000100010000"
        "ffdb004300080606070605080707070909080a0c"
        "140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c"
        "20242e2720222c231c1c2837292c30313434341f"
        "27393d38323c2e333432ffc0000b080001000101"
        "011100ffc4001f000001050101010101010000000"
        "0000000000102030405060708090a0bffc400b510"
        "000201030302040305050404000001770001020311"
        "0004210531ffd9"
    )
).decode()


class TestScanEndpoint:
    """POST /api/scan tests."""

    def test_scan_success(self, client, sample_equipment):
        """Scan with valid frames returns equipment list."""
        with patch(
            "app.routers.scan.detect_equipment",
            return_value=sample_equipment,
        ):
            response = client.post(
                "/api/scan",
                json={"frames": [TINY_JPEG_B64]},
            )

        assert response.status_code == 200
        data = response.json()
        assert "gym_id" in data
        assert len(data["equipment"]) == len(sample_equipment)
        assert data["equipment"][0]["type"] == "dumbbell"
        assert data["equipment"][0]["confidence"] == "high"

    def test_scan_no_frames(self, client):
        """Scan with empty frames list returns 422."""
        response = client.post("/api/scan", json={"frames": []})
        assert response.status_code == 422

    def test_scan_filters_invalid_equipment(self, client):
        """Invalid equipment types from LLM are silently skipped."""
        mixed_equipment = [
            {"type": "dumbbell", "details": "10-50 lbs", "confidence": "high"},
            {"type": "magic_flying_carpet", "details": "", "confidence": "low"},
            {"type": "treadmill", "details": "1 treadmill", "confidence": "high"},
        ]
        with patch(
            "app.routers.scan.detect_equipment",
            return_value=mixed_equipment,
        ):
            response = client.post(
                "/api/scan",
                json={"frames": [TINY_JPEG_B64]},
            )

        assert response.status_code == 200
        data = response.json()
        # "magic_flying_carpet" should be filtered out
        assert len(data["equipment"]) == 2
        types = [eq["type"] for eq in data["equipment"]]
        assert "magic_flying_carpet" not in types

    def test_scan_llm_error(self, client):
        """LLM failure returns 502."""
        with patch(
            "app.routers.scan.detect_equipment",
            side_effect=Exception("API timeout"),
        ):
            response = client.post(
                "/api/scan",
                json={"frames": [TINY_JPEG_B64]},
            )

        assert response.status_code == 502
        assert "Equipment detection service error" in response.json()["detail"]


class TestConfirmEndpoint:
    """POST /api/scan/{gym_id}/confirm tests."""

    def test_confirm_success(self, client, sample_equipment):
        """Confirm equipment on a scanned gym."""
        # First, create a gym via scan
        with patch(
            "app.routers.scan.detect_equipment",
            return_value=sample_equipment,
        ):
            scan_resp = client.post(
                "/api/scan",
                json={"frames": [TINY_JPEG_B64]},
            )
        gym_id = scan_resp.json()["gym_id"]

        # Then confirm equipment
        confirmed = [
            {"type": "dumbbell", "details": "5-50 lbs", "user_confirmed": True},
            {"type": "bench_adjustable", "details": "1 bench", "user_confirmed": True},
            {"type": "cable_machine", "details": "single stack", "user_confirmed": False},
        ]
        response = client.post(
            f"/api/scan/{gym_id}/confirm",
            json={"equipment": confirmed},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["gym_id"] == gym_id
        assert len(data["equipment_final"]) == 3

    def test_confirm_nonexistent_gym(self, client):
        """Confirming equipment for unknown gym returns 404."""
        response = client.post(
            "/api/scan/nonexistent-id/confirm",
            json={"equipment": [{"type": "dumbbell", "details": "", "user_confirmed": True}]},
        )
        assert response.status_code == 404

    def test_confirm_add_missed_equipment(self, client, sample_equipment):
        """User can add equipment the AI missed."""
        with patch(
            "app.routers.scan.detect_equipment",
            return_value=sample_equipment,
        ):
            scan_resp = client.post(
                "/api/scan",
                json={"frames": [TINY_JPEG_B64]},
            )
        gym_id = scan_resp.json()["gym_id"]

        # Add pull_up_bar that AI missed, remove yoga_mat false positive
        confirmed = [
            {"type": "dumbbell", "details": "5-50 lbs", "user_confirmed": True},
            {"type": "bench_adjustable", "details": "1 bench", "user_confirmed": True},
            {"type": "cable_machine", "details": "single stack", "user_confirmed": True},
            {"type": "treadmill", "details": "2 treadmills", "user_confirmed": True},
            {"type": "pull_up_bar", "details": "wall mounted", "user_confirmed": True},
        ]
        response = client.post(
            f"/api/scan/{gym_id}/confirm",
            json={"equipment": confirmed},
        )

        assert response.status_code == 200
        types = [eq["type"] for eq in response.json()["equipment_final"]]
        assert "pull_up_bar" in types
        assert "yoga_mat" not in types
