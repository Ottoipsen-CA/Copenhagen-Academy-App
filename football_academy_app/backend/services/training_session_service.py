from sqlalchemy.orm import Session
from models.training_session import TrainingSession
from schemas.training_session import TrainingSessionCreate, TrainingSessionUpdate
from typing import List, Optional

class TrainingSessionService:
    def __init__(self, db: Session):
        self.db = db

    def create(self, session: TrainingSessionCreate) -> TrainingSession:
        db_session = TrainingSession(**session.model_dump())
        self.db.add(db_session)
        self.db.commit()
        self.db.refresh(db_session)
        return db_session

    def get_by_id(self, session_id: int) -> Optional[TrainingSession]:
        return self.db.query(TrainingSession).filter(TrainingSession.id == session_id).first()

    def get_by_plan_id(self, plan_id: int) -> List[TrainingSession]:
        return self.db.query(TrainingSession).filter(TrainingSession.development_plan_id == plan_id).all()

    def update(self, session_id: int, session: TrainingSessionUpdate) -> Optional[TrainingSession]:
        db_session = self.get_by_id(session_id)
        if db_session:
            for key, value in session.model_dump(exclude_unset=True).items():
                setattr(db_session, key, value)
            self.db.commit()
            self.db.refresh(db_session)
        return db_session

    def delete(self, session_id: int) -> bool:
        db_session = self.get_by_id(session_id)
        if db_session:
            self.db.delete(db_session)
            self.db.commit()
            return True
        return False 