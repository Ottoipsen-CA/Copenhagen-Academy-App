from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class TrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(Integer, primary_key=True, index=True)
    development_plan_id = Column(Integer, ForeignKey("development_plans.id"), nullable=False)
    title = Column(String(255), nullable=False)
    weekday = Column(Integer, nullable=False)  # 1-7 representing Monday-Sunday
    start_time = Column(String(8), nullable=False)  # Format: HH:MM:SS
    duration_minutes = Column(Integer, nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    development_plan = relationship("DevelopmentPlan", back_populates="training_sessions") 