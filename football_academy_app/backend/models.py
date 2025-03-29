from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Float, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    position = Column(String)
    current_club = Column(String)
    date_of_birth = Column(DateTime)
    is_active = Column(Boolean, default=True)
    is_coach = Column(Boolean, default=False)
    
    # Relationships
    training_plans = relationship("TrainingPlan", back_populates="player")
    achievements = relationship("Achievement", back_populates="player")
    stats = relationship("PlayerStats", back_populates="player", uselist=False)

class TrainingPlan(Base):
    __tablename__ = "training_plans"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    player = relationship("User", back_populates="training_plans")
    exercises = relationship("Exercise", back_populates="training_plan")

class Exercise(Base):
    __tablename__ = "exercises"

    id = Column(Integer, primary_key=True, index=True)
    training_plan_id = Column(Integer, ForeignKey("training_plans.id"))
    title = Column(String)
    description = Column(Text)
    video_url = Column(String)
    duration = Column(Integer)  # in minutes
    difficulty = Column(String)
    category = Column(String)
    
    # Relationships
    training_plan = relationship("TrainingPlan", back_populates="exercises")

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    description = Column(Text)
    earned_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    player = relationship("User", back_populates="achievements")

class PlayerStats(Base):
    __tablename__ = "player_stats"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"), unique=True)
    pace = Column(Float, default=50)
    shooting = Column(Float, default=50)
    passing = Column(Float, default=50)
    dribbling = Column(Float, default=50)
    defense = Column(Float, default=50)
    physical = Column(Float, default=50)
    overall_rating = Column(Float, default=50)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    player = relationship("User", back_populates="stats") 
    class Challenge(Base):
    __tablename__ = "challenges"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    xp_reward = Column(Integer, default=0)
    category = Column(String)
    is_weekly = Column(Boolean, default=False)

    # Relationships
    user_challenges = relationship("UserChallenge", back_populates="challenge")


class UserChallenge(Base):
    __tablename__ = "user_challenges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    challenge_id = Column(Integer, ForeignKey("challenges.id"))
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User")
    challenge = relationship("Challenge", back_populates="user_challenges")

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    position = Column(String)
    current_club = Column(String)
    date_of_birth = Column(DateTime)
    is_active = Column(Boolean, default=True)
    is_coach = Column(Boolean, default=False)

    # Relationships
    training_plans = relationship("TrainingPlan", back_populates="player")
    achievements = relationship("Achievement", back_populates="player")
    stats = relationship("PlayerStats", back_populates="player", uselist=False)

    challenges = relationship("UserChallenge", back_populates="user")
    badges = relationship("UserBadge", back_populates="user")
