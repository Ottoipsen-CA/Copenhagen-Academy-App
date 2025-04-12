import pytest
from fastapi.testclient import TestClient
from datetime import datetime, date, time
import logging

from main import app
from database import Base, engine
from models import User, TrainingSchedule, TrainingSession

# Setup test client
client = TestClient(app)

# Test data
test_user = {
    "email": "training_test@example.com",
    "password": "password123",
    "full_name": "Training Test User"
}

test_schedule = {
    "week_number": 34,
    "year": 2023,
    "title": "Test Training Week",
    "notes": "This is a test schedule",
    "user_id": 1
}

test_session = {
    "day_of_week": 1,
    "session_date": "2023-08-21",
    "title": "Test Training Session",
    "description": "This is a test training session",
    "start_time": "16:00:00",
    "end_time": "17:30:00",
    "location": "Test Field",
    "schedule_id": 1
}

test_reflection = {
    "reflection_text": "This training went really well. Players showed great progress."
}


class TestTrainingSchedulesEndpoints:
    @classmethod
    def setup_class(cls):
        # Create tables if they don't exist
        Base.metadata.create_all(bind=engine)

    def setup_method(self):
        # Try to register the test user 
        client.post("/api/v2/auth/register", json=test_user)
        
        # Login to get token
        login_data = {
            "username": test_user["email"],
            "password": test_user["password"]
        }
        response = client.post("/api/v2/auth/token", data=login_data)
        if response.status_code != 200:
            pytest.skip("Authentication failed - cannot continue tests")
            
        self.token = response.json().get("access_token")
        if not self.token:
            pytest.skip("No access token received - cannot continue tests")
            
        self.headers = {"Authorization": f"Bearer {self.token}"}

    def test_training_schedules_endpoints_exist(self):
        """Test that the training schedules endpoints exist"""
        response = client.get("/api/v2/training-schedules", headers=self.headers)
        assert response.status_code in [200, 307]

        response = client.get("/api/v2/training-schedules/", headers=self.headers)
        assert response.status_code == 200

        # Test sessions endpoint exists
        response = client.options("/api/v2/training-schedules/sessions/1")
        assert response.status_code == 405  # Method not allowed, but endpoint exists

    def test_training_schedules_operations(self):
        """Test CRUD operations for training schedules"""
        # 1. Create a schedule
        response = client.post(
            "/api/v2/training-schedules/", 
            json=test_schedule,
            headers=self.headers
        )
        assert response.status_code == 201
        schedule_id = response.json()["id"]
        
        # 2. Get the schedule
        response = client.get(
            f"/api/v2/training-schedules/{schedule_id}", 
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["title"] == test_schedule["title"]
        
        # 3. Update the schedule
        updated_schedule = {
            "week_number": 34,
            "year": 2023,
            "title": "Updated Test Schedule",
            "notes": "This schedule has been updated"
        }
        response = client.put(
            f"/api/v2/training-schedules/{schedule_id}", 
            json=updated_schedule,
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["title"] == "Updated Test Schedule"
        
        # 4. Create a training session
        test_session["schedule_id"] = schedule_id
        response = client.post(
            "/api/v2/training-schedules/sessions", 
            json=test_session,
            headers=self.headers
        )
        assert response.status_code == 201
        session_id = response.json()["id"]
        
        # 5. Get the session
        response = client.get(
            f"/api/v2/training-schedules/sessions/{session_id}", 
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["title"] == test_session["title"]
        
        # 6. Add a reflection to the session
        response = client.post(
            f"/api/v2/training-schedules/sessions/{session_id}/reflection", 
            json=test_reflection,
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["has_reflection"] == True
        assert response.json()["reflection_text"] == test_reflection["reflection_text"]
        
        # 7. Get all sessions for a schedule
        response = client.get(
            f"/api/v2/training-schedules/{schedule_id}/sessions", 
            headers=self.headers
        )
        assert response.status_code == 200
        assert len(response.json()) == 1
        
        # 8. Delete the session
        response = client.delete(
            f"/api/v2/training-schedules/sessions/{session_id}", 
            headers=self.headers
        )
        assert response.status_code == 204
        
        # 9. Check session was deleted
        response = client.get(
            f"/api/v2/training-schedules/sessions/{session_id}", 
            headers=self.headers
        )
        assert response.status_code == 404
        
        # 10. Delete the schedule
        response = client.delete(
            f"/api/v2/training-schedules/{schedule_id}", 
            headers=self.headers
        )
        assert response.status_code == 204
        
        # 11. Check schedule was deleted
        response = client.get(
            f"/api/v2/training-schedules/{schedule_id}", 
            headers=self.headers
        )
        assert response.status_code == 404

    def test_week_specific_endpoints(self):
        """Test endpoints specific to week numbers"""
        # 1. Create a schedule
        response = client.post(
            "/api/v2/training-schedules/", 
            json=test_schedule,
            headers=self.headers
        )
        assert response.status_code == 201
        schedule_id = response.json()["id"]
        
        # 2. Get schedule by week
        response = client.get(
            f"/api/v2/training-schedules/week?user_id=1&week=34&year=2023", 
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["title"] == test_schedule["title"]
        
        # 3. Cleanup - Delete the schedule
        response = client.delete(
            f"/api/v2/training-schedules/{schedule_id}", 
            headers=self.headers
        )
        assert response.status_code == 204 