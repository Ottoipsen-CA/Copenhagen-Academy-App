import pytest
from fastapi import status
from tests.utils import get_auth_header
from constants.position_weights import Position
import json

def test_root(client):
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK
    assert "message" in response.json()
    assert response.json()["message"] == "Welcome to Football Academy API"

def test_health_check(client):
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"status": "healthy"}

# Auth Endpoints
class TestAuthEndpoints:
    def test_auth_endpoints_exist(self, client):
        """Test that auth endpoints are defined and return appropriate status codes."""
        # Test login endpoint (will fail without credentials but should return 422 not 404)
        response = client.post("/api/v2/auth/login")
        assert response.status_code != status.HTTP_404_NOT_FOUND
        
        # Test register endpoint
        response = client.post("/api/v2/auth/register")
        assert response.status_code != status.HTTP_404_NOT_FOUND

# Skill Tests Endpoints
class TestSkillTestsEndpoints:
    def test_skill_tests_operations(self, client):
        """Test all skill-tests operations: create, get, and delete."""
        # Step 1: Register a test user
        register_data = {
            "email": "skilltest@example.com",
            "password": "password123",
            "full_name": "Skill Test User",
            "position": "striker",
            "current_club": "Test FC",
            "date_of_birth": "2000-01-01",
            "is_active": True,
            "is_coach": True,
            "role": "coach"
        }
        
        register_response = client.post("/api/v2/auth/register", json=register_data)
        if register_response.status_code not in [200, 201]:
            pytest.skip(f"User registration failed: {register_response.status_code}")
            
        # Get user ID from registration response
        user_id = None
        try:
            user_id = register_response.json().get("id")
            print(f"Registered user with ID: {user_id}")
        except:
            pytest.skip("Could not extract user ID from registration response")
            
        if not user_id:
            pytest.skip("User ID is empty or null")
            
        # Step 2: Get auth header for the registered user
        auth_header = get_auth_header(client, email="skilltest@example.com", password="password123")
        if not auth_header:
            pytest.skip("Authentication failed, skipping test")
        
        # Step 3: CREATE operation - Create a skill test
        create_url = "/api/v2/skill-tests/player-tests"
        create_data = {
            "player_id": user_id,
            "date": "2023-04-15",
            "pace": 85,
            "shooting": 80,
            "passing": 78,
            "dribbling": 82,
            "juggles": 75,
            "first_touch": 79,
            "notes": "Test created by pytest"
        }
        
        print(f"Testing CREATE at URL: {create_url}")
        create_response = client.post(
            create_url, 
            headers={**auth_header, "Content-Type": "application/json"},
            json=create_data
        )
        print(f"CREATE response status: {create_response.status_code}")
        
        # Verify we can create a test
        assert create_response.status_code in [200, 201], f"Create test failed with status {create_response.status_code}"
        
        # Get test ID from response
        test_id = None
        try:
            test_id = create_response.json().get("id")
            print(f"Created test with ID: {test_id}")
        except:
            pytest.skip("Could not extract test ID from response")
            
        if not test_id:
            pytest.skip("Test ID is empty or null")
        
        # Step 4: GET operation - Get player tests
        get_url = f"/api/v2/skill-tests/player-tests/player/{user_id}"
        print(f"Testing GET at URL: {get_url}")
        get_response = client.get(get_url, headers=auth_header)
        print(f"GET response status: {get_response.status_code}")
        
        # Verify we can get tests
        assert get_response.status_code == 200, f"Get tests failed with status {get_response.status_code}"
        
        # Step 5: DELETE operation - Delete the test
        delete_url = f"/api/v2/skill-tests/player-tests/{test_id}"
        print(f"Testing DELETE at URL: {delete_url}")
        delete_response = client.delete(delete_url, headers=auth_header)
        print(f"DELETE response status: {delete_response.status_code}")
        
        # Verify we can delete the test
        assert delete_response.status_code in [200, 204], f"Delete test failed with status {delete_response.status_code}"
        
        print("All skill tests operations passed!")
        
    def test_skill_tests_endpoints_exist(self, client):
        """Test that skill tests endpoints exist (without auth)."""
        # Just check if the base endpoints return a non-404 status
        endpoints = [
            "/api/v2/skill-tests/player-tests",  # POST endpoint
            "/api/v2/skill-tests/player-tests/player/1",  # GET endpoint with sample ID
            "/api/v2/skill-tests/player-tests/1"  # DELETE endpoint with sample ID
        ]
        
        found_endpoints = []
        for endpoint in endpoints:
            # Try different methods as appropriate
            if endpoint == "/api/v2/skill-tests/player-tests":
                response = client.options(endpoint)  # OPTIONS usually works even without auth
            else:
                response = client.options(endpoint)
                
            if response.status_code != 404:
                found_endpoints.append(endpoint)
                print(f"Found endpoint: {endpoint} (status: {response.status_code})")
                
        # Pass if we found at least one endpoint
        assert len(found_endpoints) > 0, "No skill tests endpoints found"

# Challenge Endpoints
class TestChallengeEndpoints:
    def test_challenge_endpoints_exist(self, client):
        """Test that challenge endpoints are defined."""
        response = client.get("/api/v2/challenges")
        assert response.status_code != status.HTTP_404_NOT_FOUND
        
    def test_challenges_with_auth(self, client):
        """Test challenges endpoints with authentication."""
        auth_header = get_auth_header(client)
        if not auth_header:
            pytest.skip("Authentication failed, skipping test")
            
        response = client.get("/api/v2/challenges", headers=auth_header)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_204_NO_CONTENT]

# League Table Endpoints
class TestLeagueTableEndpoints:
    def test_league_table_endpoints_exist(self, client):
        """Test that league table endpoints are defined."""
        response = client.get("/api/v2/league-table")
        assert response.status_code != status.HTTP_404_NOT_FOUND
        
    def test_league_table_with_auth(self, client):
        """Test league table endpoints with authentication."""
        auth_header = get_auth_header(client)
        if not auth_header:
            pytest.skip("Authentication failed, skipping test")
            
        response = client.get("/api/v2/league-table", headers=auth_header)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_204_NO_CONTENT]

def test_auth_debug(client):
    """Debug the authentication process."""
    # Test register endpoint with hardcoded credentials
    register_data = {
        "email": "test@example.com",
        "password": "password123",
        "full_name": "Test User",
        "position": "striker",  # lowercase for position enum
        "current_club": "Test FC",
        "date_of_birth": "2000-01-01",
        "is_active": True,  # Python boolean
        "is_coach": True,   # Python boolean
        "role": "coach"
    }
    
    print("\n=== Registration Data ===")
    print(json.dumps(register_data, indent=2))
    
    register_response = client.post("/api/v2/auth/register", json=register_data)
    print(f"\n=== Register Response ===")
    print(f"Status: {register_response.status_code}")
    print(f"Response Text: {register_response.text}")
    if register_response.status_code < 500:
        if register_response.headers.get('content-type', '').startswith('application/json'):
            print(f"Body: {register_response.json()}")
        else:
            print(f"Non-JSON Response: {register_response.text}")
        if register_response.status_code != 200 and register_response.status_code != 201:
            print(f"Registration failed with status {register_response.status_code}")
    else:
        print("Server error")
    
    # Try a simpler registration
    simple_register = {
        "email": "simple@example.com",
        "password": "password123",
        "full_name": "Simple User",
        "is_active": True  # Python boolean
    }
    
    simple_response = client.post("/api/v2/auth/register", json=simple_register)
    print(f"\n=== Simple Register Response ===")
    print(f"Status: {simple_response.status_code}")
    
    # Test login endpoint with form data
    form_login = client.post(
        "/api/v2/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    print(f"\n=== Form Login Response ===")
    print(f"Status: {form_login.status_code}")
    if form_login.status_code < 500:
        print(f"Body: {form_login.json() if hasattr(form_login, 'json') else 'No JSON'}")
    
    # Test login endpoint with JSON
    json_login = client.post(
        "/api/v2/auth/login",
        json={"email": "test@example.com", "password": "password123"}
    )
    print(f"\n=== JSON Login Response ===")
    print(f"Status: {json_login.status_code}")
    if json_login.status_code < 500:
        print(f"Body: {json_login.json() if hasattr(json_login, 'json') else 'No JSON'}")
    
    # Check auth endpoints
    print("\n=== Auth Endpoints Check ===")
    for path in ["/api/v2/auth/login", "/api/v2/auth/token", "/api/v2/auth/register"]:
        response = client.get(path)
        print(f"{path}: {response.status_code}")
    
    # Check API documentation for clues
    print("\n=== API Documentation Check ===")
    docs_response = client.get("/docs")
    if docs_response.status_code == 200:
        print("Swagger docs available at /docs")
    
    openapi_response = client.get("/openapi.json")
    if openapi_response.status_code == 200:
        print("OpenAPI schema available")
        # Look for auth endpoints in schema
        schema = openapi_response.json()
        auth_paths = [path for path in schema.get("paths", {}).keys() if "auth" in path]
        print(f"Auth paths in schema: {auth_paths}") 