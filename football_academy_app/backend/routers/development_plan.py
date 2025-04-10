from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas.development_plan import DevelopmentPlan, DevelopmentPlanCreate, DevelopmentPlanUpdate
from services.development_plan import DevelopmentPlanService
from models.users import User # Assuming you have a User model and authentication
from models.development_plan import DevelopmentPlan as DevelopmentPlanModel # Import the model
# from auth.dependencies import get_current_active_user # Import your auth dependency

router = APIRouter(
    prefix="/development-plans",
    tags=["Development Plans"],
    responses={404: {"description": "Not found"}},
)

# Dependency to get the DevelopmentPlanService
def get_development_plan_service(db: Session = Depends(get_db)) -> DevelopmentPlanService:
    return DevelopmentPlanService(db)

# TEMPORARILY REMOVE response_model FOR DEBUGGING
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_development_plan(
    plan_in: DevelopmentPlanCreate,
    service: DevelopmentPlanService = Depends(get_development_plan_service),
    # current_user: User = Depends(get_current_active_user) # Add auth if needed
):
    """Create a new development plan (Simplified, manual dict return)."""
    db_plan: DevelopmentPlanModel = service.create_plan(plan_in)
    
    # Manually create a dictionary from the object's attributes
    # This bypasses FastAPI's response_model serialization
    try:
        plan_dict = {
            "id": db_plan.id, 
            "player_id": db_plan.player_id,
            "title": db_plan.title,
            "long_term_goals": db_plan.long_term_goals,
            "notes": db_plan.notes,
            "created_at": db_plan.created_at,
            "updated_at": db_plan.updated_at
            # Exclude relationships for now
        }
        print(f"DEBUG: Created plan dictionary: {plan_dict}") # Add print for debugging
        return plan_dict
    except Exception as e:
        print(f"ERROR: Failed to access attributes or create dict: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process created plan: {e}")

@router.get("/", response_model=List[DevelopmentPlan])
def read_development_plans(
    skip: int = 0,
    limit: int = 100,
    service: DevelopmentPlanService = Depends(get_development_plan_service),
    # current_user: User = Depends(get_current_active_user) # Add auth if needed
):
    """Retrieve all development plans."""
    # Optional: Filter plans based on user role (e.g., players see their own, coaches see their players')
    return service.get_all_plans(skip=skip, limit=limit)

@router.get("/player/{player_id}", response_model=List[DevelopmentPlan])
def read_player_development_plans(
    player_id: int,
    skip: int = 0,
    limit: int = 100,
    service: DevelopmentPlanService = Depends(get_development_plan_service),
    # current_user: User = Depends(get_current_active_user) # Add auth if needed
):
    """Retrieve development plans for a specific player."""
    # Optional: Authorization checks
    # if current_user.role != 'coach' and player_id != current_user.user_id:
    #     raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    return service.get_plans_by_player_id(player_id=player_id, skip=skip, limit=limit)

@router.get("/{plan_id}", response_model=DevelopmentPlan)
def read_development_plan(
    plan_id: int,
    service: DevelopmentPlanService = Depends(get_development_plan_service),
    # current_user: User = Depends(get_current_active_user) # Add auth if needed
):
    """Retrieve a specific development plan by ID."""
    db_plan = service.get_plan_by_id(plan_id)
    if db_plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Development plan not found")
    # Optional: Authorization check
    # if current_user.role != 'coach' and db_plan.player_id != current_user.user_id:
    #     raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    return db_plan

@router.put("/{plan_id}", response_model=DevelopmentPlan)
def update_development_plan(
    plan_id: int,
    plan_in: DevelopmentPlanUpdate,
    service: DevelopmentPlanService = Depends(get_development_plan_service),
    # current_user: User = Depends(get_current_active_user) # Add auth if needed
):
    """Update a development plan."""
    db_plan = service.get_plan_by_id(plan_id) # Check existence first
    if db_plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Development plan not found")
    # Optional: Authorization check
    # if current_user.role != 'coach' and db_plan.player_id != current_user.user_id:
    #     raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    updated_plan = service.update_plan(plan_id, plan_in)
    if updated_plan is None: # Should not happen if existence check passed, but good practice
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Development plan not found during update")
    return updated_plan

@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_development_plan(
    plan_id: int,
    service: DevelopmentPlanService = Depends(get_development_plan_service),
    # current_user: User = Depends(get_current_active_user) # Add auth if needed
):
    """Delete a development plan."""
    db_plan = service.get_plan_by_id(plan_id) # Check existence first
    if db_plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Development plan not found")
    # Optional: Authorization check
    # if current_user.role != 'coach':
    #     raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only coaches can delete plans")
    deleted = service.delete_plan(plan_id)
    if not deleted:
        # This case might indicate a race condition or other issue if the plan existed moments before
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Development plan not found or could not be deleted")
    return # Return No Content 