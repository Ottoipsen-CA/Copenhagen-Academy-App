from sqlalchemy import text
from database import engine

def upgrade():
    with engine.connect() as conn:
        # Rename rating column
        conn.execute(text("ALTER TABLE player_tests RENAME COLUMN juggling_rating TO juggles_rating"))
        # Add position column
        conn.execute(text("ALTER TABLE player_tests ADD COLUMN position VARCHAR"))
        conn.commit()

def downgrade():
    with engine.connect() as conn:
        # Rename rating column back
        conn.execute(text("ALTER TABLE player_tests RENAME COLUMN juggles_rating TO juggling_rating"))
        # Remove position column
        conn.execute(text("ALTER TABLE player_tests DROP COLUMN position"))
        conn.commit()

if __name__ == "__main__":
    upgrade() 