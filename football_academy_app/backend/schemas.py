from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    position: Optional[str] = None
    current_club: Optional[str] = None
    date_of_birth: Optional[datetime] = None

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    is_coach: bool

    class Config:
        from_attributes = True

# Training plan schemas
class TrainingPlanBase(BaseModel):
    title: str
    description: str

class TrainingPlanCreate(TrainingPlanBase):
    pass

class TrainingPlan(TrainingPlanBase):
    id: int
    player_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Exercise schemas
class ExerciseBase(BaseModel):
    title: str
    description: str
    video_url: str
    duration: int
    difficulty: str
    category: str

class ExerciseCreate(ExerciseBase):
    training_plan_id: int

class Exercise(ExerciseBase):
    id: int
    training_plan_id: int

    class Config:
        from_attributes = True

# Achievement schemas
class AchievementBase(BaseModel):
    title: str
    description: str

class AchievementCreate(AchievementBase):
    player_id: int

class Achievement(AchievementBase):
    id: int
    player_id: int
    earned_at: datetime

    class Config:
        from_attributes = True

# Player stats schemas
class PlayerStatsBase(BaseModel):
    pace: float
    shooting: float
    passing: float
    dribbling: float
    defense: float
    physical: float
    overall_rating: float

class PlayerStatsCreate(PlayerStatsBase):
    player_id: int

class PlayerStats(PlayerStatsBase):
    id: int
    player_id: int
    last_updated: datetime

    class Config:
        from_attributes = True

# Token schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None 