from pydantic import BaseModel, Field
from datetime import date, datetime

class FocusAreaBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=1)
    target_date: date
    is_completed: bool = False

class FocusAreaCreate(FocusAreaBase):
    development_plan_id: int

class FocusAreaUpdate(FocusAreaBase):
    pass

class FocusAreaResponse(FocusAreaBase):
    id: int
    development_plan_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True 