from sqlalchemy import text
from database import engine

def upgrade():
    with engine.connect() as conn:
        # Add position column
        conn.execute(text("ALTER TABLE player_tests ADD COLUMN position VARCHAR"))
        conn.commit()

def downgrade():
    with engine.connect() as conn:
        # Remove position column
        conn.execute(text("ALTER TABLE player_tests DROP COLUMN position"))
        conn.commit()

if __name__ == "__main__":
    upgrade() 