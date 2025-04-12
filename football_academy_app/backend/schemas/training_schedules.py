from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date, time

# Training Session Schemas
class TrainingSessionBase(BaseModel):
    day_of_week: int  # 1-7 for Monday-Sunday
    session_date: date
    title: str
    description: Optional[str] = None
    start_time: time
    end_time: time
    location: Optional[str] = None
    focus_area_id: Optional[int] = None
    has_reflection: Optional[bool] = False
    reflection_text: Optional[str] = None

class TrainingSessionCreate(TrainingSessionBase):
    schedule_id: int

class TrainingSessionUpdate(TrainingSessionBase):
    pass

class TrainingSessionReflection(BaseModel):
    reflection_text: str

class TrainingSession(TrainingSessionBase):
    id: int
    schedule_id: int
    reflection_added_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# Training Schedule Schemas
class TrainingScheduleBase(BaseModel):
    week_number: int
    year: int
    title: str
    notes: Optional[str] = None
    development_plan_id: Optional[int] = None

class TrainingScheduleCreate(TrainingScheduleBase):
    user_id: int

class TrainingScheduleUpdate(TrainingScheduleBase):
    pass

class TrainingSchedule(TrainingScheduleBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    training_sessions: Optional[List[TrainingSession]] = []

    class Config:
        orm_mode = True 