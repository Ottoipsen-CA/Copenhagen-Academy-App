from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime

from models.training import TrainingPlan, TrainingDay, TrainingDayEntry
from schemas.training import (
    TrainingPlanCreate, TrainingPlanUpdate,
    TrainingDayCreate, TrainingDayUpdate,
    TrainingDayEntryCreate, TrainingDayEntryUpdate
)
from .base import BaseService

class TrainingService:
    def __init__(self, db: Session):
        self.db = db
        self.plan_service = BaseService[TrainingPlan, TrainingPlanCreate, TrainingPlanUpdate, TrainingPlan](TrainingPlan, db)
        self.day_service = BaseService[TrainingDay, TrainingDayCreate, TrainingDayUpdate, TrainingDay](TrainingDay, db)
        self.entry_service = BaseService[TrainingDayEntry, TrainingDayEntryCreate, TrainingDayEntryUpdate, TrainingDayEntry](TrainingDayEntry, db)
    
    # Training Plan methods
    def get_all_training_plans(
        self,
        difficulty_level: Optional[str] = None,
        focus_area: Optional[str] = None,
        created_by: Optional[int] = None,
        is_public: Optional[bool] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[TrainingPlan]:
        query = self.db.query(TrainingPlan)
        
        if difficulty_level:
            query = query.filter(TrainingPlan.difficulty_level == difficulty_level)
        if focus_area:
            query = query.filter(TrainingPlan.focus_area == focus_area)
        if created_by:
            query = query.filter(TrainingPlan.created_by == created_by)
        if is_public is not None:
            query = query.filter(TrainingPlan.is_public == is_public)
            
        return query.order_by(TrainingPlan.created_at.desc()).offset(skip).limit(limit).all()
    
    def get_training_plan_by_id(self, plan_id: int) -> Optional[TrainingPlan]:
        return self.plan_service.get_by_id(plan_id)
    
    def create_training_plan(self, plan: TrainingPlanCreate) -> TrainingPlan:
        return self.plan_service.create(plan)
    
    def update_training_plan(self, plan_id: int, plan: TrainingPlanUpdate) -> TrainingPlan:
        return self.plan_service.update(plan_id, plan)
    
    def delete_training_plan(self, plan_id: int) -> bool:
        # First, delete all training days associated with this plan
        training_days = self.get_training_days_by_plan(plan_id)
        for day in training_days:
            self.delete_training_day(day.id)
            
        # Then delete the plan itself
        return self.plan_service.delete(plan_id)
    
    # Training Day methods
    def get_training_days_by_plan(self, plan_id: int) -> List[TrainingDay]:
        return self.db.query(TrainingDay).filter(TrainingDay.training_plan_id == plan_id).order_by(TrainingDay.day_number).all()
    
    def get_training_day_by_id(self, day_id: int) -> Optional[TrainingDay]:
        return self.day_service.get_by_id(day_id)
    
    def create_training_day(self, day: TrainingDayCreate) -> TrainingDay:
        # Verify that the plan exists
        plan = self.get_training_plan_by_id(day.training_plan_id)
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Training plan not found"
            )
            
        # Verify that the day number is not already used for this plan
        existing_day = self.db.query(TrainingDay).filter(
            TrainingDay.training_plan_id == day.training_plan_id,
            TrainingDay.day_number == day.day_number
        ).first()
        
        if existing_day:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Day number {day.day_number} already exists for this training plan"
            )
            
        return self.day_service.create(day)
    
    def update_training_day(self, day_id: int, day: TrainingDayUpdate) -> TrainingDay:
        db_day = self.get_training_day_by_id(day_id)
        if not db_day:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Training day not found"
            )
            
        # If day number is being changed, verify it's not already used
        if hasattr(day, 'day_number') and day.day_number is not None and day.day_number != db_day.day_number:
            existing_day = self.db.query(TrainingDay).filter(
                TrainingDay.training_plan_id == db_day.training_plan_id,
                TrainingDay.day_number == day.day_number
            ).first()
            
            if existing_day:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Day number {day.day_number} already exists for this training plan"
                )
                
        return self.day_service.update(day_id, day)
    
    def delete_training_day(self, day_id: int) -> bool:
        # First, delete all entries associated with this day
        entries = self.get_entries_by_day(day_id)
        for entry in entries:
            self.entry_service.delete(entry.id)
            
        # Then delete the day itself
        return self.day_service.delete(day_id)
    
    # Training Day Entry methods
    def get_entries_by_day(self, day_id: int) -> List[TrainingDayEntry]:
        return self.db.query(TrainingDayEntry).filter(TrainingDayEntry.training_day_id == day_id).order_by(TrainingDayEntry.order).all()
    
    def get_entry_by_id(self, entry_id: int) -> Optional[TrainingDayEntry]:
        return self.entry_service.get_by_id(entry_id)
    
    def create_training_day_entry(self, entry: TrainingDayEntryCreate) -> TrainingDayEntry:
        # Verify that the training day exists
        day = self.get_training_day_by_id(entry.training_day_id)
        if not day:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Training day not found"
            )
            
        # If no order provided, place it at the end
        if not hasattr(entry, 'order') or entry.order is None:
            last_entry = self.db.query(TrainingDayEntry).filter(
                TrainingDayEntry.training_day_id == entry.training_day_id
            ).order_by(TrainingDayEntry.order.desc()).first()
            
            next_order = 1
            if last_entry:
                next_order = last_entry.order + 1
                
            entry.order = next_order
            
        return self.entry_service.create(entry)
    
    def update_training_day_entry(self, entry_id: int, entry: TrainingDayEntryUpdate) -> TrainingDayEntry:
        db_entry = self.get_entry_by_id(entry_id)
        if not db_entry:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Training day entry not found"
            )
            
        return self.entry_service.update(entry_id, entry)
    
    def delete_training_day_entry(self, entry_id: int) -> bool:
        return self.entry_service.delete(entry_id)
    
    def reorder_training_day_entries(self, day_id: int, entry_orders: Dict[int, int]) -> List[TrainingDayEntry]:
        """Reorder the entries for a training day
        
        Args:
            day_id: ID of the training day
            entry_orders: Dictionary mapping entry IDs to their new order
        
        Returns:
            List of updated entries
        """
        # Get all entries for this day
        entries = self.get_entries_by_day(day_id)
        
        # Update the order for each entry
        for entry in entries:
            if entry.id in entry_orders:
                entry.order = entry_orders[entry.id]
                self.db.add(entry)
                
        self.db.commit()
        
        # Return the updated entries
        return self.get_entries_by_day(day_id)
    
    def clone_training_plan(self, plan_id: int, new_owner_id: int, new_title: Optional[str] = None) -> TrainingPlan:
        """Create a copy of an existing training plan with all its days and entries"""
        # Get the original plan
        original_plan = self.get_training_plan_by_id(plan_id)
        if not original_plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Training plan not found"
            )
            
        # Create a new plan based on the original
        new_plan_data = TrainingPlanCreate(
            title=new_title or f"Copy of {original_plan.title}",
            description=original_plan.description,
            difficulty_level=original_plan.difficulty_level,
            focus_area=original_plan.focus_area,
            duration_weeks=original_plan.duration_weeks,
            created_by=new_owner_id,
            is_public=False  # Set to private by default
        )
        
        new_plan = self.create_training_plan(new_plan_data)
        
        # Copy all the training days
        for day in self.get_training_days_by_plan(plan_id):
            new_day_data = TrainingDayCreate(
                training_plan_id=new_plan.id,
                day_number=day.day_number,
                title=day.title,
                description=day.description,
                focus=day.focus,
                duration_minutes=day.duration_minutes,
                intensity=day.intensity
            )
            
            new_day = self.create_training_day(new_day_data)
            
            # Copy all the entries for this day
            for entry in self.get_entries_by_day(day.id):
                new_entry_data = TrainingDayEntryCreate(
                    training_day_id=new_day.id,
                    exercise_id=entry.exercise_id,
                    order=entry.order,
                    sets=entry.sets,
                    reps=entry.reps,
                    duration_minutes=entry.duration_minutes,
                    notes=entry.notes,
                    custom_parameters=entry.custom_parameters
                )
                
                self.create_training_day_entry(new_entry_data)
                
        return new_plan 