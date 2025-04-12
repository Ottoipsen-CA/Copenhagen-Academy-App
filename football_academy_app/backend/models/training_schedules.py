from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Time, Date, Text, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime, date, time

from database import Base

class TrainingSchedule(Base):
    __tablename__ = "training_schedules"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    development_plan_id = Column(Integer, ForeignKey("development_plans.id"), nullable=True)
    week_number = Column(Integer, index=True)
    year = Column(Integer, index=True)
    title = Column(String, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="training_schedules")
    development_plan = relationship("DevelopmentPlan", back_populates="training_schedules")
    training_sessions = relationship("TrainingSession", back_populates="schedule", cascade="all, delete-orphan")

class TrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(Integer, primary_key=True, index=True)
    schedule_id = Column(Integer, ForeignKey("training_schedules.id"))
    day_of_week = Column(Integer)  # 1-7 for Monday-Sunday
    session_date = Column(Date, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    location = Column(String, nullable=True)
    focus_area_id = Column(Integer, ForeignKey("focus_areas.id"), nullable=True)
    has_reflection = Column(Boolean, default=False)
    reflection_text = Column(Text, nullable=True)
    reflection_added_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    schedule = relationship("TrainingSchedule", back_populates="training_sessions")
    focus_area = relationship("FocusArea", backref="training_sessions") 