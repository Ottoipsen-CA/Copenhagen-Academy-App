from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Enum, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from database import Base

class ChallengeStatus(enum.Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    EXPIRED = "expired"

class Challenge(Base):
    __tablename__ = "challenges"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    category = Column(String, index=True)  # e.g., "technical", "physical", "tactical"
    difficulty = Column(String, index=True)  # e.g., "beginner", "intermediate", "advanced"
    points = Column(Integer, default=100)
    criteria = Column(JSON)  # JSON object containing success criteria
    start_date = Column(DateTime, default=datetime.utcnow)
    end_date = Column(DateTime, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)
    badge_id = Column(Integer, ForeignKey("badges.id"), nullable=True)
    
    # Relationships
    badge = relationship("Badge", back_populates="challenges")
    completions = relationship("ChallengeCompletion", back_populates="challenge")

class ChallengeCompletion(Base):
    __tablename__ = "challenge_completions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    challenge_id = Column(Integer, ForeignKey("challenges.id"))
    status = Column(Enum(ChallengeStatus), default=ChallengeStatus.ACTIVE)
    progress = Column(Float, default=0.0)  # Percentage of completion
    completed_at = Column(DateTime, nullable=True)
    verified_by = Column(Integer, ForeignKey("users.id"), nullable=True)  # Coach ID if verified by coach
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    coach = relationship("User", foreign_keys=[verified_by])
    challenge = relationship("Challenge", back_populates="completions")

class Badge(Base):
    __tablename__ = "badges"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    image_url = Column(String)
    criteria = Column(String)
    created_at = Column(DateTime, default=func.now())
    
    # Relationships
    challenges = relationship("Challenge", back_populates="badge")
    achievements = relationship("Achievement", back_populates="badge")

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    badge_id = Column(Integer, ForeignKey("badges.id"))
    earned_at = Column(DateTime, default=func.now())
    awarded_by = Column(Integer, ForeignKey("users.id"), nullable=True)  # Coach ID if awarded by coach
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    coach = relationship("User", foreign_keys=[awarded_by])
    badge = relationship("Badge", back_populates="achievements") 