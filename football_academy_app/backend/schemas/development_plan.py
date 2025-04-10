from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from .training_session import TrainingSessionResponse
from .focus_area import FocusAreaResponse

# Base schema for common attributes
class DevelopmentPlanBase(BaseModel):
    player_id: int
    title: str
    long_term_goals: Optional[str] = None
    notes: Optional[str] = None

# Schema for creating a new development plan
class DevelopmentPlanCreate(DevelopmentPlanBase):
    pass

# Schema for updating an existing development plan
class DevelopmentPlanUpdate(BaseModel):
    title: Optional[str] = None
    long_term_goals: Optional[str] = None
    notes: Optional[str] = None

# Schema for reading/returning development plan data (includes ID and timestamps)
class DevelopmentPlan(DevelopmentPlanBase):
    id: int
    # player_id, title, long_term_goals, notes inherited from Base
    created_at: datetime
    updated_at: datetime
    training_sessions: List[TrainingSessionResponse] = []
    focus_areas: List[FocusAreaResponse] = []

    class Config:
        from_attributes = True 