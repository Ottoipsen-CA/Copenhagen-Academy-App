from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional
from datetime import datetime

from models.training_schedules import TrainingSchedule, TrainingSession
from schemas.training_schedules import (
    TrainingScheduleCreate, 
    TrainingScheduleUpdate,
    TrainingSessionCreate,
    TrainingSessionUpdate,
    TrainingSessionReflection
)
from .base import BaseService

class TrainingScheduleService:
    def __init__(self, db: Session):
        self.db = db
        self.schedule_service = BaseService[TrainingSchedule, TrainingScheduleCreate, TrainingScheduleUpdate, TrainingSchedule](
            TrainingSchedule, db
        )
        self.session_service = BaseService[TrainingSession, TrainingSessionCreate, TrainingSessionUpdate, TrainingSession](
            TrainingSession, db
        )

    # Training Schedule methods
    def get_all_schedules(self, skip: int = 0, limit: int = 100) -> List[TrainingSchedule]:
        return self.schedule_service.get_all(skip=skip, limit=limit)

    def get_schedule_by_id(self, schedule_id: int) -> Optional[TrainingSchedule]:
        return self.schedule_service.get_by_id(schedule_id)

    def get_user_schedules(self, user_id: int) -> List[TrainingSchedule]:
        return self.db.query(TrainingSchedule).filter(TrainingSchedule.user_id == user_id).all()

    def get_schedules_by_week(self, user_id: int, week_number: int, year: int) -> Optional[TrainingSchedule]:
        return self.db.query(TrainingSchedule).filter(
            TrainingSchedule.user_id == user_id,
            TrainingSchedule.week_number == week_number,
            TrainingSchedule.year == year
        ).first()

    def create_schedule(self, schedule: TrainingScheduleCreate) -> TrainingSchedule:
        # Check if a schedule already exists for this week/year
        existing = self.get_schedules_by_week(
            schedule.user_id, 
            schedule.week_number, 
            schedule.year
        )
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"A training schedule already exists for week {schedule.week_number}/{schedule.year}"
            )
            
        return self.schedule_service.create(schedule)

    def update_schedule(self, schedule_id: int, schedule: TrainingScheduleUpdate) -> TrainingSchedule:
        return self.schedule_service.update(schedule_id, schedule)

    def delete_schedule(self, schedule_id: int) -> bool:
        return self.schedule_service.delete(schedule_id)

    # Training Session methods
    def get_sessions_by_schedule(self, schedule_id: int) -> List[TrainingSession]:
        return self.db.query(TrainingSession).filter(TrainingSession.schedule_id == schedule_id).all()

    def get_session_by_id(self, session_id: int) -> Optional[TrainingSession]:
        return self.session_service.get_by_id(session_id)

    def create_session(self, session: TrainingSessionCreate) -> TrainingSession:
        return self.session_service.create(session)

    def update_session(self, session_id: int, session: TrainingSessionUpdate) -> TrainingSession:
        return self.session_service.update(session_id, session)

    def delete_session(self, session_id: int) -> bool:
        return self.session_service.delete(session_id)
        
    def add_reflection(self, session_id: int, reflection: TrainingSessionReflection) -> TrainingSession:
        session = self.get_session_by_id(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Training session not found")
            
        session.reflection_text = reflection.reflection_text
        session.has_reflection = True
        session.reflection_added_at = datetime.now()
        
        self.db.commit()
        self.db.refresh(session)
        return session 