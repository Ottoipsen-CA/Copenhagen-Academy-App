from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime

from models.exercise_library import ExerciseLibrary
from schemas.exercise_library import ExerciseLibraryCreate, ExerciseLibraryUpdate
from .base import BaseService

class ExerciseLibraryService:
    def __init__(self, db: Session):
        self.db = db
        self.exercise_service = BaseService[ExerciseLibrary, ExerciseLibraryCreate, ExerciseLibraryUpdate, ExerciseLibrary](ExerciseLibrary, db)
    
    def get_all_exercises(
        self,
        category: Optional[str] = None,
        difficulty_level: Optional[str] = None,
        created_by: Optional[int] = None,
        is_public: Optional[bool] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[ExerciseLibrary]:
        query = self.db.query(ExerciseLibrary)
        
        if category:
            query = query.filter(ExerciseLibrary.category == category)
        if difficulty_level:
            query = query.filter(ExerciseLibrary.difficulty_level == difficulty_level)
        if created_by:
            query = query.filter(ExerciseLibrary.created_by == created_by)
        if is_public is not None:
            query = query.filter(ExerciseLibrary.is_public == is_public)
            
        return query.order_by(ExerciseLibrary.name).offset(skip).limit(limit).all()
    
    def get_exercise_by_id(self, exercise_id: int) -> Optional[ExerciseLibrary]:
        return self.exercise_service.get_by_id(exercise_id)
    
    def search_exercises(
        self, 
        search_term: str,
        category: Optional[str] = None,
        difficulty_level: Optional[str] = None,
        is_public: Optional[bool] = True,
        skip: int = 0,
        limit: int = 100
    ) -> List[ExerciseLibrary]:
        query = self.db.query(ExerciseLibrary)
        
        # Apply search filter
        if search_term:
            search_term = f"%{search_term}%"
            query = query.filter(
                ExerciseLibrary.name.ilike(search_term) |
                ExerciseLibrary.description.ilike(search_term) |
                ExerciseLibrary.instructions.ilike(search_term) |
                ExerciseLibrary.benefits.ilike(search_term)
            )
        
        # Apply other filters
        if category:
            query = query.filter(ExerciseLibrary.category == category)
        if difficulty_level:
            query = query.filter(ExerciseLibrary.difficulty_level == difficulty_level)
        if is_public is not None:
            query = query.filter(ExerciseLibrary.is_public == is_public)
            
        return query.order_by(ExerciseLibrary.name).offset(skip).limit(limit).all()
    
    def create_exercise(self, exercise: ExerciseLibraryCreate) -> ExerciseLibrary:
        return self.exercise_service.create(exercise)
    
    def update_exercise(self, exercise_id: int, exercise: ExerciseLibraryUpdate) -> ExerciseLibrary:
        return self.exercise_service.update(exercise_id, exercise)
    
    def delete_exercise(self, exercise_id: int) -> bool:
        # Check if the exercise is used in any training day entries
        # If needed, this check would be implemented here
        # For example:
        # if self.db.query(TrainingDayEntry).filter(TrainingDayEntry.exercise_id == exercise_id).count() > 0:
        #     raise HTTPException(
        #         status_code=status.HTTP_400_BAD_REQUEST,
        #         detail="Cannot delete exercise that is used in training plans"
        #     )
        
        return self.exercise_service.delete(exercise_id)
    
    def get_exercises_by_category(self, category: str) -> List[ExerciseLibrary]:
        return self.db.query(ExerciseLibrary).filter(ExerciseLibrary.category == category).order_by(ExerciseLibrary.name).all()
    
    def get_user_exercises(self, user_id: int) -> List[ExerciseLibrary]:
        return self.db.query(ExerciseLibrary).filter(ExerciseLibrary.created_by == user_id).order_by(ExerciseLibrary.name).all()
    
    def copy_exercise(self, exercise_id: int, new_owner_id: int) -> ExerciseLibrary:
        """Create a copy of an existing exercise with a new owner"""
        # Get the original exercise
        original = self.get_exercise_by_id(exercise_id)
        if not original:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise not found"
            )
            
        # Create a new exercise based on the original
        new_exercise_data = ExerciseLibraryCreate(
            name=f"Copy of {original.name}",
            description=original.description,
            category=original.category,
            difficulty_level=original.difficulty_level,
            duration_minutes=original.duration_minutes,
            equipment=original.equipment,
            video_url=original.video_url,
            image_url=original.image_url,
            instructions=original.instructions,
            benefits=original.benefits,
            is_public=False,  # Default to private
            parameters=original.parameters,
            created_by=new_owner_id
        )
        
        return self.create_exercise(new_exercise_data) 