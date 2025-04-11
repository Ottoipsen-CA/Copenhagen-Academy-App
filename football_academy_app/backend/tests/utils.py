"""
Utility functions for testing API endpoints.
"""
import json
from typing import Dict, Any, Optional
from datetime import date

# Define JSON boolean values for use in Python
true = True
false = False

# Import the Position enum from constants
from constants.position_weights import Position

def get_auth_header(client, email: str = "test@example.com", password: str = "password123") -> Dict[str, str]:
    """
    Get an authentication header by logging in a test user.
    
    Args:
        client: The TestClient instance
        email: The email to use for login (default hardcoded value)
        password: The password to use for login (default hardcoded value)
        
    Returns:
        Dict with Authorization header
    """
    # Use hardcoded values for consistency
    email = "test@example.com"
    password = "password123"
    
    # First try to create a test user
    try:
        register_data = {
            "email": "test@example.com",
            "password": "password123",
            "full_name": "Test User",
            "position": "striker",  # Use lowercase "striker" from enum
            "current_club": "Test FC",
            "date_of_birth": "2000-01-01",  # ISO format YYYY-MM-DD
            "is_active": true,
            "is_coach": true,
            "role": "coach"
        }
        response = client.post("/api/v2/auth/register", json=register_data)
        print(f"Register response: {response.status_code}")
        if response.status_code != 201 and response.status_code != 200:
            print(f"Registration failed with reason: {response.text}")
    except Exception as e:
        print(f"Registration exception: {str(e)}")
        pass
    
    # Try multiple login methods with hardcoded credentials
    
    # 1. Try form data (username/password)
    try:
        form_response = client.post(
            "/api/v2/auth/login",
            data={"username": "test@example.com", "password": "password123"}
        )
        
        if form_response.status_code == 200 and "access_token" in form_response.json():
            token = form_response.json().get("access_token")
            return {"Authorization": f"Bearer {token}"}
    except Exception as e:
        print(f"Form login exception: {str(e)}")
    
    # 2. Try JSON with email/password
    try:
        json_response = client.post(
            "/api/v2/auth/login",
            json={"email": "test@example.com", "password": "password123"}
        )
        
        if json_response.status_code == 200 and "access_token" in json_response.json():
            token = json_response.json().get("access_token")
            return {"Authorization": f"Bearer {token}"}
    except Exception as e:
        print(f"JSON login exception: {str(e)}")
    
    # 3. Try JSON with username/password
    try:
        json_username_response = client.post(
            "/api/v2/auth/login",
            json={"username": "test@example.com", "password": "password123"}
        )
        
        if json_username_response.status_code == 200 and "access_token" in json_username_response.json():
            token = json_username_response.json().get("access_token")
            return {"Authorization": f"Bearer {token}"}
    except Exception as e:
        print(f"JSON username login exception: {str(e)}")
    
    # Print debug info
    print("All login attempts failed")
    
    return {}

def create_test_data(client, resource_type: str, data: Dict[str, Any], auth_header: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """
    Create test data for a given resource type.
    
    Args:
        client: The TestClient instance
        resource_type: The type of resource to create (e.g., "skill-tests", "challenges")
        data: The data to use for creation
        auth_header: Optional authentication header
        
    Returns:
        The created resource data
    """
    headers = {"Content-Type": "application/json"}
    if auth_header:
        headers.update(auth_header)
    
    # Try both hyphenated and underscore versions of the endpoint
    hyphen_url = f"/api/v2/{resource_type}"
    underscore_url = hyphen_url.replace("-", "_")
    
    # Try hyphenated version first
    response = client.post(
        hyphen_url,
        headers=headers,
        json=data
    )
    
    # If hyphenated fails, try underscore
    if response.status_code == 404:
        response = client.post(
            underscore_url,
            headers=headers,
            json=data
        )
    
    if response.status_code in (200, 201):
        return response.json()
    
    return {} 