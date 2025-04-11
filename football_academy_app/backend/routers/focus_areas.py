from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas.focus_areas import FocusArea, FocusAreaCreate, FocusAreaUpdate
from services.focus_areas import FocusAreasService

router = APIRouter(
    prefix="/{development_plan_id}/focus-areas",
    tags=["focus-areas"]
)

@router.get("/", response_model=List[FocusArea])
def get_plan_focus_areas(development_plan_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    service = FocusAreasService(db)
    return service.get_plan_focus_areas(development_plan_id)

@router.get("/{focus_area_id}", response_model=FocusArea)
def get_focus_area(development_plan_id: int, focus_area_id: int, db: Session = Depends(get_db)):
    service = FocusAreasService(db)
    focus_area = service.get_focus_area_by_id(focus_area_id)
    if not focus_area or focus_area.development_plan_id != development_plan_id:
        raise HTTPException(status_code=404, detail="Focus area not found")
    return focus_area

@router.post("/", response_model=FocusArea, status_code=status.HTTP_201_CREATED)
def create_focus_area(development_plan_id: int, focus_area: FocusAreaCreate, db: Session = Depends(get_db)):
    if focus_area.development_plan_id != development_plan_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Development plan ID mismatch"
        )
    service = FocusAreasService(db)
    return service.create_focus_area(focus_area)

@router.put("/{focus_area_id}", response_model=FocusArea)
def update_focus_area(
    development_plan_id: int, 
    focus_area_id: int, 
    focus_area: FocusAreaUpdate, 
    db: Session = Depends(get_db)
):
    service = FocusAreasService(db)
    existing_focus_area = service.get_focus_area_by_id(focus_area_id)
    if not existing_focus_area or existing_focus_area.development_plan_id != development_plan_id:
        raise HTTPException(status_code=404, detail="Focus area not found")
    
    return service.update_focus_area(focus_area_id, focus_area)

@router.patch("/{focus_area_id}/status", response_model=FocusArea)
def update_focus_area_status(
    development_plan_id: int,
    focus_area_id: int,
    status: str,
    db: Session = Depends(get_db)
):
    service = FocusAreasService(db)
    existing_focus_area = service.get_focus_area_by_id(focus_area_id)
    if not existing_focus_area or existing_focus_area.development_plan_id != development_plan_id:
        raise HTTPException(status_code=404, detail="Focus area not found")
    
    return service.update_focus_area_status(focus_area_id, status)

@router.delete("/{focus_area_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_focus_area(development_plan_id: int, focus_area_id: int, db: Session = Depends(get_db)):
    service = FocusAreasService(db)
    existing_focus_area = service.get_focus_area_by_id(focus_area_id)
    if not existing_focus_area or existing_focus_area.development_plan_id != development_plan_id:
        raise HTTPException(status_code=404, detail="Focus area not found")
    
    if not service.delete_focus_area(focus_area_id):
        raise HTTPException(status_code=404, detail="Focus area not found")
    return None 