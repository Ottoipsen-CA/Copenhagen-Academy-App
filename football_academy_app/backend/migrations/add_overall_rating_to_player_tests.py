from sqlalchemy import text
from database import engine

def upgrade():
    with engine.connect() as conn:
        # Add overall_rating column
        conn.execute(text("ALTER TABLE player_tests ADD COLUMN overall_rating INTEGER"))
        
        # Calculate and update overall_rating for existing records
        conn.execute(text("""
            UPDATE player_tests 
            SET overall_rating = (
                COALESCE(pace_rating, 0) + 
                COALESCE(shooting_rating, 0) + 
                COALESCE(passing_rating, 0) + 
                COALESCE(dribbling_rating, 0) + 
                COALESCE(juggles_rating, 0) + 
                COALESCE(first_touch_rating, 0)
            ) / (
                CASE WHEN pace_rating IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN shooting_rating IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN passing_rating IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN dribbling_rating IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN juggles_rating IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN first_touch_rating IS NOT NULL THEN 1 ELSE 0 END
            )
        """))
        conn.commit()

def downgrade():
    with engine.connect() as conn:
        # Remove overall_rating column
        conn.execute(text("ALTER TABLE player_tests DROP COLUMN overall_rating"))
        conn.commit()

if __name__ == "__main__":
    upgrade() 