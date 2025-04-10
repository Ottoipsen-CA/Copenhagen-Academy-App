from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from services.focus_area_service import FocusAreaService
from schemas.focus_area import FocusAreaCreate, FocusAreaUpdate, FocusAreaResponse

router = APIRouter(prefix="/focus-areas", tags=["focus_areas"])

@router.post("/", response_model=FocusAreaResponse)
def create_focus_area(focus_area: FocusAreaCreate, db: Session = Depends(get_db)):
    service = FocusAreaService(db)
    return service.create(focus_area)

@router.get("/", response_model=List[FocusAreaResponse])
def get_focus_areas(plan_id: int, db: Session = Depends(get_db)):
    service = FocusAreaService(db)
    return service.get_by_plan_id(plan_id)

@router.get("/{focus_area_id}", response_model=FocusAreaResponse)
def get_focus_area(focus_area_id: int, db: Session = Depends(get_db)):
    service = FocusAreaService(db)
    focus_area = service.get_by_id(focus_area_id)
    if not focus_area:
        raise HTTPException(status_code=404, detail="Focus area not found")
    return focus_area

@router.put("/{focus_area_id}", response_model=FocusAreaResponse)
def update_focus_area(focus_area_id: int, focus_area: FocusAreaUpdate, db: Session = Depends(get_db)):
    service = FocusAreaService(db)
    updated_focus_area = service.update(focus_area_id, focus_area)
    if not updated_focus_area:
        raise HTTPException(status_code=404, detail="Focus area not found")
    return updated_focus_area

@router.delete("/{focus_area_id}")
def delete_focus_area(focus_area_id: int, db: Session = Depends(get_db)):
    service = FocusAreaService(db)
    if not service.delete(focus_area_id):
        raise HTTPException(status_code=404, detail="Focus area not found")
    return {"message": "Focus area deleted successfully"} 