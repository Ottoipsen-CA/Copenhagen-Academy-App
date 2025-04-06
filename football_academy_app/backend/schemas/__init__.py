from .auth import UserBase, UserCreate, UserUpdate, UserResponse, TokenData, Token
from .skill_tests import (
    PlayerStatsBase, PlayerStatsCreate, PlayerStatsUpdate, PlayerStatsResponse,
    PlayerTestBase, PlayerTestCreate, PlayerTestUpdate, PlayerTestResponse
)
from .challenges import (
    ChallengeBase, ChallengeCreate, ChallengeUpdate, ChallengeResponse,
    ChallengeWithStatus, ChallengeStatusResponse,
    ChallengeCompletionBase, ChallengeCompletionCreate, ChallengeCompletionUpdate, ChallengeCompletionResponse,
    ChallengeCompletionWithDetails,
    BadgeBase, BadgeCreate, BadgeUpdate, BadgeResponse, BadgeWithChallenge,
    AchievementBase, AchievementCreate, AchievementUpdate, AchievementResponse,
    ChallengeStatusEnum,
    ChallengeResultBase, ChallengeResultCreate, ChallengeResultResponse, ChallengeResultWithCompletion
)
from .league_table import (
    LeagueTableEntryBase, LeagueTableEntryCreate, LeagueTableEntryUpdate, LeagueTableEntryResponse,
    ChallengeEntryBase, ChallengeEntryCreate, ChallengeEntryUpdate, ChallengeEntryResponse,
    ChallengeLeagueTableEntry, ChallengeLeagueTableResponse
)
from .training import (
    TrainingPlanBase, TrainingPlanCreate, TrainingPlanUpdate, TrainingPlanResponse,
    TrainingDayBase, TrainingDayCreate, TrainingDayUpdate, TrainingDayResponse,
    TrainingDayEntryBase, TrainingDayEntryCreate, TrainingDayEntryUpdate, TrainingDayEntryResponse
)
from .exercise_library import (
    ExerciseLibraryBase, ExerciseLibraryCreate, ExerciseLibraryUpdate, ExerciseLibraryResponse
)

__all__ = [
    # Auth schemas
    "UserBase", "UserCreate", "UserUpdate", "UserResponse", "TokenData", "Token",
    
    # Skill tests schemas
    "PlayerStatsBase", "PlayerStatsCreate", "PlayerStatsUpdate", "PlayerStatsResponse",
    "PlayerTestBase", "PlayerTestCreate", "PlayerTestUpdate", "PlayerTestResponse",
    
    # Challenges schemas
    "ChallengeBase", "ChallengeCreate", "ChallengeUpdate", "ChallengeResponse",
    "ChallengeWithStatus", "ChallengeStatusResponse",  
    "ChallengeCompletionBase", "ChallengeCompletionCreate", "ChallengeCompletionUpdate", "ChallengeCompletionResponse",
    "ChallengeCompletionWithDetails",
    "BadgeBase", "BadgeCreate", "BadgeUpdate", "BadgeResponse", "BadgeWithChallenge",
    "AchievementBase", "AchievementCreate", "AchievementUpdate", "AchievementResponse",
    "ChallengeStatusEnum",
    # Challenge Result schemas
    "ChallengeResultBase", "ChallengeResultCreate", "ChallengeResultResponse", "ChallengeResultWithCompletion",
    
    # League table schemas
    "LeagueTableEntryBase", "LeagueTableEntryCreate", "LeagueTableEntryUpdate", "LeagueTableEntryResponse",
    "ChallengeEntryBase", "ChallengeEntryCreate", "ChallengeEntryUpdate", "ChallengeEntryResponse",
    "ChallengeLeagueTableEntry", "ChallengeLeagueTableResponse",
    
    # Training schemas
    "TrainingPlanBase", "TrainingPlanCreate", "TrainingPlanUpdate", "TrainingPlanResponse",
    "TrainingDayBase", "TrainingDayCreate", "TrainingDayUpdate", "TrainingDayResponse",
    "TrainingDayEntryBase", "TrainingDayEntryCreate", "TrainingDayEntryUpdate", "TrainingDayEntryResponse",
    
    # Exercise library schemas
    "ExerciseLibraryBase", "ExerciseLibraryCreate", "ExerciseLibraryUpdate", "ExerciseLibraryResponse"
] 