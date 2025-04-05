# Import all models
from .users import User
from .skill_tests import PlayerStats, Test, TestEntry, PlayerTest
from .challenges import Challenge, ChallengeStatus, ChallengeCompletion, Badge, Achievement
from .league_table import LeagueTableEntry, ChallengeEntry
from .training import TrainingPlan, TrainingDay, TrainingDayEntry
from .exercise_library import ExerciseLibrary

# Export all models
__all__ = [
    "User",
    "PlayerStats",
    "Test",
    "TestEntry",
    "PlayerTest",
    "Challenge",
    "ChallengeStatus",
    "ChallengeCompletion",
    "Badge",
    "Achievement",
    "LeagueTableEntry",
    "ChallengeEntry",
    "TrainingPlan",
    "TrainingDay",
    "TrainingDayEntry",
    "ExerciseLibrary"
] 