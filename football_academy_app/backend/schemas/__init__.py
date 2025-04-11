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
    "ChallengeLeagueTableEntry", "ChallengeLeagueTableResponse"
] 