from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

import models
import schemas
import auth
from database import get_db

router = APIRouter(
    prefix="/training-days",
    tags=["training days"],
    responses={404: {"description": "Not found"}},
)

# Create a training day (coach only)
@router.post("/", response_model=schemas.TrainingDay)
async def create_training_day(
    training_day: schemas.TrainingDayCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create training days"
        )
    
    db_training_day = models.TrainingDay(
        **training_day.dict(),
        created_by=current_user.id
    )
    db.add(db_training_day)
    db.commit()
    db.refresh(db_training_day)
    
    # Automatically create entries for all active players
    players = db.query(models.User).filter(
        models.User.is_active == True,
        models.User.is_coach == False
    ).all()
    
    for player in players:
        db_entry = models.TrainingDayEntry(
            training_day_id=db_training_day.id,
            user_id=player.id,
            attendance_status="pending"
        )
        db.add(db_entry)
    
    db.commit()
    return db_training_day

# Get all training days
@router.get("/", response_model=List[schemas.TrainingDay])
async def get_training_days(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    training_days = db.query(models.TrainingDay).offset(skip).limit(limit).all()
    return training_days

# Get a specific training day
@router.get("/{training_day_id}", response_model=schemas.TrainingDay)
async def get_training_day(
    training_day_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    training_day = db.query(models.TrainingDay).filter(models.TrainingDay.id == training_day_id).first()
    if training_day is None:
        raise HTTPException(status_code=404, detail="Training day not found")
    return training_day

# Update a training day (coach only)
@router.put("/{training_day_id}", response_model=schemas.TrainingDay)
async def update_training_day(
    training_day_id: int,
    training_day: schemas.TrainingDayCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update training days"
        )
    
    db_training_day = db.query(models.TrainingDay).filter(models.TrainingDay.id == training_day_id).first()
    if db_training_day is None:
        raise HTTPException(status_code=404, detail="Training day not found")
    
    # Update training day attributes
    for key, value in training_day.dict().items():
        setattr(db_training_day, key, value)
    
    db_training_day.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_training_day)
    return db_training_day

# Delete a training day (coach only)
@router.delete("/{training_day_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_training_day(
    training_day_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete training days"
        )
    
    db_training_day = db.query(models.TrainingDay).filter(models.TrainingDay.id == training_day_id).first()
    if db_training_day is None:
        raise HTTPException(status_code=404, detail="Training day not found")
    
    # Delete associated entries first
    db.query(models.TrainingDayEntry).filter(
        models.TrainingDayEntry.training_day_id == training_day_id
    ).delete()
    
    db.delete(db_training_day)
    db.commit()
    return {"status": "success"}

# --- Training Day Entries ---

# Get all entries for a training day (coach only)
@router.get("/entries/day/{training_day_id}", response_model=List[schemas.TrainingDayEntry])
async def get_training_day_entries(
    training_day_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can view all entries"
        )
    
    entries = db.query(models.TrainingDayEntry).filter(
        models.TrainingDayEntry.training_day_id == training_day_id
    ).all()
    
    return entries

# Get all entries for current user
@router.get("/entries/user/", response_model=List[schemas.TrainingDayEntry])
async def get_user_entries(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    entries = db.query(models.TrainingDayEntry).filter(
        models.TrainingDayEntry.user_id == current_user.id
    ).all()
    
    return entries

# Update a training day entry pre-session notes (player)
@router.put("/entries/{entry_id}/pre", response_model=schemas.TrainingDayEntry)
async def update_pre_session_notes(
    entry_id: int,
    pre_notes: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_entry = db.query(models.TrainingDayEntry).filter(
        models.TrainingDayEntry.id == entry_id,
        models.TrainingDayEntry.user_id == current_user.id
    ).first()
    
    if db_entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Training day entry not found or doesn't belong to you"
        )
    
    db_entry.pre_session_notes = pre_notes
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    return db_entry

# Update a training day entry post-session notes (player)
@router.put("/entries/{entry_id}/post", response_model=schemas.TrainingDayEntry)
async def update_post_session_notes(
    entry_id: int,
    post_notes: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_entry = db.query(models.TrainingDayEntry).filter(
        models.TrainingDayEntry.id == entry_id,
        models.TrainingDayEntry.user_id == current_user.id
    ).first()
    
    if db_entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Training day entry not found or doesn't belong to you"
        )
    
    db_entry.post_session_notes = post_notes
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    return db_entry

# Update attendance status (coach only)
@router.put("/entries/{entry_id}/attendance", response_model=schemas.TrainingDayEntry)
async def update_attendance_status(
    entry_id: int,
    attendance_status: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update attendance status"
        )
    
    if attendance_status not in ["pending", "attended", "missed"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid attendance status. Must be one of: pending, attended, missed"
        )
    
    db_entry = db.query(models.TrainingDayEntry).filter(
        models.TrainingDayEntry.id == entry_id
    ).first()
    
    if db_entry is None:
        raise HTTPException(status_code=404, detail="Training day entry not found")
    
    db_entry.attendance_status = attendance_status
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    return db_entry 