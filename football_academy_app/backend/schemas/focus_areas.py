from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date

class FocusAreaBase(BaseModel):
    title: str
    description: str
    priority: Optional[int] = 0
    status: Optional[str] = "not_started"
    target_date: Optional[date] = None
    notes: Optional[str] = None

class FocusAreaCreate(FocusAreaBase):
    development_plan_id: int

class FocusAreaUpdate(FocusAreaBase):
    pass

class FocusArea(FocusAreaBase):
    id: int
    development_plan_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True 