from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

# -----------------------------
# Player Stats
# -----------------------------
class PlayerStats(Base):
    __tablename__ = "player_stats"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("users.id"))
    pace = Column(Integer)
    shooting = Column(Integer)
    passing = Column(Integer)
    dribbling = Column(Integer)
    juggles = Column(Integer)
    first_touch = Column(Integer)
    overall_rating = Column(Integer)
    last_updated = Column(DateTime, default=datetime.utcnow)

    player = relationship("User", back_populates="stats")


# -----------------------------
# Challenge
# -----------------------------
class Challenge(Base):
    __tablename__ = "challenges"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    xp_reward = Column(Integer, default=0)
    category = Column(String)
    is_weekly = Column(Boolean, default=False)
    level = Column(Integer, default=1)
    prerequisite_id = Column(Integer, ForeignKey("challenges.id"), nullable=True)

    user_challenges = relationship("UserChallenge", back_populates="challenge")
    prerequisite = relationship("Challenge", remote_side=[id], backref="next_challenges", uselist=False)


# -----------------------------
# ChallengeStatus - new model to track user challenge status
# -----------------------------
class ChallengeStatus(Base):
    __tablename__ = "challenge_statuses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    challenge_id = Column(Integer, ForeignKey("challenges.id"))
    status = Column(String, default="LOCKED")  # LOCKED, AVAILABLE, COMPLETED
    unlocked_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    
    user = relationship("User", backref="challenge_statuses")
    challenge = relationship("Challenge", backref="statuses")


# -----------------------------
# UserChallenge
# -----------------------------
class UserChallenge(Base):
    __tablename__ = "user_challenges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    challenge_id = Column(Integer, ForeignKey("challenges.id"))
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="user_challenges")
    challenge = relationship("Challenge", back_populates="user_challenges")


# -----------------------------
# UserBadge
# -----------------------------
class UserBadge(Base):
    __tablename__ = "user_badges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    badge_name = Column(String)
    earned_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="badges")


# -----------------------------
# User
# -----------------------------
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

    stats = relationship("PlayerStats", back_populates="player")
    badges = relationship("UserBadge", back_populates="user")
    user_challenges = relationship("UserChallenge", back_populates="user")
