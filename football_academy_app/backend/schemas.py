from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


# -------- USER --------
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    position: Optional[str] = None
    current_club: Optional[str] = None
    date_of_birth: Optional[datetime] = None


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: int
    is_active: bool
    is_coach: bool

    class Config:
        from_attributes = True


# -------- TRAINING PLANS --------
class TrainingPlanBase(BaseModel):
    title: str
    description: Optional[str] = None


class TrainingPlanCreate(TrainingPlanBase):
    pass


class TrainingPlan(TrainingPlanBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# -------- EXERCISES --------
class ExerciseBase(BaseModel):
    name: str
    description: Optional[str] = None
    video_url: Optional[str] = None


class ExerciseCreate(ExerciseBase):
    pass


class Exercise(ExerciseBase):
    id: int
    training_plan_id: int

    class Config:
        from_attributes = True


# -------- PLAYER STATS --------
class PlayerStatBase(BaseModel):
    pace: int
    shooting: int
    passing: int
    dribbling: int
    defense: int
    physical: int
    overall_rating: int


class PlayerStatCreate(PlayerStatBase):
    player_id: int


class PlayerStat(PlayerStatBase):
    id: int
    player_id: int
    last_updated: datetime

    class Config:
        from_attributes = True


# Create an alias for PlayerStatsResponse to match the endpoint
class PlayerStatsResponse(PlayerStat):
    pass


# -------- ACHIEVEMENTS --------
class AchievementBase(BaseModel):
    title: str
    description: Optional[str] = None


class AchievementCreate(AchievementBase):
    pass


class Achievement(AchievementBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# -------- AUTH --------
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


# -------- CHALLENGES --------
class ChallengeBase(BaseModel):
    title: str
    description: Optional[str] = None
    xp_reward: int
    category: Optional[str] = None
    is_weekly: Optional[bool] = False
    level: Optional[int] = 1
    prerequisite_id: Optional[int] = None


class ChallengeCreate(ChallengeBase):
    pass


class ChallengeResponse(ChallengeBase):
    id: int

    class Config:
        from_attributes = True


# -------- CHALLENGE STATUS --------
class ChallengeStatusBase(BaseModel):
    user_id: int
    challenge_id: int
    status: str = "LOCKED"  # LOCKED, AVAILABLE, COMPLETED
    unlocked_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class ChallengeStatusCreate(BaseModel):
    challenge_id: int
    status: str = "LOCKED"


class ChallengeStatusResponse(ChallengeStatusBase):
    id: int

    class Config:
        from_attributes = True


# -------- CHALLENGE WITH STATUS --------
class ChallengeWithStatus(ChallengeResponse):
    status: str = "LOCKED"
    unlocked_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# -------- USER CHALLENGES --------
class UserChallengeResponse(BaseModel):
    id: int
    user_id: int
    challenge_id: int
    completed_at: datetime

    class Config:
        from_attributes = True


# -------- BADGES --------
class UserBadgeResponse(BaseModel):
    id: int
    user_id: int
    badge_name: str
    awarded_at: datetime

    class Config:
        from_attributes = True


# -------- CHALLENGE COMPLETION --------
class ChallengeCompletionCreate(BaseModel):
    challenge_id: int


class ChallengeCompletionWithDetails(BaseModel):
    id: int
    user_id: int
    challenge_id: int
    completed_at: datetime
    challenge_title: Optional[str]

    class Config:
        from_attributes = True


# -------- USER PROGRESS --------
class UserProgressResponse(BaseModel):
    user: UserResponse
    completed_challenges: List[UserChallengeResponse]
    badges: List[UserBadgeResponse]
    total_xp: int

    class Config:
        from_attributes = True


# -------- BADGE WITH CHALLENGE --------
class BadgeWithChallenge(BaseModel):
    id: int
    badge_name: str
    challenge_id: int
    challenge_title: str

    class Config:
        from_attributes = True


# -------------------------------
# ChallengeCompletion Schemas
# -------------------------------
class ChallengeCompletionBase(BaseModel):
    user_id: int
    challenge_id: int


class ChallengeCompletionCreate(ChallengeCompletionBase):
    pass

class ChallengeCompletion(ChallengeCompletionBase):
    id: int
    completed_at: datetime

    class Config:
        from_attributes = True

# -------- SIMPLE PLAYER STATS TEST (til test route) --------
class SimplePlayerStatBase(BaseModel):
    pace: int
    shooting: int
    passing: int
    player_id: int

class SimplePlayerStatCreate(SimplePlayerStatBase):
    pass

class SimplePlayerStat(SimplePlayerStatBase):
    id: int

    class Config:
        from_attributes = True
