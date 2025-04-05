from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import sys
import os

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

router = APIRouter(
    prefix="/achievements",
    tags=["achievements"]
)

@router.post("/", response_model=schemas.Achievement)
def create_achievement(
    achievement: schemas.AchievementCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify player ownership
    if achievement.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db_achievement = models.Achievement(**achievement.dict())
    db.add(db_achievement)
    db.commit()
    db.refresh(db_achievement)
    return db_achievement

@router.get("/", response_model=List[schemas.Achievement])
def read_achievements(
    player_id: int,
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify access rights
    if player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    achievements = db.query(models.Achievement).filter(
        models.Achievement.player_id == player_id
    ).offset(skip).limit(limit).all()
    return achievements

@router.get("/{achievement_id}", response_model=schemas.Achievement)
def read_achievement(
    achievement_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    achievement = db.query(models.Achievement).filter(
        models.Achievement.id == achievement_id
    ).first()
    if achievement is None:
        raise HTTPException(status_code=404, detail="Achievement not found")
    
    # Verify access rights
    if achievement.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    return achievement

@router.delete("/{achievement_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_achievement(
    achievement_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    achievement = db.query(models.Achievement).filter(
        models.Achievement.id == achievement_id
    ).first()
    if achievement is None:
        raise HTTPException(status_code=404, detail="Achievement not found")
    
    # Verify access rights
    if achievement.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db.delete(achievement)
    db.commit()
    return None 