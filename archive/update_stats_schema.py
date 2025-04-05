"""
Migration script to update the player_stats table from defense/physical to juggles/first_touch

To run: python update_stats_schema.py
"""

import sqlite3
import sys
import os
from datetime import datetime

DB_PATH = 'football_academy.db'

def migrate_player_stats():
    """Update the player_stats table schema and convert existing data"""
    
    print("Starting player stats schema migration...")
    
    # Connect to database
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # Check if the columns already exist
        cursor.execute("PRAGMA table_info(player_stats)")
        columns = [col[1] for col in cursor.fetchall()]
        
        if 'juggles' in columns and 'first_touch' in columns:
            print("Schema already updated. No changes needed.")
            return
        
        # Create temporary table with new schema
        print("Creating temporary table with new schema...")
        cursor.execute("""
        CREATE TABLE player_stats_new (
            id INTEGER PRIMARY KEY,
            player_id INTEGER REFERENCES users(id),
            pace INTEGER,
            shooting INTEGER,
            passing INTEGER,
            dribbling INTEGER,
            juggles INTEGER,
            first_touch INTEGER,
            overall_rating INTEGER,
            last_updated DATETIME
        )
        """)
        
        # Copy data, converting defense to juggles and physical to first_touch
        print("Migrating existing data...")
        cursor.execute("""
        INSERT INTO player_stats_new (
            id, player_id, pace, shooting, passing, dribbling, 
            juggles, first_touch, overall_rating, last_updated
        )
        SELECT 
            id, player_id, pace, shooting, passing, dribbling, 
            defense, physical, overall_rating, last_updated
        FROM player_stats
        """)
        
        # Drop old table and rename new one
        print("Replacing old table with new schema...")
        cursor.execute("DROP TABLE player_stats")
        cursor.execute("ALTER TABLE player_stats_new RENAME TO player_stats")
        
        # Recalculate overall ratings just to be safe
        print("Recalculating overall ratings...")
        cursor.execute("""
        UPDATE player_stats
        SET overall_rating = (pace + shooting + passing + dribbling + juggles + first_touch) / 6
        """)
        
        # Commit changes
        conn.commit()
        print("Migration completed successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"Error during migration: {e}")
        sys.exit(1)
    
    finally:
        conn.close()

if __name__ == "__main__":
    migrate_player_stats() 