from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

# TrainingPlan schemas
class TrainingPlanBase(BaseModel):
    title: str
    description: str
    difficulty_level: str
    focus_area: str
    duration_weeks: int = 1
    is_public: bool = False

class TrainingPlanCreate(TrainingPlanBase):
    created_by: int

class TrainingPlanUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    difficulty_level: Optional[str] = None
    focus_area: Optional[str] = None
    duration_weeks: Optional[int] = None
    is_public: Optional[bool] = None

class TrainingPlanResponse(TrainingPlanBase):
    id: int
    created_by: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# TrainingDay schemas
class TrainingDayBase(BaseModel):
    training_plan_id: int
    day_number: int
    title: str
    description: Optional[str] = None
    focus: Optional[str] = None
    duration_minutes: int = 60
    intensity: Optional[str] = None

class TrainingDayCreate(TrainingDayBase):
    pass

class TrainingDayUpdate(BaseModel):
    day_number: Optional[int] = None
    title: Optional[str] = None
    description: Optional[str] = None
    focus: Optional[str] = None
    duration_minutes: Optional[int] = None
    intensity: Optional[str] = None

class TrainingDayResponse(TrainingDayBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# TrainingDayEntry schemas
class TrainingDayEntryBase(BaseModel):
    training_day_id: int
    exercise_id: int
    order: int
    sets: Optional[int] = None
    reps: Optional[int] = None
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None
    custom_parameters: Optional[Dict[str, Any]] = None

class TrainingDayEntryCreate(TrainingDayEntryBase):
    pass

class TrainingDayEntryUpdate(BaseModel):
    exercise_id: Optional[int] = None
    order: Optional[int] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None
    custom_parameters: Optional[Dict[str, Any]] = None

class TrainingDayEntryResponse(TrainingDayEntryBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True 