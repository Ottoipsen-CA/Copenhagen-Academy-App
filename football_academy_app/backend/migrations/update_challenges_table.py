import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from database import engine
from models.challenges import MeasurementType

def upgrade():
    with engine.connect() as conn:
        # Create a new table with the desired schema
        conn.execute(text("""
            CREATE TABLE challenges_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                category VARCHAR NOT NULL,
                difficulty VARCHAR NOT NULL,
                points INTEGER NOT NULL DEFAULT 0,
                start_date TIMESTAMP NOT NULL,
                end_date TIMESTAMP NOT NULL,
                is_weekly BOOLEAN NOT NULL DEFAULT FALSE,
                measurement_type VARCHAR NOT NULL CHECK(measurement_type IN ('SECONDS', 'COUNT', 'DISTANCE', 'REPETITIONS', 'SCORE')),
                target_value INTEGER NOT NULL DEFAULT 0,
                created_by INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                badge_id INTEGER
            )
        """))
        
        # Copy data from the old table to the new one
        conn.execute(text("""
            INSERT INTO challenges_new (
                id, title, description, category, difficulty, points,
                start_date, end_date, created_by, created_at, updated_at,
                is_active, badge_id, measurement_type, target_value
            )
            SELECT 
                id, title, description, 
                'technical' as category,  -- default category
                'beginner' as difficulty, -- default difficulty
                100 as points,            -- default points
                COALESCE(start_date, CURRENT_TIMESTAMP) as start_date,
                COALESCE(end_date, CURRENT_TIMESTAMP) as end_date,
                1 as created_by,          -- default creator ID
                created_at,
                updated_at,
                TRUE as is_active,        -- default to active
                NULL as badge_id,         -- no badge by default
                'COUNT' as measurement_type, -- default measurement type
                0 as target_value         -- default target value
            FROM challenges
        """))
        
        # Drop the old table
        conn.execute(text("DROP TABLE challenges"))
        
        # Rename the new table to the original name
        conn.execute(text("ALTER TABLE challenges_new RENAME TO challenges"))
        
        conn.commit()

def downgrade():
    with engine.connect() as conn:
        # Create a new table with the old schema
        conn.execute(text("""
            CREATE TABLE challenges_old (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                criteria TEXT,
                start_date TIMESTAMP,
                end_date TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        
        # Copy data from the current table to the old schema
        conn.execute(text("""
            INSERT INTO challenges_old (
                id, title, description, start_date, end_date,
                created_at, updated_at
            )
            SELECT 
                id, title, description, start_date, end_date,
                created_at, updated_at
            FROM challenges
        """))
        
        # Drop the current table
        conn.execute(text("DROP TABLE challenges"))
        
        # Rename the old schema table to the original name
        conn.execute(text("ALTER TABLE challenges_old RENAME TO challenges"))
        
        conn.commit()

if __name__ == "__main__":
    upgrade() 