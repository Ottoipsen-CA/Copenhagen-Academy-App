from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# LeagueTableEntry schemas
class LeagueTableEntryBase(BaseModel):
    player_id: int
    points: int = 0
    challenges_completed: int = 0
    tests_completed: int = 0
    average_rating: float = 0.0
    rank: int
    previous_rank: Optional[int] = None
    rank_change: int = 0

class LeagueTableEntryCreate(LeagueTableEntryBase):
    pass

class LeagueTableEntryUpdate(BaseModel):
    points: Optional[int] = None
    challenges_completed: Optional[int] = None
    tests_completed: Optional[int] = None
    average_rating: Optional[float] = None
    rank: Optional[int] = None
    previous_rank: Optional[int] = None
    rank_change: Optional[int] = None

class LeagueTableEntryResponse(LeagueTableEntryBase):
    id: int
    last_updated: datetime

    class Config:
        orm_mode = True

# ChallengeEntry schemas
class ChallengeEntryBase(BaseModel):
    player_id: int
    challenge_id: int
    points_earned: int = 0
    included_in_rankings: bool = True

class ChallengeEntryCreate(ChallengeEntryBase):
    pass

class ChallengeEntryUpdate(BaseModel):
    points_earned: Optional[int] = None
    included_in_rankings: Optional[bool] = None

class ChallengeEntryResponse(ChallengeEntryBase):
    id: int
    completed_date: datetime
    created_at: datetime

    class Config:
        orm_mode = True

# Challenge League Table schemas
class ChallengeLeagueTableEntry(BaseModel):
    user_id: int
    full_name: str
    position: Optional[str] = None
    current_club: Optional[str] = None
    best_result: float
    submitted_at: datetime
    rank: Optional[int] = None

    class Config:
        orm_mode = True

# Response that includes challenge information
class ChallengeLeagueTableResponse(BaseModel):
    challenge_id: int
    challenge_title: str
    challenge_description: Optional[str] = None
    entries: List[ChallengeLeagueTableEntry] 