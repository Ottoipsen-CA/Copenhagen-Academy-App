from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

class TrainingPlan(Base):
    __tablename__ = "training_plans"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    difficulty_level = Column(String, index=True)  # beginner, intermediate, advanced
    focus_area = Column(String, index=True)  # e.g., "technical", "physical", "tactical"
    duration_weeks = Column(Integer, default=1)
    created_by = Column(Integer, ForeignKey("users.id"))
    is_public = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    creator = relationship("User", foreign_keys=[created_by])
    training_days = relationship("TrainingDay", back_populates="training_plan")

class TrainingDay(Base):
    __tablename__ = "training_days"

    id = Column(Integer, primary_key=True, index=True)
    training_plan_id = Column(Integer, ForeignKey("training_plans.id"))
    day_number = Column(Integer)
    title = Column(String)
    description = Column(String, nullable=True)
    focus = Column(String, nullable=True)  # e.g., "passing", "shooting", "endurance"
    duration_minutes = Column(Integer, default=60)
    intensity = Column(String, nullable=True)  # low, medium, high
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    training_plan = relationship("TrainingPlan", back_populates="training_days")
    exercises = relationship("TrainingDayEntry", back_populates="training_day")

class TrainingDayEntry(Base):
    __tablename__ = "training_day_entries"

    id = Column(Integer, primary_key=True, index=True)
    training_day_id = Column(Integer, ForeignKey("training_days.id"))
    exercise_id = Column(Integer, ForeignKey("exercise_library.id"))
    order = Column(Integer)
    sets = Column(Integer, nullable=True)
    reps = Column(Integer, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    notes = Column(String, nullable=True)
    custom_parameters = Column(JSON, nullable=True)  # For any exercise-specific parameters
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    training_day = relationship("TrainingDay", back_populates="exercises")
    exercise = relationship("ExerciseLibrary") 