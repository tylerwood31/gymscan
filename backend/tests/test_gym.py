"""Tests for gym retrieval endpoint."""

from unittest.mock import patch


class TestGetGym:
    """GET /api/gym/{gym_id} tests."""

    def test_get_gym_success(self, client, seeded_gym):
        """Retrieve a gym with confirmed equipment."""
        response = client.get(f"/api/gym/{seeded_gym}")

        assert response.status_code == 200
        data = response.json()
        assert data["gym_id"] == seeded_gym
        assert len(data["equipment"]) == 5
        assert data["equipment"][0]["type"] == "dumbbell"
        assert "created_at" in data
        assert isinstance(data["workouts"], list)

    def test_get_gym_not_found(self, client):
        """Requesting unknown gym returns 404."""
        response = client.get("/api/gym/nonexistent-id")
        assert response.status_code == 404

    def test_get_gym_includes_workout_ids(self, client, seeded_gym, sample_exercises):
        """Gym response includes workout IDs after generation."""
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

        response = client.get(f"/api/gym/{seeded_gym}")
        assert response.status_code == 200
        assert workout_id in response.json()["workouts"]


class TestHealthCheck:
    """GET /health tests."""

    def test_health(self, client):
        """Health endpoint returns healthy status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "gymscan-api"
