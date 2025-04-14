from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime

from models.challenges import Challenge, ChallengeCompletion, Badge, Achievement, ChallengeStatus
from schemas.challenges import (
    ChallengeCreate, ChallengeUpdate,
    ChallengeCompletionCreate, ChallengeCompletionUpdate,
    BadgeCreate, BadgeUpdate,
    AchievementCreate, AchievementUpdate
)
from .base import BaseService

class ChallengesService:
    def __init__(self, db: Session):
        self.db = db
        self.challenge_service = BaseService[Challenge, ChallengeCreate, ChallengeUpdate, Challenge](Challenge, db)
        self.completion_service = BaseService[ChallengeCompletion, ChallengeCompletionCreate, ChallengeCompletionUpdate, ChallengeCompletion](ChallengeCompletion, db)
        self.badge_service = BaseService[Badge, BadgeCreate, BadgeUpdate, Badge](Badge, db)
        self.achievement_service = BaseService[Achievement, AchievementCreate, AchievementUpdate, Achievement](Achievement, db)
    
    # Challenge methods
    def get_challenges(self) -> List[Challenge]:
        """Get all challenges."""
        return self.db.query(Challenge).all()
    
    def get_all_challenges(
        self, 
        category: Optional[str] = None, 
        difficulty: Optional[str] = None,
        is_active: Optional[bool] = None,
        skip: int = 0, 
        limit: int = 100
    ) -> List[Challenge]:
        query = self.db.query(Challenge)
        
        if category:
            query = query.filter(Challenge.category == category)
        if difficulty:
            query = query.filter(Challenge.difficulty == difficulty)
        if is_active is not None:
            query = query.filter(Challenge.is_active == is_active)
            
        return query.offset(skip).limit(limit).all()
    
    def get_challenge_by_id(self, challenge_id: int) -> Optional[Challenge]:
        return self.challenge_service.get_by_id(challenge_id)
    
    def create_challenge(self, challenge: ChallengeCreate, created_by: int) -> Challenge:
        """Create a new challenge.
        
        Args:
            challenge: The challenge data to create
            created_by: The ID of the user creating the challenge
            
        Returns:
            The created challenge
        """
        # Create a new ChallengeCreate object with the created_by field set
        challenge_data = ChallengeCreate(
            title=challenge.title,
            description=challenge.description,
            category=challenge.category,
            difficulty=challenge.difficulty,
            points=challenge.points,
            criteria=challenge.criteria,
            start_date=challenge.start_date,
            end_date=challenge.end_date,
            is_active=challenge.is_active,
            created_by=created_by,
            badge_id=challenge.badge_id
        )
        
        return self.challenge_service.create(challenge_data)
    
    def update_challenge(self, challenge_id: int, challenge: ChallengeUpdate) -> Challenge:
        """Update a challenge.
        
        Args:
            challenge_id: The ID of the challenge to update
            challenge: The challenge data to update
            
        Returns:
            The updated challenge
        """
        # Convert badge_id=0 to None for the database
        if hasattr(challenge, 'badge_id') and challenge.badge_id == 0:
            challenge_dict = challenge.dict()
            challenge_dict['badge_id'] = None
            challenge = ChallengeUpdate(**challenge_dict)
        
        return self.challenge_service.update(challenge_id, challenge)
    
    def delete_challenge(self, challenge_id: int) -> bool:
        return self.challenge_service.delete(challenge_id)
    
    # Challenge Completion methods
    def get_user_challenges(self, user_id: int) -> List[ChallengeCompletion]:
        return self.db.query(ChallengeCompletion).filter(ChallengeCompletion.user_id == user_id).all()
    
    def get_challenge_completions(self, challenge_id: int) -> List[ChallengeCompletion]:
        return self.db.query(ChallengeCompletion).filter(ChallengeCompletion.challenge_id == challenge_id).all()
    
    def get_completion_by_id(self, completion_id: int) -> Optional[ChallengeCompletion]:
        return self.completion_service.get_by_id(completion_id)
    
    def get_user_challenge_completion(self, user_id: int, challenge_id: int) -> Optional[ChallengeCompletion]:
        return self.db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == user_id,
            ChallengeCompletion.challenge_id == challenge_id
        ).first()
    
    def start_challenge(self, user_id: int, challenge_id: int) -> ChallengeCompletion:
        # Check if user has already started/completed this challenge
        existing = self.get_user_challenge_completion(user_id, challenge_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User has already started this challenge"
            )
        
        # Check if challenge exists and is active
        challenge = self.get_challenge_by_id(challenge_id)
        if not challenge:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Challenge not found"
            )
        
        if not challenge.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Challenge is not active"
            )
        
        # Create challenge completion record
        completion_data = ChallengeCompletionCreate(
            user_id=user_id,
            challenge_id=challenge_id,
            status=ChallengeStatus.ACTIVE,
            progress=0.0
        )
        
        return self.completion_service.create(completion_data)
    
    def update_challenge_progress(
        self, 
        user_id: int, 
        challenge_id: int, 
        progress: float,
        notes: Optional[str] = None
    ) -> ChallengeCompletion:
        completion = self.get_user_challenge_completion(user_id, challenge_id)
        if not completion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Challenge progress not found"
            )
        
        update_data = {"progress": progress}
        if notes:
            update_data["notes"] = notes
        
        # Check if the progress is 100%, mark as completed
        if progress >= 100.0:
            update_data["status"] = ChallengeStatus.COMPLETED
            update_data["completed_at"] = datetime.utcnow()
            
            # If the challenge has a badge, award it to the user
            challenge = self.get_challenge_by_id(challenge_id)
            if challenge and challenge.badge_id:
                self._award_badge(user_id, challenge.badge_id, None)
        
        return self.completion_service.update(completion.id, update_data)
    
    def verify_challenge_completion(
        self, 
        completion_id: int, 
        coach_id: int,
        notes: Optional[str] = None
    ) -> ChallengeCompletion:
        completion = self.get_completion_by_id(completion_id)
        if not completion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Challenge completion not found"
            )
        
        if completion.status != ChallengeStatus.COMPLETED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Challenge is not completed yet"
            )
        
        # Update verification
        update_data = {
            "verified_by": coach_id
        }
        
        if notes:
            update_data["notes"] = notes
        
        # Update completion record
        result = self.completion_service.update(completion_id, update_data)
        
        # Update league table if challenge is verified
        # This would be implemented in the LeagueTableService
        
        return result
    
    # Badge methods
    def get_all_badges(self, skip: int = 0, limit: int = 100) -> List[Badge]:
        return self.badge_service.get_all(skip=skip, limit=limit)
    
    def get_badge_by_id(self, badge_id: int) -> Optional[Badge]:
        return self.badge_service.get_by_id(badge_id)
    
    def create_badge(self, badge: BadgeCreate) -> Badge:
        return self.badge_service.create(badge)
    
    def update_badge(self, badge_id: int, badge: BadgeUpdate) -> Badge:
        return self.badge_service.update(badge_id, badge)
    
    def delete_badge(self, badge_id: int) -> bool:
        return self.badge_service.delete(badge_id)
    
    # Achievement methods
    def get_user_achievements(self, user_id: int) -> List[Achievement]:
        return self.db.query(Achievement).filter(Achievement.user_id == user_id).all()
    
    def get_badge_achievements(self, badge_id: int) -> List[Achievement]:
        return self.db.query(Achievement).filter(Achievement.badge_id == badge_id).all()
    
    def get_achievement_by_id(self, achievement_id: int) -> Optional[Achievement]:
        return self.achievement_service.get_by_id(achievement_id)
    
    def _award_badge(self, user_id: int, badge_id: int, awarded_by: Optional[int]) -> Achievement:
        # Check if user already has this badge
        existing = self.db.query(Achievement).filter(
            Achievement.user_id == user_id,
            Achievement.badge_id == badge_id
        ).first()
        
        if existing:
            return existing
        
        # Create new achievement
        achievement_data = AchievementCreate(
            user_id=user_id,
            badge_id=badge_id,
            awarded_by=awarded_by
        )
        
        return self.achievement_service.create(achievement_data)
    
    def award_badge(self, user_id: int, badge_id: int, coach_id: int) -> Achievement:
        # Check if badge exists
        badge = self.get_badge_by_id(badge_id)
        if not badge:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Badge not found"
            )
        
        return self._award_badge(user_id, badge_id, coach_id) 