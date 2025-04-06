from sqlalchemy import Column, Integer, String, Boolean, Date, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base
from constants.position_weights import Position

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    position = Column(String, nullable=True)
    current_club = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    is_active = Column(Boolean, default=True)
    is_coach = Column(Boolean, default=False)
    role = Column(String, default="player")
    created_at = Column(DateTime, default=func.now())
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    stats = relationship("PlayerStats", back_populates="player", uselist=False)
    tests = relationship("PlayerTest", foreign_keys="PlayerTest.player_id", back_populates="player")
    recorded_tests = relationship("PlayerTest", foreign_keys="PlayerTest.recorded_by", back_populates="coach")
    
    @property
    def age(self):
        if self.date_of_birth:
            today = datetime.now().date()
            age = today.year - self.date_of_birth.year
            if today.month < self.date_of_birth.month or (today.month == self.date_of_birth.month and today.day < self.date_of_birth.day):
                age -= 1
            return age
        return None

    @property
    def id(self):
        return self.user_id 