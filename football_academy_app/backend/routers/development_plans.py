from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas.development_plans import DevelopmentPlan, DevelopmentPlanCreate, DevelopmentPlanUpdate
from services.development_plans import DevelopmentPlansService
from . import focus_areas

router = APIRouter(
    prefix="/development-plans",
    tags=["development-plans"]
)

# Include focus areas router
router.include_router(focus_areas.router)

@router.get("/", response_model=List[DevelopmentPlan])
def get_all_plans(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    service = DevelopmentPlansService(db)
    return service.get_all_plans(skip=skip, limit=limit)

@router.get("/{plan_id}", response_model=DevelopmentPlan)
def get_plan(plan_id: int, db: Session = Depends(get_db)):
    service = DevelopmentPlansService(db)
    plan = service.get_plan_by_id(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Development plan not found")
    return plan

@router.get("/user/{user_id}", response_model=List[DevelopmentPlan])
def get_user_plans(user_id: int, db: Session = Depends(get_db)):
    service = DevelopmentPlansService(db)
    return service.get_user_plans(user_id)

@router.post("/", response_model=DevelopmentPlan, status_code=status.HTTP_201_CREATED)
def create_plan(plan: DevelopmentPlanCreate, db: Session = Depends(get_db)):
    service = DevelopmentPlansService(db)
    return service.create_plan(plan)

@router.put("/{plan_id}", response_model=DevelopmentPlan)
def update_plan(plan_id: int, plan: DevelopmentPlanUpdate, db: Session = Depends(get_db)):
    service = DevelopmentPlansService(db)
    updated_plan = service.update_plan(plan_id, plan)
    if not updated_plan:
        raise HTTPException(status_code=404, detail="Development plan not found")
    return updated_plan

@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_plan(plan_id: int, db: Session = Depends(get_db)):
    service = DevelopmentPlansService(db)
    if not service.delete_plan(plan_id):
        raise HTTPException(status_code=404, detail="Development plan not found")
    return None 