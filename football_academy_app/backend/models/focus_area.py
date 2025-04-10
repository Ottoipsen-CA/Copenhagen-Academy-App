from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, Date
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class FocusArea(Base):
    __tablename__ = "focus_areas"

    id = Column(Integer, primary_key=True, index=True)
    development_plan_id = Column(Integer, ForeignKey("development_plans.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    target_date = Column(Date, nullable=False)
    is_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    development_plan = relationship("DevelopmentPlan", back_populates="focus_areas") 