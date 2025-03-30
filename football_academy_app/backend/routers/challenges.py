from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import and_

import models
import schemas
import auth
from database import get_db

router = APIRouter(
    prefix="/challenges",
    tags=["challenges"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized"}
    },
)

# Get all challenges
@router.get(
    "/", 
    response_model=List[schemas.ChallengeResponse],
    summary="Get all challenges",
    description="Retrieve a list of all available challenges"
)
async def get_all_challenges(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    challenges = db.query(models.Challenge).all()
    return challenges

# Get all challenges with user status
@router.get(
    "/with-status", 
    response_model=List[schemas.ChallengeWithStatus],
    summary="Get all challenges with user status",
    description="Retrieve a list of all challenges with user-specific status information"
)
async def get_challenges_with_status(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Get all challenges and statuses in one query with join
    result = db.query(
        models.Challenge,
        models.ChallengeStatus.status,
        models.ChallengeStatus.unlocked_at,
        models.ChallengeStatus.completed_at
    ).outerjoin(
        models.ChallengeStatus,
        and_(
            models.ChallengeStatus.challenge_id == models.Challenge.id,
            models.ChallengeStatus.user_id == current_user.id
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

# Initialize challenge statuses for a user
@router.post(
    "/initialize-status",
    status_code=status.HTTP_201_CREATED,
    summary="Initialize challenge statuses",
    description="Initialize the status of all challenges for the current user. First level challenges will be available, others locked."
)
async def initialize_challenge_statuses(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Check if statuses already exist
    existing_statuses = db.query(models.ChallengeStatus).filter(
        models.ChallengeStatus.user_id == current_user.id
    ).first()
    
    if existing_statuses:
        raise HTTPException(status_code=400, detail="Challenge statuses already initialized")
    
    # Get all challenges
    challenges = db.query(models.Challenge).all()
    
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
            
            status_record = models.ChallengeStatus(
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

# Complete a challenge
@router.post(
    "/complete/{challenge_id}", 
    response_model=schemas.ChallengeStatusResponse,
    summary="Complete a challenge",
    description="Mark a challenge as completed and unlock the next challenge in the progression"
)
async def complete_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # 1. Find challenge
    challenge = db.query(models.Challenge).filter(models.Challenge.id == challenge_id).first()
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    # 2. Check challenge status
    challenge_status = db.query(models.ChallengeStatus).filter(
        models.ChallengeStatus.user_id == current_user.id,
        models.ChallengeStatus.challenge_id == challenge_id
    ).first()
    
    if not challenge_status:
        raise HTTPException(status_code=404, detail="Challenge status not found")
    
    if challenge_status.status != "AVAILABLE":
        if challenge_status.status == "COMPLETED":
            raise HTTPException(status_code=400, detail="Challenge already completed")
        else:
            raise HTTPException(status_code=400, detail="Challenge is not available")
    
    # 3. Mark challenge as completed
    now = datetime.utcnow()
    challenge_status.status = "COMPLETED"
    challenge_status.completed_at = now
    
    # 4. Update player stats based on challenge category
    stats = db.query(models.PlayerStats).filter(models.PlayerStats.player_id == current_user.id).first()
    
    # Create stats if they don't exist
    if not stats:
        stats = models.PlayerStats(
            player_id=current_user.id,
            pace=50, shooting=50, passing=50, dribbling=50, juggles=50, first_touch=50,
            overall_rating=60,
            last_updated=now
        )
        db.add(stats)
    
    # Print before values for debugging
    print(f"BEFORE - User {current_user.id} stats: pace={stats.pace}, shooting={stats.shooting}, passing={stats.passing}, dribbling={stats.dribbling}, juggles={stats.juggles}, first_touch={stats.first_touch}, overall={stats.overall_rating}")
    
    # Determine which stat to improve based on challenge category
    xp_boost = challenge.xp_reward  # Base XP boost from the challenge
    base_boost = xp_boost * 2  # Increased overall rating boost (was xp_boost/2)
    specific_boost = xp_boost * 5  # Much larger boost for the specific skill (was xp_boost*1.5)
    
    # Update specific attribute based on challenge category
    if challenge.category.lower() == "passing":
        stats.passing += specific_boost
        stats.first_touch += specific_boost * 0.5
        print(f"Improved passing by {specific_boost} and first touch by {specific_boost * 0.5} for user {current_user.id}")
    elif challenge.category.lower() == "shooting":
        stats.shooting += specific_boost
        print(f"Improved shooting by {specific_boost} for user {current_user.id}")
    elif challenge.category.lower() == "dribbling":
        stats.dribbling += specific_boost
        stats.first_touch += specific_boost * 0.3
        print(f"Improved dribbling by {specific_boost} and first touch by {specific_boost * 0.3} for user {current_user.id}")
    elif challenge.category.lower() == "fitness":
        stats.pace += specific_boost 
        print(f"Improved pace by {specific_boost} for user {current_user.id}")
    elif challenge.category.lower() == "juggles":
        stats.juggles += specific_boost
        stats.first_touch += specific_boost * 0.3
        print(f"Improved juggles by {specific_boost} and first touch by {specific_boost * 0.3} for user {current_user.id}")
    elif challenge.category.lower() == "first_touch" or challenge.category.lower() == "first touch":
        stats.first_touch += specific_boost
        stats.dribbling += specific_boost * 0.3
        print(f"Improved first touch by {specific_boost} and dribbling by {specific_boost * 0.3} for user {current_user.id}")
    elif challenge.category.lower() == "tactical":
        # Tactical challenges improve all stats significantly
        all_stats_boost = specific_boost / 2
        stats.passing += all_stats_boost
        stats.shooting += all_stats_boost
        stats.dribbling += all_stats_boost
        stats.pace += all_stats_boost
        stats.juggles += all_stats_boost
        stats.first_touch += all_stats_boost
        print(f"Improved all stats by {all_stats_boost} for user {current_user.id}")
    else:
        # For weekly challenges or other categories, just boost overall rating more
        print(f"Improved overall rating for weekly challenge for user {current_user.id}")
    
    # Make sure no stat goes over 99
    stats.pace = min(stats.pace, 99)
    stats.shooting = min(stats.shooting, 99)
    stats.passing = min(stats.passing, 99)
    stats.dribbling = min(stats.dribbling, 99)
    stats.juggles = min(stats.juggles, 99)
    stats.first_touch = min(stats.first_touch, 99)
    
    # Calculate overall rating as average of all stats
    new_overall = (stats.pace + stats.shooting + stats.passing + stats.dribbling + stats.juggles + stats.first_touch) / 6
    
    # Apply additional base boost to the calculated overall rating
    stats.overall_rating = min(new_overall + base_boost, 99)
    
    print(f"Updated overall rating to {stats.overall_rating} for user {current_user.id}")
    
    # Update the last_updated timestamp
    stats.last_updated = now
    
    # Print after values for debugging
    print(f"AFTER - User {current_user.id} stats: pace={stats.pace}, shooting={stats.shooting}, passing={stats.passing}, dribbling={stats.dribbling}, juggles={stats.juggles}, first_touch={stats.first_touch}, overall={stats.overall_rating}")
    
    # 5. Unlock next challenges (only for non-weekly challenges)
    if not challenge.is_weekly:
        # Check if there's a direct next challenge with this as prerequisite
        next_challenges = db.query(models.Challenge).filter(
            models.Challenge.prerequisite_id == challenge.id
        ).all()
        
        # If there are direct prerequisite relationships, unlock those challenges
        if next_challenges:
            for next_challenge in next_challenges:
                next_status = db.query(models.ChallengeStatus).filter(
                    models.ChallengeStatus.user_id == current_user.id,
                    models.ChallengeStatus.challenge_id == next_challenge.id
                ).first()
                
                if next_status and next_status.status == "LOCKED":
                    next_status.status = "AVAILABLE"
                    next_status.unlocked_at = now
        else:
            # Default to level-based progression
            # Find next level challenges in the same category
            next_level_challenges = db.query(models.Challenge).filter(
                models.Challenge.category == challenge.category,
                models.Challenge.level == challenge.level + 1
            ).all()
            
            # Check if all previous level challenges are completed
            current_level_challenges = db.query(models.Challenge).filter(
                models.Challenge.category == challenge.category,
                models.Challenge.level == challenge.level
            ).all()
            
            current_level_challenge_ids = [c.id for c in current_level_challenges]
            
            completed_count = db.query(models.ChallengeStatus).filter(
                models.ChallengeStatus.user_id == current_user.id,
                models.ChallengeStatus.challenge_id.in_(current_level_challenge_ids),
                models.ChallengeStatus.status == "COMPLETED"
            ).count()
            
            # Only unlock next level if all current level challenges are completed
            if completed_count == len(current_level_challenges):
                for next_challenge in next_level_challenges:
                    next_status = db.query(models.ChallengeStatus).filter(
                        models.ChallengeStatus.user_id == current_user.id,
                        models.ChallengeStatus.challenge_id == next_challenge.id
                    ).first()
                    
                    if next_status and next_status.status == "LOCKED":
                        next_status.status = "AVAILABLE"
                        next_status.unlocked_at = now
    
    db.commit()
    db.refresh(challenge_status)
    
    return challenge_status

# Get challenge by ID
@router.get(
    "/{challenge_id}", 
    response_model=schemas.ChallengeWithStatus,
    summary="Get challenge by ID",
    description="Retrieve details of a specific challenge by its ID along with user status"
)
async def get_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    challenge = db.query(models.Challenge).filter(models.Challenge.id == challenge_id).first()
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    status = db.query(models.ChallengeStatus).filter(
        models.ChallengeStatus.user_id == current_user.id,
        models.ChallengeStatus.challenge_id == challenge_id
    ).first()
    
    # Create response with status information
    result = {
        "id": challenge.id,
        "title": challenge.title,
        "description": challenge.description,
        "xp_reward": challenge.xp_reward,
        "category": challenge.category,
        "is_weekly": challenge.is_weekly,
        "level": challenge.level,
        "prerequisite_id": challenge.prerequisite_id,
        "status": status.status if status else "LOCKED",
        "unlocked_at": status.unlocked_at if status else None,
        "completed_at": status.completed_at if status else None
    }
    
    return result

