from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base
from constants.position_weights import Position, POSITION_WEIGHTS

class PlayerStats(Base):
    __tablename__ = "player_stats"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"), unique=True)
    pace = Column(Float, default=50)
    shooting = Column(Float, default=50)
    passing = Column(Float, default=50)
    dribbling = Column(Float, default=50)
    juggles = Column(Float, default=50)
    first_touch = Column(Float, default=50)
    overall_rating = Column(Float, default=50)
    last_updated = Column(DateTime, default=datetime.utcnow)
    
    # Relationship to user for position information
    player = relationship("User", back_populates="stats")
    
    def calculate_overall_rating(self, position: Position) -> float:
        """Calculate overall rating based on position-specific weights"""
        weights = POSITION_WEIGHTS.get(position, POSITION_WEIGHTS[Position.MIDFIELDER])  # Default to midfielder weights
        overall = (
            self.pace * weights["pace"] +
            self.shooting * weights["shooting"] +
            self.passing * weights["passing"] +
            self.dribbling * weights["dribbling"] +
            self.juggles * weights["juggles"] +
            self.first_touch * weights["first_touch"]
        )
        return round(overall, 1)

class Test(Base):
    __tablename__ = "tests"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    category = Column(String, index=True)  # passing, shooting, dribbling, etc.
    difficulty_level = Column(String, index=True)  # easy, medium, hard
    instructions = Column(String)
    points_scale = Column(Float, default=1.0)
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class TestEntry(Base):
    __tablename__ = "test_entries"

    id = Column(Integer, primary_key=True, index=True)
    test_id = Column(Integer, ForeignKey("tests.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    score = Column(Float)
    details = Column(JSON, nullable=True)
    completed_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    test = relationship("Test")
    user = relationship("User")

class PlayerTest(Base):
    __tablename__ = "player_tests"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"))
    test_date = Column(DateTime, default=datetime.utcnow)
    position = Column(String)  # Store the player's position at test time
    
    # Raw test results
    pace = Column(Float)
    shooting = Column(Float)
    passing = Column(Float)
    dribbling = Column(Float)
    juggles = Column(Float)
    first_touch = Column(Float)
    
    # Calculated ratings (1-99 scale)
    pace_rating = Column(Integer)
    shooting_rating = Column(Integer)
    passing_rating = Column(Integer)
    dribbling_rating = Column(Integer)
    juggles_rating = Column(Integer)
    first_touch_rating = Column(Integer)
    overall_rating = Column(Integer)  # Overall rating for this test session
    
    notes = Column(String)
    recorded_by = Column(Integer, ForeignKey("users.id"))
    
    # Relationships
    player = relationship("User", foreign_keys=[player_id], back_populates="tests")
    coach = relationship("User", foreign_keys=[recorded_by], back_populates="recorded_tests") 