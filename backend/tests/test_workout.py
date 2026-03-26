"""Tests for workout endpoints."""

from datetime import datetime, timezone
from unittest.mock import patch


class TestWorkoutGenerate:
    """POST /api/workout/generate tests."""

    def test_generate_success(self, client, seeded_gym, sample_exercises):
        """Generate workout for a gym with confirmed equipment."""
        with patch(
            "app.routers.workout.generate_workout",
            return_value=sample_exercises,
        ):
            response = client.post(
                "/api/workout/generate",
                json={
                    "gym_id": seeded_gym,
                    "target_muscles": ["chest", "triceps"],
                    "duration_minutes": 30,
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert "workout_id" in data
        assert len(data["exercises"]) == 3
        assert data["exercises"][0]["name"] == "Dumbbell Bench Press"
        assert data["exercises"][0]["equipment_type"] == "dumbbell"
        assert data["exercises"][0]["sets"] == 4

    def test_generate_nonexistent_gym(self, client):
        """Generating workout for unknown gym returns 404."""
        response = client.post(
            "/api/workout/generate",
            json={
                "gym_id": "nonexistent",
                "target_muscles": ["chest"],
                "duration_minutes": 30,
            },
        )
        assert response.status_code == 404

    def test_generate_no_equipment(self, client):
        """Generating workout for gym with no equipment returns 400."""
        from app.storage import gym_store

        gym_store.create_gym("empty-gym")

        response = client.post(
            "/api/workout/generate",
            json={
                "gym_id": "empty-gym",
                "target_muscles": ["chest"],
                "duration_minutes": 30,
            },
        )
        assert response.status_code == 400
        assert "No equipment found" in response.json()["detail"]

    def test_generate_invalid_duration(self, client, seeded_gym):
        """Duration outside 10-120 minutes returns 422."""
        response = client.post(
            "/api/workout/generate",
            json={
                "gym_id": seeded_gym,
                "target_muscles": ["chest"],
                "duration_minutes": 5,
            },
        )
        assert response.status_code == 422

    def test_generate_no_target_muscles(self, client, seeded_gym):
        """Empty target muscles returns 422."""
        response = client.post(
            "/api/workout/generate",
            json={
                "gym_id": seeded_gym,
                "target_muscles": [],
                "duration_minutes": 30,
            },
        )
        assert response.status_code == 422

    def test_generate_llm_error(self, client, seeded_gym):
        """LLM failure returns 502."""
        with patch(
            "app.routers.workout.generate_workout",
            side_effect=Exception("API rate limited"),
        ):
            response = client.post(
                "/api/workout/generate",
                json={
                    "gym_id": seeded_gym,
                    "target_muscles": ["chest"],
                    "duration_minutes": 30,
                },
            )
        assert response.status_code == 502

    def test_generate_filters_invalid_exercises(self, client, seeded_gym):
        """Invalid exercises from LLM are skipped, valid ones kept."""
        exercises_with_bad = [
            {
                "name": "Dumbbell Press",
                "equipment_type": "dumbbell",
                "sets": 3,
                "reps": "10",
                "rest_seconds": 60,
                "notes": "",
                "order": 1,
            },
            {
                "name": "Bad Exercise",
                "equipment_type": "antigravity_chamber",
                "sets": 3,
                "reps": "10",
                "rest_seconds": 60,
                "notes": "",
                "order": 2,
            },
        ]
        with patch(
            "app.routers.workout.generate_workout",
            return_value=exercises_with_bad,
        ):
            response = client.post(
                "/api/workout/generate",
                json={
                    "gym_id": seeded_gym,
                    "target_muscles": ["chest"],
                    "duration_minutes": 30,
                },
            )
        assert response.status_code == 200
        assert len(response.json()["exercises"]) == 1


class TestWorkoutComplete:
    """POST /api/workout/{workout_id}/complete tests."""

    def test_complete_success(self, client, seeded_gym, sample_exercises):
        """Complete a workout."""
        with patch(
            "app.routers.workout.generate_workout",
            return_value=sample_exercises,
        ):
            gen_resp = client.post(
                "/api/workout/generate",
                json={
                    "gym_id": seeded_gym,
                    "target_muscles": ["chest", "triceps"],
                    "duration_minutes": 30,
                },
            )
        workout_id = gen_resp.json()["workout_id"]

        response = client.post(
            f"/api/workout/{workout_id}/complete",
            json={
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "exercises_completed": [0, 1, 2],
            },
        )

        assert response.status_code == 200
        assert response.json()["saved"] is True

    def test_complete_nonexistent_workout(self, client):
        """Completing unknown workout returns 404."""
        response = client.post(
            "/api/workout/nonexistent/complete",
            json={
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "exercises_completed": [0],
            },
        )
        assert response.status_code == 404

    def test_complete_already_completed(self, client, seeded_gym, sample_exercises):
        """Completing an already-completed workout returns 400."""
        with patch(
            "app.routers.workout.generate_workout",
            return_value=sample_exercises,
        ):
            gen_resp = client.post(
                "/api/workout/generate",
                json={
                    "gym_id": seeded_gym,
                    "target_muscles": ["chest"],
                    "duration_minutes": 30,
                },
            )
        workout_id = gen_resp.json()["workout_id"]

        # Complete once
        client.post(
            f"/api/workout/{workout_id}/complete",
            json={
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "exercises_completed": [0, 1],
            },
        )

        # Try to complete again
        response = client.post(
            f"/api/workout/{workout_id}/complete",
            json={
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "exercises_completed": [0, 1, 2],
            },
        )
        assert response.status_code == 400
        assert "already completed" in response.json()["detail"]

    def test_complete_partial_exercises(self, client, seeded_gym, sample_exercises):
        """Completing only some exercises is valid."""
        with patch(
            "app.routers.workout.generate_workout",
            return_value=sample_exercises,
        ):
            gen_resp = client.post(
                "/api/workout/generate",
                json={
                    "gym_id": seeded_gym,
                    "target_muscles": ["chest"],
                    "duration_minutes": 30,
                },
            )
        workout_id = gen_resp.json()["workout_id"]

        response = client.post(
            f"/api/workout/{workout_id}/complete",
            json={
                "completed_at": datetime.now(timezone.utc).isoformat(),
                "exercises_completed": [0],  # Only first exercise
            },
        )
        assert response.status_code == 200
        assert response.json()["saved"] is True
