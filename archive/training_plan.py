from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from models import User, TrainingPlan, TrainingDay, TrainingDayEntry
from database import get_db
from auth import get_current_active_user, get_current_user
from schemas import (
    TrainingPlan as TrainingPlanSchema, 
    TrainingPlanCreate, TrainingPlanBase,
    TrainingDay as TrainingDaySchema,
    TrainingDayCreate, TrainingDayEntry as TrainingDayEntrySchema
)

router = APIRouter(
    prefix="/training",
    tags=["training"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

# -------------- Training Plans Endpoints --------------

@router.post("/plans", response_model=TrainingPlanSchema)
def create_training_plan(
    training_plan: TrainingPlanCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    db_training_plan = TrainingPlan(
        **training_plan.dict(),
        player_id=current_user.id
    )
    db.add(db_training_plan)
    db.commit()
    db.refresh(db_training_plan)
    return db_training_plan

@router.get("/plans", response_model=List[TrainingPlanSchema])
def read_training_plans(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    training_plans = db.query(TrainingPlan).filter(
        TrainingPlan.player_id == current_user.id
    ).offset(skip).limit(limit).all()
    return training_plans

@router.get("/plans/{training_plan_id}", response_model=TrainingPlanSchema)
def read_training_plan(
    training_plan_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    training_plan = db.query(TrainingPlan).filter(
        TrainingPlan.id == training_plan_id,
        TrainingPlan.player_id == current_user.id
    ).first()
    if training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    return training_plan

@router.put("/plans/{training_plan_id}", response_model=TrainingPlanSchema)
def update_training_plan(
    training_plan_id: int,
    training_plan_update: TrainingPlanBase,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    db_training_plan = db.query(TrainingPlan).filter(
        TrainingPlan.id == training_plan_id,
        TrainingPlan.player_id == current_user.id
    ).first()
    if db_training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    for field, value in training_plan_update.dict().items():
        setattr(db_training_plan, field, value)
    
    db.commit()
    db.refresh(db_training_plan)
    return db_training_plan

@router.delete("/plans/{training_plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_training_plan(
    training_plan_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    db_training_plan = db.query(TrainingPlan).filter(
        TrainingPlan.id == training_plan_id,
        TrainingPlan.player_id == current_user.id
    ).first()
    if db_training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    db.delete(db_training_plan)
    db.commit()
    return None

# -------------- Training Days Endpoints --------------

@router.post("/days", response_model=TrainingDaySchema)
async def create_training_day(
    training_day: TrainingDayCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create training days"
        )
    
    db_training_day = TrainingDay(
        **training_day.dict(),
        created_by=current_user.id
    )
    db.add(db_training_day)
    db.commit()
    db.refresh(db_training_day)
    
    # Automatically create entries for all active players
    players = db.query(User).filter(
        User.is_active == True,
        User.is_coach == False
    ).all()
    
    for player in players:
        db_entry = TrainingDayEntry(
            training_day_id=db_training_day.id,
            user_id=player.id,
            attendance_status="pending"
        )
        db.add(db_entry)
    
    db.commit()
    return db_training_day

@router.get("/days", response_model=List[TrainingDaySchema])
async def get_training_days(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    training_days = db.query(TrainingDay).offset(skip).limit(limit).all()
    return training_days

@router.get("/days/{training_day_id}", response_model=TrainingDaySchema)
async def get_training_day(
    training_day_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    training_day = db.query(TrainingDay).filter(TrainingDay.id == training_day_id).first()
    if training_day is None:
        raise HTTPException(status_code=404, detail="Training day not found")
    return training_day

@router.put("/days/{training_day_id}", response_model=TrainingDaySchema)
async def update_training_day(
    training_day_id: int,
    training_day: TrainingDayCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update training days"
        )
    
    db_training_day = db.query(TrainingDay).filter(TrainingDay.id == training_day_id).first()
    if db_training_day is None:
        raise HTTPException(status_code=404, detail="Training day not found")
    
    # Update training day attributes
    for key, value in training_day.dict().items():
        setattr(db_training_day, key, value)
    
    db_training_day.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_training_day)
    return db_training_day

@router.delete("/days/{training_day_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_training_day(
    training_day_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete training days"
        )
    
    db_training_day = db.query(TrainingDay).filter(TrainingDay.id == training_day_id).first()
    if db_training_day is None:
        raise HTTPException(status_code=404, detail="Training day not found")
    
    # Delete associated entries first
    db.query(TrainingDayEntry).filter(
        TrainingDayEntry.training_day_id == training_day_id
    ).delete()
    
    db.delete(db_training_day)
    db.commit()
    return {"status": "success"}

# -------------- Training Day Entries Endpoints --------------

@router.get("/entries/day/{training_day_id}", response_model=List[TrainingDayEntrySchema])
async def get_training_day_entries(
    training_day_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can view all entries"
        )
    
    entries = db.query(TrainingDayEntry).filter(
        TrainingDayEntry.training_day_id == training_day_id
    ).all()
    
    return entries

@router.get("/entries/user", response_model=List[TrainingDayEntrySchema])
async def get_user_entries(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    entries = db.query(TrainingDayEntry).filter(
        TrainingDayEntry.user_id == current_user.id
    ).all()
    
    return entries

@router.put("/entries/{entry_id}/pre", response_model=TrainingDayEntrySchema)
async def update_pre_session_notes(
    entry_id: int,
    pre_notes: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_entry = db.query(TrainingDayEntry).filter(
        TrainingDayEntry.id == entry_id,
        TrainingDayEntry.user_id == current_user.id
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

@router.put("/entries/{entry_id}/post", response_model=TrainingDayEntrySchema)
async def update_post_session_notes(
    entry_id: int,
    post_notes: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_entry = db.query(TrainingDayEntry).filter(
        TrainingDayEntry.id == entry_id,
        TrainingDayEntry.user_id == current_user.id
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

@router.put("/entries/{entry_id}/attendance", response_model=TrainingDayEntrySchema)
async def update_attendance_status(
    entry_id: int,
    attendance_status: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
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
    
    db_entry = db.query(TrainingDayEntry).filter(
        TrainingDayEntry.id == entry_id
    ).first()
    
    if db_entry is None:
        raise HTTPException(status_code=404, detail="Training day entry not found")
    
    db_entry.attendance_status = attendance_status
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    return db_entry 