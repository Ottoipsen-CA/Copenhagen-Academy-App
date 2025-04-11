from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional

from models.focus_areas import FocusArea
from schemas.focus_areas import FocusAreaCreate, FocusAreaUpdate
from .base import BaseService

class FocusAreasService:
    def __init__(self, db: Session):
        self.db = db
        self.focus_area_service = BaseService[FocusArea, FocusAreaCreate, FocusAreaUpdate, FocusArea](
            FocusArea, db
        )

    def get_all_focus_areas(self, skip: int = 0, limit: int = 100) -> List[FocusArea]:
        return self.focus_area_service.get_all(skip=skip, limit=limit)

    def get_focus_area_by_id(self, focus_area_id: int) -> Optional[FocusArea]:
        return self.focus_area_service.get_by_id(focus_area_id)

    def get_plan_focus_areas(self, development_plan_id: int) -> List[FocusArea]:
        return self.db.query(FocusArea).filter(FocusArea.development_plan_id == development_plan_id).all()

    def create_focus_area(self, focus_area: FocusAreaCreate) -> FocusArea:
        return self.focus_area_service.create(focus_area)

    def update_focus_area(self, focus_area_id: int, focus_area: FocusAreaUpdate) -> FocusArea:
        return self.focus_area_service.update(focus_area_id, focus_area)

    def delete_focus_area(self, focus_area_id: int) -> bool:
        return self.focus_area_service.delete(focus_area_id)

    def update_focus_area_status(self, focus_area_id: int, status: str) -> FocusArea:
        focus_area = self.get_focus_area_by_id(focus_area_id)
        if not focus_area:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Focus area not found"
            )
        
        update_data = {"status": status}
        return self.focus_area_service.update(focus_area_id, update_data) 