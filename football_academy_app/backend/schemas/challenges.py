from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class ChallengeStatusEnum(str, Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    EXPIRED = "expired"

# Challenge schemas
class ChallengeBase(BaseModel):
    title: str
    description: str
    category: str
    difficulty: str
    points: int = 100
    criteria: Dict[str, Any]
    start_date: datetime = Field(default_factory=datetime.utcnow)
    end_date: Optional[datetime] = None
    is_active: bool = True

class ChallengeCreate(ChallengeBase):
    created_by: int
    badge_id: Optional[int] = None

class ChallengeUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    difficulty: Optional[str] = None
    points: Optional[int] = None
    criteria: Optional[Dict[str, Any]] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    is_active: Optional[bool] = None
    badge_id: Optional[int] = None

class ChallengeResponse(ChallengeBase):
    id: int
    created_by: int
    created_at: datetime
    updated_at: datetime
    badge_id: Optional[int] = None

    class Config:
        orm_mode = True

# Additional schema for use with the get-with-status endpoint
class ChallengeWithStatus(BaseModel):
    id: int
    title: str
    description: str
    xp_reward: int = Field(alias="points")
    category: str
    is_weekly: bool = False
    level: int = 1
    prerequisite_id: Optional[int] = None
    status: str
    unlocked_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        orm_mode = True

# ChallengeStatus schema for responses
class ChallengeStatusResponse(BaseModel):
    id: int
    user_id: int
    challenge_id: int
    status: str
    unlocked_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        orm_mode = True

# ChallengeCompletion schemas
class ChallengeCompletionBase(BaseModel):
    user_id: int
    challenge_id: int
    status: ChallengeStatusEnum = ChallengeStatusEnum.ACTIVE
    progress: float = 0.0
    notes: Optional[str] = None

class ChallengeCompletionCreate(ChallengeCompletionBase):
    verified_by: Optional[int] = None
    completed_at: Optional[datetime] = None

class ChallengeCompletionUpdate(BaseModel):
    status: Optional[ChallengeStatusEnum] = None
    progress: Optional[float] = None
    notes: Optional[str] = None
    verified_by: Optional[int] = None
    completed_at: Optional[datetime] = None

class ChallengeCompletionResponse(ChallengeCompletionBase):
    id: int
    completed_at: Optional[datetime] = None
    verified_by: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class ChallengeCompletionWithDetails(ChallengeCompletionResponse):
    """Extended schema with challenge details"""
    challenge: Dict[str, Any]
    results: List[Dict[str, Any]] = []

    class Config:
        orm_mode = True

# ChallengeResult schemas
class ChallengeResultBase(BaseModel):
    completion_id: int
    result_value: float
    notes: Optional[str] = None

class ChallengeResultCreate(BaseModel):
    result_value: float
    notes: Optional[str] = None

class ChallengeResultResponse(ChallengeResultBase):
    id: int
    submitted_at: datetime

    class Config:
        orm_mode = True

class ChallengeResultWithCompletion(ChallengeResultResponse):
    completion: ChallengeCompletionResponse

    class Config:
        orm_mode = True

# Badge schemas
class BadgeBase(BaseModel):
    name: str
    description: str
    image_url: str
    criteria: str

class BadgeCreate(BadgeBase):
    pass

class BadgeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    criteria: Optional[str] = None

class BadgeResponse(BadgeBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

class BadgeWithChallenge(BadgeResponse):
    challenge: Optional[ChallengeResponse] = None

    class Config:
        orm_mode = True

# Achievement schemas
class AchievementBase(BaseModel):
    user_id: int
    badge_id: int

class AchievementCreate(AchievementBase):
    awarded_by: Optional[int] = None

class AchievementUpdate(BaseModel):
    # Usually achievements are just awarded/deleted, not updated. 
    # If update is needed, define fields here.
    pass

class AchievementResponse(AchievementBase):
    id: int
    earned_at: datetime
    awarded_by: Optional[int] = None

    class Config:
        orm_mode = True 