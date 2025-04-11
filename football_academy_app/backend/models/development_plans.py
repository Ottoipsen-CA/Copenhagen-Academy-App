from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

class DevelopmentPlan(Base):
    __tablename__ = "development_plans"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    long_term_goals = Column(String)
    notes = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="development_plans") 