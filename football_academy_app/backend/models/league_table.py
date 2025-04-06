from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

class LeagueTableEntry(Base):
    __tablename__ = "league_table"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.user_id"), unique=True)
    points = Column(Integer, default=0)
    challenges_completed = Column(Integer, default=0)
    tests_completed = Column(Integer, default=0)
    average_rating = Column(Float, default=0.0)
    rank = Column(Integer)
    previous_rank = Column(Integer, nullable=True)
    rank_change = Column(Integer, default=0)
    last_updated = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    player = relationship("User")

class ChallengeEntry(Base):
    __tablename__ = "challenge_entries"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.user_id"))
    challenge_id = Column(Integer, ForeignKey("challenges.id"))
    points_earned = Column(Integer, default=0)
    completed_date = Column(DateTime, default=datetime.utcnow)
    included_in_rankings = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    
    # Relationships
    player = relationship("User")
    challenge = relationship("Challenge") 