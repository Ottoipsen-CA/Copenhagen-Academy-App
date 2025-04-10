from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TrainingSessionBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    weekday: int = Field(..., ge=1, le=7)  # 1-7 representing Monday-Sunday
    start_time: str = Field(..., pattern=r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$')
    duration_minutes: int = Field(..., gt=0)
    description: Optional[str] = None

class TrainingSessionCreate(TrainingSessionBase):
    development_plan_id: int

class TrainingSessionUpdate(TrainingSessionBase):
    pass

class TrainingSessionResponse(TrainingSessionBase):
    id: int
    development_plan_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True 