from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from services.training_session_service import TrainingSessionService
from schemas.training_session import TrainingSessionCreate, TrainingSessionUpdate, TrainingSessionResponse

router = APIRouter(prefix="/training-sessions", tags=["training_sessions"])

@router.post("/", response_model=TrainingSessionResponse)
def create_training_session(session: TrainingSessionCreate, db: Session = Depends(get_db)):
    service = TrainingSessionService(db)
    return service.create(session)

@router.get("/", response_model=List[TrainingSessionResponse])
def get_training_sessions(plan_id: int, db: Session = Depends(get_db)):
    service = TrainingSessionService(db)
    return service.get_by_plan_id(plan_id)

@router.get("/{session_id}", response_model=TrainingSessionResponse)
def get_training_session(session_id: int, db: Session = Depends(get_db)):
    service = TrainingSessionService(db)
    session = service.get_by_id(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")
    return session

@router.put("/{session_id}", response_model=TrainingSessionResponse)
def update_training_session(session_id: int, session: TrainingSessionUpdate, db: Session = Depends(get_db)):
    service = TrainingSessionService(db)
    updated_session = service.update(session_id, session)
    if not updated_session:
        raise HTTPException(status_code=404, detail="Training session not found")
    return updated_session

@router.delete("/{session_id}")
def delete_training_session(session_id: int, db: Session = Depends(get_db)):
    service = TrainingSessionService(db)
    if not service.delete(session_id):
        raise HTTPException(status_code=404, detail="Training session not found")
    return {"message": "Training session deleted successfully"} 