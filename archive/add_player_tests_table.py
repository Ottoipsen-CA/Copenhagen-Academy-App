import sys
import os
import sqlite3
from datetime import datetime

# Add the parent directory to the path
parent_dir = os.path.dirname(os.path.abspath(__file__))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

# Database path
DATABASE_PATH = "football_academy.db"

def create_player_tests_table():
    """
    Create the player_tests table to store skill test results
    """
    conn = sqlite3.connect(DATABASE_PATH)
    cursor = conn.cursor()
    
    # Check if table already exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='player_tests'")
    if cursor.fetchone():
        print("Table player_tests already exists.")
        conn.close()
        return
    
    # Create the player_tests table
    cursor.execute("""
    CREATE TABLE player_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        passing_test INTEGER,
        sprint_test REAL,
        first_touch_test INTEGER,
        shooting_test INTEGER,
        juggling_test INTEGER,
        dribbling_test REAL,
        passing_rating INTEGER,
        pace_rating INTEGER,
        first_touch_rating INTEGER,
        shooting_rating INTEGER,
        juggling_rating INTEGER,
        dribbling_rating INTEGER,
        FOREIGN KEY (player_id) REFERENCES users (id)
    )
    """)
    
    print("Created player_tests table.")
    conn.commit()
    conn.close()

if __name__ == "__main__":
    print(f"Running migration to add player_tests table...")
    create_player_tests_table()
    print("Migration completed.") 