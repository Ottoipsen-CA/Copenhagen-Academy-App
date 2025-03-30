import requests
import json
import sys
import os
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:8080"

# Test user credentials
TEST_USER = {
    "email": "ottoipsen@gmail.com",
    "password": "carl1402"
}

def get_token():
    """Get authentication token"""
    response = requests.post(
        f"{BASE_URL}/token",
        data={"username": TEST_USER["email"], "password": TEST_USER["password"]}
    )
    
    if response.status_code != 200:
        print(f"Failed to get auth token: {response.text}")
        sys.exit(1)
        
    return response.json()["access_token"]

def submit_test_results(player_id, token):
    """Submit test results for a player"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Test results - these would normally come from user input
    test_data = {
        "player_id": player_id,
        "passing_test": 35,         # 35 successful passes in 1 minute
        "sprint_test": 2.1,         # 2.1 seconds for 15m sprint
        "first_touch_test": 30,     # 30 first touches in 1 minute
        "shooting_test": 10,        # 10 successful goals out of 15
        "juggling_test": 120,       # 120 juggles in 1 minute
        "dribbling_test": 13.5      # 13.5 seconds for dribbling course
    }
    
    response = requests.post(
        f"{BASE_URL}/player-tests/",
        headers=headers,
        json=test_data
    )
    
    print(f"Submit test results status: {response.status_code}")
    if response.status_code == 200:
        test_result = response.json()
        print(f"Test recorded with ID: {test_result['id']}")
        print(f"Calculated ratings:")
        print(f"  Passing: {test_result['passing_rating']}")
        print(f"  Pace: {test_result['pace_rating']}")
        print(f"  First Touch: {test_result['first_touch_rating']}")
        print(f"  Shooting: {test_result['shooting_rating']}")
        print(f"  Juggling: {test_result['juggling_rating']}")
        print(f"  Dribbling: {test_result['dribbling_rating']}")
        return test_result["id"]
    else:
        print(f"Failed to submit test results: {response.text}")
        return None

def get_latest_test(player_id, token):
    """Get the latest test results for a player"""
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    response = requests.get(
        f"{BASE_URL}/player-tests/{player_id}/latest",
        headers=headers
    )
    
    print(f"Get latest test status: {response.status_code}")
    if response.status_code == 200:
        test_result = response.json()
        print(f"Latest test date: {test_result['test_date']}")
        print(f"Ratings: {test_result['passing_rating']}/{test_result['pace_rating']}/"
              f"{test_result['shooting_rating']}/{test_result['dribbling_rating']}/"
              f"{test_result['juggling_rating']}/{test_result['first_touch_rating']}")
    else:
        print(f"Failed to get latest test: {response.text}")

def get_player_stats(player_id, token):
    """Get player stats to see updated ratings"""
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    response = requests.get(
        f"{BASE_URL}/player-stats/{player_id}",
        headers=headers
    )
    
    print(f"Get player stats status: {response.status_code}")
    if response.status_code == 200:
        stats = response.json()
        print(f"Updated player stats:")
        print(f"  Pace: {stats['pace']}")
        print(f"  Shooting: {stats['shooting']}")
        print(f"  Passing: {stats['passing']}")
        print(f"  Dribbling: {stats['dribbling']}")
        print(f"  Juggles: {stats['juggles']}")
        print(f"  First Touch: {stats['first_touch']}")
        print(f"  Overall: {stats['overall_rating']}")
    else:
        print(f"Failed to get player stats: {response.text}")

def main():
    print("Testing Player Tests API...")
    
    # Get token
    token = get_token()
    print(f"Got authentication token")
    
    # Player ID - this would normally be the logged-in user
    player_id = 1
    
    # Submit test results
    test_id = submit_test_results(player_id, token)
    
    if test_id:
        # Get latest test
        get_latest_test(player_id, token)
        
        # Get updated player stats
        get_player_stats(player_id, token)

if __name__ == "__main__":
    main() 