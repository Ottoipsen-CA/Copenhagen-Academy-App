import os
import sys
import sqlite3
from datetime import datetime

# Add parent directory to path
parent_dir = os.path.dirname(os.path.abspath(__file__))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

import models
from database import engine, get_db

def fix_schema():
    """
    Fix the database schema by dropping and recreating tables with inconsistencies.
    This is a more aggressive approach than migrations and should be used with caution.
    """
    print("Fixing database schema...")
    
    # Connect to sqlite database
    conn = sqlite3.connect('football_academy.db')
    cursor = conn.cursor()
    
    try:
        # Backup challenge data
        print("Backing up challenge data...")
        cursor.execute("SELECT * FROM challenges")
        challenges_data = cursor.fetchall()
        
        # Get column names
        cursor.execute("PRAGMA table_info(challenges)")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        print(f"Found {len(challenges_data)} challenges with columns: {', '.join(column_names)}")
        
        # Drop the existing challenges table
        print("Dropping challenges table...")
        cursor.execute("DROP TABLE challenges")
        conn.commit()
        
        # Drop the challenge_statuses table if it exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='challenge_statuses'")
        if cursor.fetchone():
            print("Dropping challenge_statuses table...")
            cursor.execute("DROP TABLE challenge_statuses")
            conn.commit()
        
        # Close the connection
        conn.close()
        
        # Recreate tables with SQLAlchemy
        print("Recreating tables with new schema...")
        models.Base.metadata.create_all(bind=engine)
        
        # Add challenge data with new schema
        print("Adding challenge data with new schema...")
        db = next(get_db())
        
        challenges = [
            # Passing challenges - Level 1
            {"title": "Short Passing Accuracy", "description": "Complete 20 accurate short passes against a wall from 5 meters distance.", "xp_reward": 100, "category": "passing", "level": 1, "prerequisite_id": None},
            {"title": "Pass and Control", "description": "Pass the ball against a wall and control the ball with different parts of your body 15 times.", "xp_reward": 100, "category": "passing", "level": 1, "prerequisite_id": None},
            
            # Passing challenges - Level 2 (require level 1 completion)
            {"title": "Medium Range Passing", "description": "Complete 15 accurate passes to a target 15 meters away.", "xp_reward": 125, "category": "passing", "level": 2, "prerequisite_id": 1},
            {"title": "First-Touch Passing", "description": "Pass against a wall and receive with one touch, then pass again without stopping, 10 times.", "xp_reward": 125, "category": "passing", "level": 2, "prerequisite_id": 2},
            
            # Passing challenges - Level 3 (require level 2 completion)
            {"title": "Long Ball Precision", "description": "Hit a 2x2 meter target from 30 meters away 10 times.", "xp_reward": 150, "category": "passing", "level": 3, "prerequisite_id": 3},
            {"title": "No-Look Passing", "description": "Complete 10 no-look passes to a training partner with accuracy.", "xp_reward": 150, "category": "passing", "level": 3, "prerequisite_id": 4},
            
            # Shooting challenges - Level 1
            {"title": "Target Practice", "description": "Hit each corner of the goal 5 times from the penalty spot.", "xp_reward": 100, "category": "shooting", "level": 1, "prerequisite_id": None},
            {"title": "First-Time Shots", "description": "Score 10 first-time shots from a rolling ball.", "xp_reward": 100, "category": "shooting", "level": 1, "prerequisite_id": None},
            
            # Shooting challenges - Level 2
            {"title": "Long Range Shooting", "description": "Score 5 goals from outside the box.", "xp_reward": 125, "category": "shooting", "level": 2, "prerequisite_id": 7},
            {"title": "Volley Shots", "description": "Score 5 volley shots from a lofted pass.", "xp_reward": 125, "category": "shooting", "level": 2, "prerequisite_id": 8},
            
            # Dribbling challenges - Level 1
            {"title": "Cone Slalom", "description": "Dribble through 10 cones without touching any of them.", "xp_reward": 100, "category": "dribbling", "level": 1, "prerequisite_id": None},
            {"title": "Quick Feet", "description": "Complete 20 toe taps in 30 seconds.", "xp_reward": 100, "category": "dribbling", "level": 1, "prerequisite_id": None},
            
            # Weekly challenge
            {"title": "7-Day Streak", "description": "Train for 7 consecutive days.", "xp_reward": 200, "category": "weekly", "is_weekly": True, "level": 1, "prerequisite_id": None},
        ]
        
        for challenge_data in challenges:
            db.add(models.Challenge(**challenge_data))
        
        db.commit()
        db.close()
        
        print("Schema fix completed successfully!")
        return True
    
    except Exception as e:
        print(f"Error fixing schema: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    fix_schema() 