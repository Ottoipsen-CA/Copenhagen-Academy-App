from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime

class ExerciseLibraryBase(BaseModel):
    name: str
    description: str
    category: str
    difficulty_level: str
    duration_minutes: int
    equipment: Optional[str] = None
    video_url: Optional[str] = None
    image_url: Optional[str] = None
    instructions: str
    benefits: Optional[str] = None
    is_public: bool = True
    parameters: Optional[Dict[str, Any]] = None

class ExerciseLibraryCreate(ExerciseLibraryBase):
    created_by: int

class ExerciseLibraryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    difficulty_level: Optional[str] = None
    duration_minutes: Optional[int] = None
    equipment: Optional[str] = None
    video_url: Optional[str] = None
    image_url: Optional[str] = None
    instructions: Optional[str] = None
    benefits: Optional[str] = None
    is_public: Optional[bool] = None
    parameters: Optional[Dict[str, Any]] = None

class ExerciseLibraryResponse(ExerciseLibraryBase):
    id: int
    created_by: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True 