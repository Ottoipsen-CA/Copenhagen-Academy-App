from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any

from database import get_db
from services.training import TrainingService
from schemas import (
    TrainingPlanCreate, TrainingPlanUpdate, TrainingPlanResponse,
    TrainingDayCreate, TrainingDayUpdate, TrainingDayResponse,
    TrainingDayEntryCreate, TrainingDayEntryUpdate, TrainingDayEntryResponse
)
from models import User as UserModel
from services.auth import get_current_user_dependency

router = APIRouter(
    prefix="/training",
    tags=["training"],
    responses={404: {"description": "Not found"}},
)

def get_training_service(db: Session = Depends(get_db)) -> TrainingService:
    return TrainingService(db)

# --- Training Plan Endpoints --- 

@router.post("/plans", response_model=TrainingPlanResponse, status_code=status.HTTP_201_CREATED)
def create_training_plan(
    plan_in: TrainingPlanCreate,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Create a new training plan. Only coaches or admins can create public plans."""
    if plan_in.is_public and current_user.role not in ["coach", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only coaches or admins can create public plans."
        )
    plan_in.created_by = current_user.id
    return service.create_training_plan(plan_in)

@router.get("/plans", response_model=List[TrainingPlanResponse])
def read_training_plans(
    difficulty_level: Optional[str] = None,
    focus_area: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Retrieve training plans. 
    - Users can see public plans and their own private plans.
    - Coaches/Admins can see all plans.
    """
    if current_user.role in ["coach", "admin"]:
        return service.get_all_training_plans(
            difficulty_level=difficulty_level, focus_area=focus_area, 
            skip=skip, limit=limit
        )
    else:
        # Combine public plans and user's own plans
        public_plans = service.get_all_training_plans(
            difficulty_level=difficulty_level, focus_area=focus_area,
            is_public=True, skip=skip, limit=limit
        )
        my_plans = service.get_all_training_plans(
            difficulty_level=difficulty_level, focus_area=focus_area,
            created_by=current_user.id, is_public=False, 
            skip=skip, limit=limit
        )
        # Simple combination, might need refinement for pagination/duplicates
        plan_ids = {p.id for p in public_plans}
        combined_plans = public_plans + [p for p in my_plans if p.id not in plan_ids]
        return combined_plans

@router.get("/plans/{plan_id}", response_model=TrainingPlanResponse)
def read_training_plan(
    plan_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Retrieve a specific training plan. Checks if the user has access."""
    db_plan = service.get_training_plan_by_id(plan_id)
    if not db_plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training plan not found")
    
    if not db_plan.is_public and db_plan.created_by != current_user.id and current_user.role not in ["coach", "admin"]:
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to access this plan."
        )
    return db_plan

@router.put("/plans/{plan_id}", response_model=TrainingPlanResponse)
def update_training_plan(
    plan_id: int,
    plan_in: TrainingPlanUpdate,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Update a training plan. Requires ownership or admin role."""
    db_plan = service.get_training_plan_by_id(plan_id)
    if not db_plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training plan not found")
        
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to update this plan."
        )
        
    # Prevent non-admins/coaches from making plans public
    if plan_in.is_public is True and current_user.role not in ["coach", "admin"]:
         plan_in.is_public = db_plan.is_public # Keep original status
         
    return service.update_training_plan(plan_id, plan_in)

@router.delete("/plans/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_training_plan(
    plan_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Delete a training plan. Requires ownership or admin role."""
    db_plan = service.get_training_plan_by_id(plan_id)
    if not db_plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training plan not found")
        
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to delete this plan."
        )
        
    service.delete_training_plan(plan_id)
    return None

@router.post("/plans/{plan_id}/clone", response_model=TrainingPlanResponse, status_code=status.HTTP_201_CREATED)
def clone_training_plan(
    plan_id: int,
    new_title: Optional[str] = None,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Clone an existing training plan for the current user."""
    # Ensure user has access to the original plan
    original_plan = read_training_plan(plan_id, service, current_user) 
    
    return service.clone_training_plan(plan_id, current_user.id, new_title)

# --- Training Day Endpoints --- 

@router.post("/days", response_model=TrainingDayResponse, status_code=status.HTTP_201_CREATED)
def create_training_day(
    day_in: TrainingDayCreate,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Create a new training day within a plan. Requires plan ownership or admin role."""
    db_plan = service.get_training_plan_by_id(day_in.training_plan_id)
    if not db_plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training plan not found")
        
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to add days to this plan."
        )
        
    return service.create_training_day(day_in)

@router.get("/plans/{plan_id}/days", response_model=List[TrainingDayResponse])
def read_training_days_for_plan(
    plan_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Retrieve all training days for a specific plan. Requires access to the plan."""
    # Ensure user has access to the plan first
    read_training_plan(plan_id, service, current_user)
    return service.get_training_days_by_plan(plan_id)

@router.get("/days/{day_id}", response_model=TrainingDayResponse)
def read_training_day(
    day_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Retrieve a specific training day. Requires access to the parent plan."""
    db_day = service.get_training_day_by_id(day_id)
    if not db_day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day not found")
    # Check access to parent plan
    read_training_plan(db_day.training_plan_id, service, current_user)
    return db_day

@router.put("/days/{day_id}", response_model=TrainingDayResponse)
def update_training_day(
    day_id: int,
    day_in: TrainingDayUpdate,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Update a training day. Requires ownership of the parent plan or admin role."""
    db_day = service.get_training_day_by_id(day_id)
    if not db_day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day not found")
        
    db_plan = service.get_training_plan_by_id(db_day.training_plan_id)
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to update days in this plan."
        )
        
    return service.update_training_day(day_id, day_in)

@router.delete("/days/{day_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_training_day(
    day_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Delete a training day. Requires ownership of the parent plan or admin role."""
    db_day = service.get_training_day_by_id(day_id)
    if not db_day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day not found")
        
    db_plan = service.get_training_plan_by_id(db_day.training_plan_id)
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to delete days in this plan."
        )
        
    service.delete_training_day(day_id)
    return None

@router.post("/days/{day_id}/reorder", response_model=List[TrainingDayEntryResponse])
def reorder_day_entries(
    day_id: int, 
    entry_orders: Dict[int, int], # {entry_id: new_order}
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Reorder exercises within a training day. Requires ownership or admin."""
    db_day = service.get_training_day_by_id(day_id)
    if not db_day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day not found")
        
    db_plan = service.get_training_plan_by_id(db_day.training_plan_id)
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to reorder entries in this plan."
        )
        
    return service.reorder_training_day_entries(day_id, entry_orders)

# --- Training Day Entry Endpoints --- 

@router.post("/entries", response_model=TrainingDayEntryResponse, status_code=status.HTTP_201_CREATED)
def create_training_day_entry(
    entry_in: TrainingDayEntryCreate,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Create a new exercise entry in a training day. Requires ownership or admin role."""
    db_day = service.get_training_day_by_id(entry_in.training_day_id)
    if not db_day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day not found")
        
    db_plan = service.get_training_plan_by_id(db_day.training_plan_id)
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to add entries to this plan."
        )
        
    # TODO: Add check to ensure exercise_id exists in ExerciseLibrary
    
    return service.create_training_day_entry(entry_in)

@router.get("/days/{day_id}/entries", response_model=List[TrainingDayEntryResponse])
def read_day_entries(
    day_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Retrieve all entries for a specific training day. Requires access to the parent plan."""
    db_day = service.get_training_day_by_id(day_id)
    if not db_day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day not found")
    # Check access to parent plan
    read_training_plan(db_day.training_plan_id, service, current_user)
    return service.get_entries_by_day(day_id)

@router.get("/entries/{entry_id}", response_model=TrainingDayEntryResponse)
def read_day_entry(
    entry_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Retrieve a specific training day entry. Requires access to the parent plan."""
    db_entry = service.get_entry_by_id(entry_id)
    if not db_entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day entry not found")
    # Check access via parent day and plan
    read_training_day(db_entry.training_day_id, service, current_user)
    return db_entry

@router.put("/entries/{entry_id}", response_model=TrainingDayEntryResponse)
def update_training_day_entry(
    entry_id: int,
    entry_in: TrainingDayEntryUpdate,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Update a training day entry. Requires ownership of the parent plan or admin role."""
    db_entry = service.get_entry_by_id(entry_id)
    if not db_entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day entry not found")
        
    db_day = service.get_training_day_by_id(db_entry.training_day_id)
    db_plan = service.get_training_plan_by_id(db_day.training_plan_id)
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to update entries in this plan."
        )
        
    # TODO: Add check to ensure exercise_id exists if changed
        
    return service.update_training_day_entry(entry_id, entry_in)

@router.delete("/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_training_day_entry(
    entry_id: int,
    service: TrainingService = Depends(get_training_service),
    current_user: UserModel = Depends(get_current_user_dependency)
):
    """Delete a training day entry. Requires ownership of the parent plan or admin role."""
    db_entry = service.get_entry_by_id(entry_id)
    if not db_entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Training day entry not found")
        
    db_day = service.get_training_day_by_id(db_entry.training_day_id)
    db_plan = service.get_training_plan_by_id(db_day.training_plan_id)
    if db_plan.created_by != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to delete entries in this plan."
        )
        
    service.delete_training_day_entry(entry_id)
    return None 