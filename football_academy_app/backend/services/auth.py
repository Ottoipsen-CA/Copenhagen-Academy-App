from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer

from models.users import User
from schemas.auth import UserCreate, UserUpdate, TokenData
from .base import BaseService
from database import get_db

SECRET_KEY = "YOUR_SECRET_KEY_HERE"  # In production, use a proper secret key and store it securely
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v2/auth/token")

class AuthService(BaseService[User, UserCreate, UserUpdate, User]):
    def __init__(self, db: Session):
        super().__init__(model=User, db=db)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        return pwd_context.verify(plain_password, hashed_password)
    
    def get_password_hash(self, password: str) -> str:
        return pwd_context.hash(password)
    
    def get_user_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()
    
    def get_by_id(self, id: int) -> Optional[User]:
        return self.db.query(User).filter(User.user_id == id).first()
    
    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        user = self.get_user_by_email(email)
        if not user:
            return None
        if not self.verify_password(password, user.hashed_password):
            return None
        return user
    
    def create_access_token(self, data: dict, expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    
    def create_user(self, user: UserCreate) -> User:
        if self.get_user_by_email(user.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        hashed_password = self.get_password_hash(user.password)
        db_user = User(
            email=user.email,
            hashed_password=hashed_password,
            full_name=user.full_name,
            position=user.position,
            current_club=user.current_club,
            date_of_birth=user.date_of_birth,
            is_active=user.is_active,
            is_coach=user.is_coach,
            role=user.role
        )
        
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def update_user(self, user_id: int, user_update: UserUpdate) -> User:
        db_user = self.get_by_id(user_id)
        if not db_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        update_data = user_update.dict(exclude_unset=True)
        
        if "password" in update_data and update_data["password"]:
            update_data["hashed_password"] = self.get_password_hash(update_data.pop("password"))
        elif "password" in update_data: # Handle case where password is None or empty string
            del update_data["password"]

        for field, value in update_data.items():
            if hasattr(db_user, field):
                setattr(db_user, field, value)
        
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def update_last_login(self, user_id: int) -> Optional[User]: # Made return optional
        db_user = self.get_by_id(user_id)
        if not db_user:
            # Log this? Or raise? For now, just return None
            return None 
        
        db_user.last_login = datetime.utcnow()
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def get_current_user(self, token: str) -> Optional[User]: # Made return optional
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id: int = payload.get("user_id") # Use user_id instead of email for lookup
            if user_id is None:
                raise credentials_exception
            # We don't need TokenData here if we have user_id
        except JWTError:
            raise credentials_exception
        
        user = self.get_by_id(id=user_id) # Use get_by_id
        if user is None:
            raise credentials_exception
        return user 

# Dependency function to get the current user
def get_current_user_dependency(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("user_id")
        if user_id is None:
            raise credentials_exception
        token_data = TokenData(user_id=user_id) # We might not need TokenData schema here, but can keep for clarity
    except JWTError:
        raise credentials_exception
    
    auth_service = AuthService(db)
    user = auth_service.get_by_id(id=token_data.user_id) # Use get_by_id from BaseService via AuthService
    if user is None:
        raise credentials_exception
    return user

# Dependency function to get the current active user (optional, if needed)
# def get_current_active_user_dependency(current_user: User = Depends(get_current_user_dependency)) -> User:
#     if not current_user.is_active:
#         raise HTTPException(status_code=400, detail="Inactive user")
#     return current_user 