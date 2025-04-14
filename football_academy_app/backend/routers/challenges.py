from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import and_, desc

from models import (
    User, Challenge, ChallengeStatus, ChallengeCompletion, ChallengeResult,
    Badge, PlayerStats, Achievement
)
from database import get_db
from services.auth import get_current_user_dependency
from schemas import (
    ChallengeCreate, ChallengeResponse, ChallengeWithStatus,
    ChallengeStatusResponse, ChallengeCompletionCreate, ChallengeCompletionResponse,
    ChallengeCompletionWithDetails, BadgeWithChallenge, AchievementCreate, AchievementResponse,
    ChallengeStatusEnum, ChallengeResultCreate, ChallengeResultResponse,
    ChallengeUpdate
)
from services.challenges import ChallengesService

router = APIRouter(
    prefix="/challenges",
    tags=["challenges"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

# Helper function to properly convert ChallengeCompletion to ChallengeCompletionResponse
def format_challenge_completion_response(completion: ChallengeCompletion) -> Dict[str, Any]:
    """Manually convert a ChallengeCompletion database model to a dictionary for the response."""
    # Convert the status enum to string value for Pydantic
    status_str = completion.status.value if completion.status else "active"
    
    # Create a dictionary with all the fields needed for ChallengeCompletionResponse
    return {
        "id": completion.id,
        "user_id": completion.user_id,
        "challenge_id": completion.challenge_id,
        "status": status_str,  # Use string value, not enum object
        "progress": completion.progress,
        "notes": completion.notes,
        "completed_at": completion.completed_at,
        "verified_by": completion.verified_by,
        "created_at": completion.created_at,
        "updated_at": completion.updated_at
    }

# -------------- Challenge Management Endpoints --------------

@router.post("/", response_model=ChallengeResponse)
async def create_challenge(
    challenge: ChallengeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Only coaches can create challenges
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create challenges"
        )
    
    service = ChallengesService(db)
    return service.create_challenge(challenge, current_user.id)

@router.get("/", response_model=List[ChallengeResponse])
async def get_challenges(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_challenges()

@router.get("/active", response_model=List[ChallengeWithStatus])
async def get_active_challenges(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_active_challenges(current_user.id)

@router.get("/{challenge_id}", response_model=ChallengeResponse)
async def get_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_challenge(challenge_id)

@router.post("/{challenge_id}/complete", response_model=ChallengeCompletionResponse)
async def complete_challenge(
    challenge_id: int,
    completion: ChallengeCompletionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.complete_challenge(challenge_id, current_user.id, completion)

@router.get("/{challenge_id}/status", response_model=ChallengeStatusResponse)
async def get_challenge_status(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_challenge_status(challenge_id, current_user.id)

@router.put("/{challenge_id}/status", response_model=ChallengeStatusResponse)
async def update_challenge_status(
    challenge_id: int,
    status: ChallengeStatusEnum,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.update_challenge_status(challenge_id, current_user.id, status)

@router.post("/{challenge_id}/results", response_model=ChallengeResultResponse)
async def add_challenge_result(
    challenge_id: int,
    result: ChallengeResultCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.add_challenge_result(challenge_id, current_user.id, result)

@router.get("/{challenge_id}/results", response_model=List[ChallengeResultResponse])
async def get_challenge_results(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_challenge_results(challenge_id)

@router.get("/{challenge_id}/badges", response_model=List[BadgeWithChallenge])
async def get_challenge_badges(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_challenge_badges(challenge_id)

@router.post("/{challenge_id}/achievements", response_model=AchievementResponse)
async def create_achievement(
    challenge_id: int,
    achievement: AchievementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Only coaches can create achievements
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create achievements"
        )
    
    service = ChallengesService(db)
    return service.create_achievement(challenge_id, achievement)

@router.get("/{challenge_id}/achievements", response_model=List[AchievementResponse])
async def get_challenge_achievements(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    service = ChallengesService(db)
    return service.get_challenge_achievements(challenge_id)

@router.put("/{challenge_id}", response_model=ChallengeResponse)
async def update_challenge(
    challenge_id: int,
    challenge: ChallengeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Only coaches can update challenges
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update challenges"
        )
    
    service = ChallengesService(db)
    return service.update_challenge(challenge_id, challenge)

@router.delete("/{challenge_id}")
async def delete_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Only coaches can delete challenges
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete challenges"
        )
    
    service = ChallengesService(db)
    service.delete_challenge(challenge_id)
    return {"detail": "Challenge deleted successfully"}

@router.get("/with-status", response_model=List[ChallengeWithStatus])
async def get_challenges_with_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get all challenges and statuses in one query with join
    result = db.query(
        Challenge,
        ChallengeStatus.status,
        ChallengeStatus.unlocked_at,
        ChallengeStatus.completed_at
    ).outerjoin(
        ChallengeStatus,
        and_(
            ChallengeStatus.challenge_id == Challenge.id,
            ChallengeStatus.user_id == current_user.id
        )
    ).all()
    
    challenges_with_status = []
    for challenge, status, unlocked_at, completed_at in result:
        # If no status record exists, set default to LOCKED
        challenge_dict = {
            "id": challenge.id,
            "title": challenge.title,
            "description": challenge.description,
            "xp_reward": challenge.xp_reward,
            "category": challenge.category,
            "is_weekly": challenge.is_weekly,
            "level": challenge.level,
            "prerequisite_id": challenge.prerequisite_id,
            "status": status or "LOCKED",
            "unlocked_at": unlocked_at,
            "completed_at": completed_at
        }
        challenges_with_status.append(challenge_dict)
    
    return challenges_with_status

# -------------- Challenge Status Endpoints --------------

@router.post("/initialize-status", status_code=status.HTTP_201_CREATED)
async def initialize_challenge_statuses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Check if statuses already exist
    existing_statuses = db.query(ChallengeStatus).filter(
        ChallengeStatus.user_id == current_user.id
    ).first()
    
    if existing_statuses:
        raise HTTPException(status_code=400, detail="Challenge statuses already initialized")
    
    # Get all challenges
    challenges = db.query(Challenge).all()
    
    # Group challenges by category
    categories = {}
    for challenge in challenges:
        if challenge.category not in categories:
            categories[challenge.category] = []
        categories[challenge.category].append(challenge)
    
    # For each category, set first level challenges to AVAILABLE, others to LOCKED
    now = datetime.utcnow()
    statuses_to_add = []
    
    for category, category_challenges in categories.items():
        for challenge in category_challenges:
            # Level 1 challenges or weekly challenges are AVAILABLE, others are LOCKED
            status = "AVAILABLE" if challenge.level == 1 or challenge.is_weekly else "LOCKED"
            unlocked_at = now if status == "AVAILABLE" else None
            
            status_record = ChallengeStatus(
                user_id=current_user.id,
                challenge_id=challenge.id,
                status=status,
                unlocked_at=unlocked_at
            )
            statuses_to_add.append(status_record)
    
    # Add all statuses in batch
    db.add_all(statuses_to_add)
    db.commit()
    
    return {"detail": f"Initialized {len(statuses_to_add)} challenge statuses"}

@router.post("/completion", response_model=ChallengeCompletionResponse)
async def record_challenge_completion(
    completion: ChallengeCompletionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    try:
        # Debug info
        print(f"Recording completion for challenge {completion.challenge_id}, user {current_user.id}")
        
        # Check if the challenge exists
        challenge = db.query(Challenge).filter(Challenge.id == completion.challenge_id).first()
        if not challenge:
            raise HTTPException(status_code=404, detail="Challenge not found")
        
        # Check if the user has already opted into this challenge
        existing_completion = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == current_user.id,
            ChallengeCompletion.challenge_id == completion.challenge_id
        ).first()
        
        if existing_completion:
            raise HTTPException(
                status_code=400, 
                detail="You have already opted into this challenge"
            )
        
        # Format initial notes with timestamp
        now = datetime.utcnow()
        initial_note = None
        if hasattr(completion, 'notes') and completion.notes:
            current_time = now.strftime("%Y-%m-%d %H:%M")
            initial_note = f"[{current_time}] Opted in - {completion.notes}"
        
        # Create the challenge completion record
        challenge_completion = ChallengeCompletion(
            user_id=current_user.id,
            challenge_id=completion.challenge_id,
            status=ChallengeStatus.ACTIVE,  # Use the enum directly, not a string
            progress=0.0,  # Initialize with zero
            notes=initial_note
        )
        
        db.add(challenge_completion)
        db.commit()
        db.refresh(challenge_completion)
        print(f"Created completion record ID {challenge_completion.id}")
        
        # Use the helper function to format the response
        return format_challenge_completion_response(challenge_completion)
    except Exception as e:
        print(f"Error in record_challenge_completion: {str(e)}")
        db.rollback()  # Roll back transaction on error
        if "defined enum values" in str(e):
            # This is a specific SQLAlchemy enum error
            raise HTTPException(
                status_code=500,
                detail="Database enum error. The challenge status format is invalid. Please contact support."
            )
        raise

@router.post("/opt-in/{challenge_id}", response_model=ChallengeCompletionResponse)
async def opt_into_challenge(
    challenge_id: int,
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    try:
        # Debug info
        print(f"User {current_user.id} is opting into challenge {challenge_id}")
        
        # Check if the challenge exists
        challenge = db.query(Challenge).filter(Challenge.id == challenge_id).first()
        if not challenge:
            raise HTTPException(status_code=404, detail="Challenge not found")
        
        # Check if the challenge is active
        if not challenge.is_active:
            raise HTTPException(status_code=400, detail="This challenge is no longer active")
        
        # Check if challenge is expired based on end_date
        now = datetime.utcnow()
        if challenge.end_date and challenge.end_date < now:
            raise HTTPException(
                status_code=400,
                detail="This challenge has expired and cannot be joined."
            )
        
        # Check if the user has already opted into this challenge - without filtering by status
        existing_completion = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == current_user.id,
            ChallengeCompletion.challenge_id == challenge_id
        ).first()
        
        if existing_completion:
            return format_challenge_completion_response(existing_completion)  # Use helper function
        
        # Format initial notes with timestamp
        initial_note = None
        if notes:
            current_time = now.strftime("%Y-%m-%d %H:%M")
            initial_note = f"[{current_time}] Opted in - {notes}"
        
        # Create the challenge completion record with the status as an enum, not a string
        challenge_completion = ChallengeCompletion(
            user_id=current_user.id,
            challenge_id=challenge_id,
            status=ChallengeStatus.ACTIVE,  # Use the enum directly, not a string
            progress=0.0,  # Initialize with zero
            notes=initial_note
        )
        
        db.add(challenge_completion)
        db.commit()
        db.refresh(challenge_completion)
        print(f"User {current_user.id} successfully opted into challenge {challenge_id}, completion ID: {challenge_completion.id}")
        
        return format_challenge_completion_response(challenge_completion)  # Use helper function
    except Exception as e:
        print(f"Error in opt_into_challenge: {str(e)}")
        db.rollback()  # Roll back transaction on error
        if "defined enum values" in str(e):
            # This is a specific SQLAlchemy enum error
            raise HTTPException(
                status_code=500,
                detail="Database enum error. The challenge status format is invalid. Please contact support."
            )
        raise

@router.get("/user/{challenge_id}", response_model=ChallengeCompletionWithDetails)
async def get_user_challenge_completion(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    """Get the challenge completion for the current user and a specific challenge"""
    
    try:
        challenge = db.query(Challenge).filter(Challenge.id == challenge_id).first()
        if not challenge:
            raise HTTPException(status_code=404, detail="Challenge not found")
            
        completion = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == current_user.id,
            ChallengeCompletion.challenge_id == challenge_id
        ).first()
        
        if not completion:
            raise HTTPException(status_code=404, detail="Challenge completion not found")
            
        # Get related results for this completion
        results = db.query(ChallengeResult).filter(
            ChallengeResult.completion_id == completion.id
        ).order_by(desc(ChallengeResult.submitted_at)).all()
        
        # Create the response with completion and results data
        response = {
            "id": completion.id,
            "user_id": completion.user_id,
            "challenge_id": completion.challenge_id,
            "status": completion.status.value,
            "progress": completion.progress,
            "notes": completion.notes,
            "completed_at": completion.completed_at,
            "verified_by": completion.verified_by,
            "created_at": completion.created_at,
            "updated_at": completion.updated_at,
            "challenge": {
                "id": challenge.id,
                "title": challenge.title,
                "description": challenge.description,
                "category": challenge.category,
                "difficulty": challenge.difficulty,
                "points": challenge.points,
                "criteria": challenge.criteria,
                "start_date": challenge.start_date,
                "end_date": challenge.end_date
            },
            "results": [
                {
                    "id": result.id,
                    "result_value": result.result_value,
                    "notes": result.notes,
                    "submitted_at": result.submitted_at
                } for result in results
            ]
        }
        
        return response
            
    except Exception as e:
        print(f"Error in get_user_challenge_completion: {str(e)}")
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/user", response_model=List[ChallengeCompletionWithDetails])
async def get_challenge_completions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    """Get all challenge completions for the current user"""
    
    try:
        completions = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == current_user.id
        ).all()
        
        result = []
        for completion in completions:
            challenge = db.query(Challenge).filter(Challenge.id == completion.challenge_id).first()
            if not challenge:
                continue  # Skip if challenge not found
                
            # Get related results for this completion
            results = db.query(ChallengeResult).filter(
                ChallengeResult.completion_id == completion.id
            ).order_by(desc(ChallengeResult.submitted_at)).all()
            
            result.append({
                "id": completion.id,
                "user_id": completion.user_id,
                "challenge_id": completion.challenge_id,
                "status": completion.status.value,
                "progress": completion.progress,
                "notes": completion.notes,
                "completed_at": completion.completed_at,
                "verified_by": completion.verified_by,
                "created_at": completion.created_at,
                "updated_at": completion.updated_at,
                "challenge": {
                    "id": challenge.id,
                    "title": challenge.title,
                    "description": challenge.description,
                    "category": challenge.category,
                    "difficulty": challenge.difficulty,
                    "points": challenge.points,
                    "criteria": challenge.criteria,
                    "start_date": challenge.start_date,
                    "end_date": challenge.end_date
                },
                "results": [
                    {
                        "id": result.id,
                        "result_value": result.result_value,
                        "notes": result.notes,
                        "submitted_at": result.submitted_at
                    } for result in results
                ]
            })
            
        return result
            
    except Exception as e:
        print(f"Error in get_challenge_completions: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/submit-result/{challenge_id}", response_model=ChallengeResultResponse)
async def submit_challenge_result(
    challenge_id: int,
    result_value: float,
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Debug info
    print(f"Submitting result for challenge {challenge_id}, user {current_user.id}, result value: {result_value}")
    
    try:
        # First check if the challenge exists
        challenge = db.query(Challenge).filter(Challenge.id == challenge_id).first()
        if not challenge:
            raise HTTPException(status_code=404, detail="Challenge not found")
            
        # Check if challenge is expired based on end_date
        now = datetime.utcnow()
        if challenge.end_date and challenge.end_date < now:
            raise HTTPException(
                status_code=400,
                detail="This challenge has expired and cannot be updated."
            )
        
        # Find the challenge completion record
        completion = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == current_user.id,
            ChallengeCompletion.challenge_id == challenge_id
        ).first()
        
        if not completion:
            # If no completion record exists, create one for this user
            completion = ChallengeCompletion(
                user_id=current_user.id,
                challenge_id=challenge_id,
                status=ChallengeStatus.ACTIVE,
                progress=0.0,  # Initial progress is 0
                notes="Opted in automatically when submitting result"
            )
            db.add(completion)
            db.commit()
            db.refresh(completion)
            print(f"Created new completion record with ID {completion.id}")
        
        # Create a new result record
        new_result = ChallengeResult(
            completion_id=completion.id,
            result_value=result_value,
            notes=notes,
            submitted_at=now
        )
        
        db.add(new_result)
        
        # Update the progress field on the completion record with the best result so far
        # Get all results for this completion, including the new one
        db.flush()  # Ensure new_result has an ID
        
        # Update the completion's progress field with the new result value
        # This keeps the progress field updated with the latest result for backward compatibility
        completion.progress = result_value
        completion.updated_at = now
        
        db.commit()
        db.refresh(new_result)
        db.refresh(completion)
        
        print(f"Created new result record with ID {new_result.id} for completion {completion.id}")
        
        # Return the new result
        return {
            "id": new_result.id,
            "completion_id": new_result.completion_id,
            "result_value": new_result.result_value,
            "notes": new_result.notes,
            "submitted_at": new_result.submitted_at
        }
    except Exception as e:
        print(f"Error in submit_challenge_result: {str(e)}")
        db.rollback()  # Roll back transaction on error
        if "defined enum values" in str(e):
            # This is a specific SQLAlchemy enum error
            raise HTTPException(
                status_code=500,
                detail="Database enum error. The challenge status format is invalid. Please contact support."
            )
        raise

@router.patch("/verify/{completion_id}", response_model=ChallengeCompletionResponse)
async def verify_challenge_completion(
    completion_id: int,
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    try:
        # Only coaches can verify challenge completions
        if not current_user.is_coach:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only coaches can verify challenge completions"
            )
        
        # Find the challenge completion
        completion = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.id == completion_id
        ).first()
        
        if not completion:
            raise HTTPException(status_code=404, detail="Challenge completion not found")
        
        # Mark as completed explicitly with the actual enum object, not a string
        completion.status = ChallengeStatus.COMPLETED  # Use the enum object directly
        completion.completed_at = datetime.utcnow()
        completion.verified_by = current_user.id
        
        # Add coach verification notes
        current_time = datetime.utcnow().strftime("%Y-%m-%d %H:%M")
        verification_note = f"[{current_time}] Verified by coach {current_user.id}"
        if notes:
            verification_note += f": {notes}"
        
        # Append verification note to existing notes
        if completion.notes:
            completion.notes += f"\n{verification_note}"
        else:
            completion.notes = verification_note
        
        # Get the challenge to check if there's a badge to award
        challenge = db.query(Challenge).filter(Challenge.id == completion.challenge_id).first()
        
        # Award badge if applicable
        if challenge and challenge.badge_id:
            # Check if the user already has this badge
            existing_achievement = db.query(Achievement).filter(
                Achievement.user_id == completion.user_id,
                Achievement.badge_id == challenge.badge_id
            ).first()
            
            if not existing_achievement:
                # Create new achievement
                achievement = Achievement(
                    user_id=completion.user_id,
                    badge_id=challenge.badge_id,
                    awarded_by=current_user.id,
                    earned_at=datetime.utcnow()
                )
                db.add(achievement)
                print(f"Awarded badge {challenge.badge_id} to user {completion.user_id}")
        
        db.commit()
        db.refresh(completion)
        print(f"Verified completion with ID {completion.id}, final result: {completion.progress}")
        
        return format_challenge_completion_response(completion)  # Use helper function
    except Exception as e:
        print(f"Error in verify_challenge_completion: {str(e)}")
        db.rollback()  # Roll back transaction on error
        if "defined enum values" in str(e):
            # This is a specific SQLAlchemy enum error
            raise HTTPException(
                status_code=500,
                detail="Database enum error. The challenge status format is invalid. Please contact support."
            )
        raise

# -------------- Badges and Achievements Endpoints --------------

@router.get("/badges", response_model=List[BadgeWithChallenge])
async def get_user_badges(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    badges = db.query(Badge).all()
    
    # Filter to only include badges that have been earned by the current user
    user_achievements = db.query(Achievement).filter(Achievement.user_id == current_user.id).all()
    user_badge_ids = [a.badge_id for a in user_achievements]
    
    user_badges = [badge for badge in badges if badge.id in user_badge_ids]
    
    return user_badges

@router.get("/badge-stats", response_model=Dict[str, int])
async def get_badge_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get all challenges to get their categories
    challenges = db.query(Challenge).all()
    challenge_categories = {c.id: c.category for c in challenges}
    
    # Get all badges earned by the user through achievements
    user_achievements = db.query(Achievement).filter(Achievement.user_id == current_user.id).all()
    user_badges = db.query(Badge).filter(Badge.id.in_([a.badge_id for a in user_achievements])).all()
    
    # Group badges by challenge category based on which challenge they're associated with
    category_counts = {}
    for badge in user_badges:
        # Find challenges that use this badge
        badge_challenges = [c for c in challenges if c.badge_id == badge.id]
        if badge_challenges:
            for challenge in badge_challenges:
                category = challenge.category
                category_counts[category] = category_counts.get(category, 0) + 1
        else:
            category_counts["Other"] = category_counts.get("Other", 0) + 1
    
    return category_counts

@router.post("/achievements", response_model=AchievementResponse)
def create_achievement(
    achievement: AchievementCreate,
    current_user: User = Depends(get_current_user_dependency),
    db: Session = Depends(get_db)
):
    # Verify player ownership (only for coaches or self)
    if achievement.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db_achievement = Achievement(**achievement.dict())
    db.add(db_achievement)
    db.commit()
    db.refresh(db_achievement)
    return db_achievement

@router.get("/achievements", response_model=List[AchievementResponse])
def read_achievements(
    user_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user_dependency),
    db: Session = Depends(get_db)
):
    # If no user_id provided, use current user's id
    user_id = user_id or current_user.id
    
    # Verify access rights (only for coaches or self)
    if user_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    achievements = db.query(Achievement).filter(
        Achievement.user_id == user_id
    ).offset(skip).limit(limit).all()
    return achievements

@router.get("/active", response_model=List[ChallengeResponse])
async def get_active_challenges(
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Start with base query - only active challenges
    query = db.query(Challenge).filter(Challenge.is_active == True)
    
    # Apply category filter if provided
    if category:
        query = query.filter(Challenge.category == category)
    
    # Apply difficulty filter if provided
    if difficulty:
        query = query.filter(Challenge.difficulty == difficulty)
    
    # For non-expired challenges, end_date should be None or in the future
    now = datetime.utcnow()
    query = query.filter(
        (Challenge.end_date == None) | (Challenge.end_date > now)
    )
    
    challenges = query.all()
    return challenges

@router.get("/results/{completion_id}", response_model=List[ChallengeResultResponse])
async def get_challenge_results(
    completion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    """Get all results for a specific challenge completion"""
    
    try:
        # First check if the completion exists and belongs to the user
        completion = db.query(ChallengeCompletion).filter(
            ChallengeCompletion.id == completion_id,
            ChallengeCompletion.user_id == current_user.id
        ).first()
        
        if not completion:
            raise HTTPException(status_code=404, detail="Challenge completion not found or you don't have access to it")
            
        # Get all results for this completion
        results = db.query(ChallengeResult).filter(
            ChallengeResult.completion_id == completion_id
        ).order_by(desc(ChallengeResult.submitted_at)).all()
        
        # Format the results
        return [
            {
                "id": result.id,
                "completion_id": result.completion_id,
                "result_value": result.result_value,
                "notes": result.notes,
                "submitted_at": result.submitted_at
            } for result in results
        ]
            
    except Exception as e:
        print(f"Error in get_challenge_results: {str(e)}")
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))

