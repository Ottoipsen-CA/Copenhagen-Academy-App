from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List
import sys
import os
import logging

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

# Set up logger
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/users",
    tags=["users"]
)

@router.post("/", response_model=schemas.User)
async def create_user(user: schemas.UserCreate, db: Session = Depends(get_db), request: Request = None):
    try:
        # Log the registration attempt
        logger.info(f"Registration attempt for email: {user.email}")
        if request:
            body = await request.body()
            logger.info(f"Raw request body: {body}")
            logger.info(f"Request headers: {request.headers}")
        
        # Log all incoming data
        logger.info(f"User data: {user.dict()}")
        
        # Check if email is already registered
        db_user = db.query(models.User).filter(models.User.email == user.email).first()
        if db_user:
            logger.warning(f"Email already registered: {user.email}")
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Hash the password
        hashed_password = auth.get_password_hash(user.password)
        
        # Create the user object
        db_user = models.User(
            email=user.email,
            hashed_password=hashed_password,
            full_name=user.full_name,
            position=user.position,
            current_club=user.current_club,
            date_of_birth=user.date_of_birth
        )
        
        # Save to database
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        logger.info(f"User registered successfully: {user.email}")
        return db_user
    except Exception as e:
        logger.error(f"Error registering user: {str(e)}")
        # Log the complete error with traceback
        import traceback
        logger.error(traceback.format_exc())
        raise

@router.get("/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(auth.get_current_active_user)):
    return current_user

@router.get("/{user_id}", response_model=schemas.User)
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@router.put("/me", response_model=schemas.User)
def update_user(
    user_update: schemas.UserBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    for field, value in user_update.dict().items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db.delete(current_user)
    db.commit()
    return None 