from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Date
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

class FocusArea(Base):
    __tablename__ = "focus_areas"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    development_plan_id = Column(Integer, ForeignKey("development_plans.id"))
    priority = Column(Integer, default=0)  # To order focus areas by importance
    status = Column(String, default="not_started")  # e.g., "not_started", "in_progress", "completed"
    target_date = Column(Date, nullable=True)  # When this focus area should be completed
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    development_plan = relationship("DevelopmentPlan", back_populates="focus_areas") 