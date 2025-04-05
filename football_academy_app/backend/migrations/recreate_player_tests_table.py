from sqlalchemy import text
from database import engine

def upgrade():
    with engine.connect() as conn:
        # Create a temporary table with the correct structure
        conn.execute(text("""
            CREATE TABLE player_tests_new (
                id INTEGER NOT NULL,
                player_id INTEGER,
                test_date DATETIME,
                position VARCHAR,
                pace FLOAT,
                shooting FLOAT,
                passing FLOAT,
                dribbling FLOAT,
                juggles FLOAT,
                first_touch FLOAT,
                pace_rating INTEGER,
                shooting_rating INTEGER,
                passing_rating INTEGER,
                dribbling_rating INTEGER,
                juggles_rating INTEGER,
                first_touch_rating INTEGER,
                notes VARCHAR,
                recorded_by INTEGER,
                PRIMARY KEY (id),
                FOREIGN KEY(player_id) REFERENCES users (id),
                FOREIGN KEY(recorded_by) REFERENCES users (id)
            )
        """))
        conn.commit()

        # Copy data from old table to new table
        conn.execute(text("""
            INSERT INTO player_tests_new (
                id, player_id, test_date, position, pace, shooting, passing,
                dribbling, juggles, first_touch, pace_rating, shooting_rating,
                passing_rating, dribbling_rating, juggles_rating, first_touch_rating,
                notes, recorded_by
            )
            SELECT 
                id, player_id, test_date, position, pace, shooting, passing,
                dribbling, juggles, first_touch, pace_rating, shooting_rating,
                passing_rating, dribbling_rating, juggles_rating, first_touch_rating,
                notes, recorded_by
            FROM player_tests
        """))
        conn.commit()

        # Drop old table and rename new table
        conn.execute(text("DROP TABLE player_tests"))
        conn.commit()
        conn.execute(text("ALTER TABLE player_tests_new RENAME TO player_tests"))
        conn.commit()

        # Recreate the index
        conn.execute(text("CREATE INDEX ix_player_tests_id ON player_tests (id)"))
        conn.commit()

def downgrade():
    # Note: This is a destructive operation that cannot be easily reversed
    # as we're recreating the table. In a production environment, you would
    # want to backup the data first.
    pass

if __name__ == "__main__":
    upgrade() 