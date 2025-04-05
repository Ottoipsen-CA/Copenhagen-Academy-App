from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

# PlayerStats schemas
class PlayerStatsBase(BaseModel):
    pace: float = Field(50, ge=0, le=99)
    shooting: float = Field(50, ge=0, le=99)
    passing: float = Field(50, ge=0, le=99)
    dribbling: float = Field(50, ge=0, le=99)
    juggles: float = Field(50, ge=0, le=99)
    first_touch: float = Field(50, ge=0, le=99)
    overall_rating: float = Field(50, ge=0, le=99)

class PlayerStatsCreate(PlayerStatsBase):
    player_id: int

class PlayerStatsUpdate(BaseModel):
    pace: Optional[float] = Field(None, ge=0, le=99)
    shooting: Optional[float] = Field(None, ge=0, le=99)
    passing: Optional[float] = Field(None, ge=0, le=99)
    dribbling: Optional[float] = Field(None, ge=0, le=99)
    juggles: Optional[float] = Field(None, ge=0, le=99)
    first_touch: Optional[float] = Field(None, ge=0, le=99)
    overall_rating: Optional[float] = Field(None, ge=0, le=99)

class PlayerStatsResponse(PlayerStatsBase):
    id: int
    player_id: int
    last_updated: datetime

    class Config:
        orm_mode = True

# PlayerTest schemas
class PlayerTestBase(BaseModel):
    player_id: int
    test_date: Optional[datetime] = None
    position: Optional[str] = None
    pace: Optional[float] = None
    shooting: Optional[float] = None
    passing: Optional[float] = None
    dribbling: Optional[float] = None
    juggles: Optional[float] = None
    first_touch: Optional[float] = None
    pace_rating: Optional[int] = None
    shooting_rating: Optional[int] = None
    passing_rating: Optional[int] = None
    dribbling_rating: Optional[int] = None
    juggles_rating: Optional[int] = None
    first_touch_rating: Optional[int] = None
    overall_rating: Optional[int] = None
    notes: Optional[str] = None

class PlayerTestCreate(PlayerTestBase):
    pass

class PlayerTestUpdate(PlayerTestBase):
    pass

class PlayerTestResponse(PlayerTestBase):
    id: int
    pace_rating: Optional[int] = None
    shooting_rating: Optional[int] = None
    passing_rating: Optional[int] = None
    dribbling_rating: Optional[int] = None
    juggles_rating: Optional[int] = None
    first_touch_rating: Optional[int] = None
    recorded_by: Optional[int] = None

    class Config:
        orm_mode = True 