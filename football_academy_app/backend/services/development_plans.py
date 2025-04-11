from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional

from models.development_plans import DevelopmentPlan
from schemas.development_plans import DevelopmentPlanCreate, DevelopmentPlanUpdate
from .base import BaseService

class DevelopmentPlansService:
    def __init__(self, db: Session):
        self.db = db
        self.plan_service = BaseService[DevelopmentPlan, DevelopmentPlanCreate, DevelopmentPlanUpdate, DevelopmentPlan](
            DevelopmentPlan, db
        )

    def get_all_plans(self, skip: int = 0, limit: int = 100) -> List[DevelopmentPlan]:
        return self.plan_service.get_all(skip=skip, limit=limit)

    def get_plan_by_id(self, plan_id: int) -> Optional[DevelopmentPlan]:
        return self.plan_service.get_by_id(plan_id)

    def get_user_plans(self, user_id: int) -> List[DevelopmentPlan]:
        return self.db.query(DevelopmentPlan).filter(DevelopmentPlan.user_id == user_id).all()

    def create_plan(self, plan: DevelopmentPlanCreate) -> DevelopmentPlan:
        return self.plan_service.create(plan)

    def update_plan(self, plan_id: int, plan: DevelopmentPlanUpdate) -> DevelopmentPlan:
        return self.plan_service.update(plan_id, plan)

    def delete_plan(self, plan_id: int) -> bool:
        return self.plan_service.delete(plan_id) 