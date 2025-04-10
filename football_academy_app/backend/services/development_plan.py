from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from models.development_plan import DevelopmentPlan
from schemas.development_plan import DevelopmentPlanCreate, DevelopmentPlanUpdate
from .base import BaseService

class DevelopmentPlanService:
    def __init__(self, db: Session):
        self.db = db
        # Initialize BaseService for DevelopmentPlan model and associated schemas
        self.plan_service = BaseService[DevelopmentPlan, DevelopmentPlanCreate, DevelopmentPlanUpdate, DevelopmentPlan](DevelopmentPlan, db)

    def get_all_plans(self, skip: int = 0, limit: int = 100) -> List[DevelopmentPlan]:
        """Retrieve all development plans with pagination (Eager loading)."""
        return self.db.query(DevelopmentPlan).options(
            joinedload(DevelopmentPlan.training_sessions),
            joinedload(DevelopmentPlan.focus_areas)
        ).offset(skip).limit(limit).all()

    def get_plans_by_player_id(self, player_id: int, skip: int = 0, limit: int = 100) -> List[DevelopmentPlan]:
        """Retrieve development plans for a specific player (Eager loading)."""
        return self.db.query(DevelopmentPlan).options(
            joinedload(DevelopmentPlan.training_sessions),
            joinedload(DevelopmentPlan.focus_areas)
        ).filter(DevelopmentPlan.player_id == player_id).offset(skip).limit(limit).all()

    def get_plan_by_id(self, plan_id: int) -> Optional[DevelopmentPlan]:
        """Retrieve a specific development plan by its ID (Eager loading)."""
        return self.db.query(DevelopmentPlan).options(
            joinedload(DevelopmentPlan.training_sessions),
            joinedload(DevelopmentPlan.focus_areas)
        ).filter(DevelopmentPlan.id == plan_id).first()

    def create_plan(self, plan: DevelopmentPlanCreate) -> DevelopmentPlan:
        """Create a new development plan (Simplified for debugging)."""
        # Directly use BaseService to create and return the basic plan entry.
        # BaseService.create currently uses only add/commit.
        # The returned object's ID should be populated after commit.
        # FastAPI will serialize this using the simplified DevelopmentPlan schema.
        return self.plan_service.create(plan)

    def update_plan(self, plan_id: int, plan_update: DevelopmentPlanUpdate) -> Optional[DevelopmentPlan]:
        """Update an existing development plan."""
        updated_plan_basic = self.plan_service.update(plan_id, plan_update)
        if not updated_plan_basic:
             return None
        # Re-fetch with eager loading after update to ensure response has relationships
        return self.get_plan_by_id(plan_id)

    def delete_plan(self, plan_id: int) -> bool:
        """Delete a development plan by its ID."""
        return self.plan_service.delete(plan_id) 