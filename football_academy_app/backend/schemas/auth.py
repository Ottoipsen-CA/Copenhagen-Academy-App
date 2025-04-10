from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime, date
from constants.position_weights import Position

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    position: Optional[Position] = None
    current_club: Optional[str] = None
    date_of_birth: Optional[date] = None
    is_active: bool = True
    is_coach: bool = False
    role: str = "player"  # player, coach, admin

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    password: Optional[str] = None
    full_name: Optional[str] = None
    position: Optional[Position] = None
    current_club: Optional[str] = None
    date_of_birth: Optional[date] = None
    is_active: Optional[bool] = None
    is_coach: Optional[bool] = None
    role: Optional[str] = None

class UserResponse(UserBase):
    id: int
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
    user_id: Optional[int] = None
    exp: Optional[datetime] = None 