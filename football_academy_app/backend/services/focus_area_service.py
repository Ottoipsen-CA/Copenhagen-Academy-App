from sqlalchemy.orm import Session
from models.focus_area import FocusArea
from schemas.focus_area import FocusAreaCreate, FocusAreaUpdate
from typing import List, Optional

class FocusAreaService:
    def __init__(self, db: Session):
        self.db = db

    def create(self, focus_area: FocusAreaCreate) -> FocusArea:
        db_focus_area = FocusArea(**focus_area.model_dump())
        self.db.add(db_focus_area)
        self.db.commit()
        self.db.refresh(db_focus_area)
        return db_focus_area

    def get_by_id(self, focus_area_id: int) -> Optional[FocusArea]:
        return self.db.query(FocusArea).filter(FocusArea.id == focus_area_id).first()

    def get_by_plan_id(self, plan_id: int) -> List[FocusArea]:
        return self.db.query(FocusArea).filter(FocusArea.development_plan_id == plan_id).all()

    def update(self, focus_area_id: int, focus_area: FocusAreaUpdate) -> Optional[FocusArea]:
        db_focus_area = self.get_by_id(focus_area_id)
        if db_focus_area:
            for key, value in focus_area.model_dump(exclude_unset=True).items():
                setattr(db_focus_area, key, value)
            self.db.commit()
            self.db.refresh(db_focus_area)
        return db_focus_area

    def delete(self, focus_area_id: int) -> bool:
        db_focus_area = self.get_by_id(focus_area_id)
        if db_focus_area:
            self.db.delete(db_focus_area)
            self.db.commit()
            return True
        return False 