from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import sys
import os

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

router = APIRouter(
    prefix="/training-plans",
    tags=["training_plans"]
)

@router.post("/", response_model=schemas.TrainingPlan)
def create_training_plan(
    training_plan: schemas.TrainingPlanCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_training_plan = models.TrainingPlan(
        **training_plan.dict(),
        player_id=current_user.id
    )
    db.add(db_training_plan)
    db.commit()
    db.refresh(db_training_plan)
    return db_training_plan

@router.get("/", response_model=List[schemas.TrainingPlan])
def read_training_plans(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    training_plans = db.query(models.TrainingPlan).filter(
        models.TrainingPlan.player_id == current_user.id
    ).offset(skip).limit(limit).all()
    return training_plans

@router.get("/{training_plan_id}", response_model=schemas.TrainingPlan)
def read_training_plan(
    training_plan_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    training_plan = db.query(models.TrainingPlan).filter(
        models.TrainingPlan.id == training_plan_id,
        models.TrainingPlan.player_id == current_user.id
    ).first()
    if training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    return training_plan

@router.put("/{training_plan_id}", response_model=schemas.TrainingPlan)
def update_training_plan(
    training_plan_id: int,
    training_plan_update: schemas.TrainingPlanBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_training_plan = db.query(models.TrainingPlan).filter(
        models.TrainingPlan.id == training_plan_id,
        models.TrainingPlan.player_id == current_user.id
    ).first()
    if db_training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    for field, value in training_plan_update.dict().items():
        setattr(db_training_plan, field, value)
    
    db.commit()
    db.refresh(db_training_plan)
    return db_training_plan

@router.delete("/{training_plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_training_plan(
    training_plan_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_training_plan = db.query(models.TrainingPlan).filter(
        models.TrainingPlan.id == training_plan_id,
        models.TrainingPlan.player_id == current_user.id
    ).first()
    if db_training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    db.delete(db_training_plan)
    db.commit()
    return None 