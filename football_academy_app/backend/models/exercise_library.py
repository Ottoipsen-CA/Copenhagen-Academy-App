from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

class ExerciseLibrary(Base):
    __tablename__ = "exercise_library"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    category = Column(String, index=True)  # technical, physical, tactical, mental
    difficulty_level = Column(String, index=True)  # beginner, intermediate, advanced
    duration_minutes = Column(Integer)
    equipment = Column(String, nullable=True)
    video_url = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    instructions = Column(String)
    benefits = Column(String, nullable=True)
    created_by = Column(Integer, ForeignKey("users.user_id"))
    is_public = Column(Boolean, default=True)
    parameters = Column(JSON, nullable=True)  # Any custom parameters for this exercise
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    creator = relationship("User") 