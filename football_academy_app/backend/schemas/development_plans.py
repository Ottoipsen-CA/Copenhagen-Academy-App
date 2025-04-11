from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class DevelopmentPlanBase(BaseModel):
    title: str
    long_term_goals: str
    notes: Optional[str] = None

class DevelopmentPlanCreate(DevelopmentPlanBase):
    user_id: int

class DevelopmentPlanUpdate(DevelopmentPlanBase):
    pass

class DevelopmentPlan(DevelopmentPlanBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True 