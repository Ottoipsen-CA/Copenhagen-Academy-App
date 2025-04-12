from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from database import get_db
from schemas.training_schedules import (
    TrainingSchedule, 
    TrainingScheduleCreate, 
    TrainingScheduleUpdate,
    TrainingSession,
    TrainingSessionCreate,
    TrainingSessionUpdate,
    TrainingSessionReflection
)
from services.training_schedules import TrainingScheduleService

router = APIRouter(
    prefix="/training-schedules",
    tags=["training-schedules"]
)

# Training Schedule Routes
@router.get("/", response_model=List[TrainingSchedule])
def get_all_schedules(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    return service.get_all_schedules(skip=skip, limit=limit)

@router.get("/user/{user_id}", response_model=List[TrainingSchedule])
def get_user_schedules(user_id: int, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    return service.get_user_schedules(user_id)

@router.get("/week", response_model=TrainingSchedule)
def get_schedule_by_week(
    user_id: int,
    week: int,
    year: int = datetime.now().year,
    db: Session = Depends(get_db)
):
    service = TrainingScheduleService(db)
    schedule = service.get_schedules_by_week(user_id, week, year)
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found for this week")
    return schedule

@router.get("/{schedule_id}", response_model=TrainingSchedule)
def get_schedule(schedule_id: int, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    schedule = service.get_schedule_by_id(schedule_id)
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")
    return schedule

@router.post("/", response_model=TrainingSchedule, status_code=status.HTTP_201_CREATED)
def create_schedule(schedule: TrainingScheduleCreate, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    return service.create_schedule(schedule)

@router.put("/{schedule_id}", response_model=TrainingSchedule)
def update_schedule(schedule_id: int, schedule: TrainingScheduleUpdate, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    updated_schedule = service.update_schedule(schedule_id, schedule)
    if not updated_schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")
    return updated_schedule

@router.delete("/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_schedule(schedule_id: int, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    if not service.delete_schedule(schedule_id):
        raise HTTPException(status_code=404, detail="Schedule not found")
    return None

# Training Session Routes
@router.get("/{schedule_id}/sessions", response_model=List[TrainingSession])
def get_sessions(schedule_id: int, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    return service.get_sessions_by_schedule(schedule_id)

@router.get("/sessions/{session_id}", response_model=TrainingSession)
def get_session(session_id: int, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    session = service.get_session_by_id(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")
    return session

@router.post("/sessions", response_model=TrainingSession, status_code=status.HTTP_201_CREATED)
def create_session(session: TrainingSessionCreate, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    return service.create_session(session)

@router.put("/sessions/{session_id}", response_model=TrainingSession)
def update_session(session_id: int, session: TrainingSessionUpdate, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    updated_session = service.update_session(session_id, session)
    if not updated_session:
        raise HTTPException(status_code=404, detail="Training session not found")
    return updated_session

@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session(session_id: int, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    if not service.delete_session(session_id):
        raise HTTPException(status_code=404, detail="Training session not found")
    return None

@router.post("/sessions/{session_id}/reflection", response_model=TrainingSession)
def add_reflection(session_id: int, reflection: TrainingSessionReflection, db: Session = Depends(get_db)):
    service = TrainingScheduleService(db)
    return service.add_reflection(session_id, reflection) 