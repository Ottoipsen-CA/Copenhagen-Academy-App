import os
import sys
from pathlib import Path

# Add the parent directory to the path so that imports work correctly
sys.path.append(str(Path(__file__).parent))

from database import engine, Base
from models import (
    User, 
    PlayerStats, 
    Test, 
    TestEntry, 
    PlayerTest,
    Challenge, 
    ChallengeStatus, 
    ChallengeCompletion, 
    Badge, 
    Achievement,
    LeagueTableEntry, 
    ChallengeEntry,
    TrainingPlan, 
    TrainingDay, 
    TrainingDayEntry,
    ExerciseLibrary
)

def create_tables():
    print("Creating all database tables...")
    # Create all tables defined in the models
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully!")

if __name__ == "__main__":
    create_tables() 