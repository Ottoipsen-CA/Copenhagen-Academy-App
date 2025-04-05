from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import and_

from models import (
    User, Challenge, ChallengeStatus, ChallengeCompletion, 
    Badge, PlayerStats, Achievement
)
from database import get_db
from services.auth import get_current_user_dependency
from schemas import (
    ChallengeCreate, ChallengeResponse, ChallengeWithStatus,
    ChallengeStatusResponse, ChallengeCompletionCreate, ChallengeCompletionResponse,
    ChallengeCompletionWithDetails, BadgeWithChallenge, AchievementCreate, AchievementResponse
)

router = APIRouter(
    prefix="/challenges",
    tags=["challenges"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

# -------------- Challenge Management Endpoints --------------

@router.post("/", response_model=ChallengeResponse, status_code=status.HTTP_201_CREATED)
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
    
    db_challenge = Challenge(**challenge.dict())
    db.add(db_challenge)
    db.commit()
    db.refresh(db_challenge)
    return db_challenge

@router.get("/", response_model=List[ChallengeResponse])
async def get_all_challenges(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    challenges = db.query(Challenge).all()
    return challenges

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

@router.post("/complete/{challenge_id}", response_model=ChallengeStatusResponse)
async def complete_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # 1. Find challenge
    challenge = db.query(Challenge).filter(Challenge.id == challenge_id).first()
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    # 2. Check challenge status
    challenge_status = db.query(ChallengeStatus).filter(
        ChallengeStatus.user_id == current_user.id,
        ChallengeStatus.challenge_id == challenge_id
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
    stats = db.query(PlayerStats).filter(PlayerStats.player_id == current_user.id).first()
    
    # Create stats if they don't exist
    if not stats:
        stats = PlayerStats(
            player_id=current_user.id,
            pace=50, shooting=50, passing=50, dribbling=50, juggles=50, first_touch=50,
            overall_rating=60,
            last_updated=now
        )
        db.add(stats)
    
    # Determine which stat to improve based on challenge category
    xp_boost = challenge.xp_reward  # Base XP boost from the challenge
    base_boost = xp_boost * 2  # Overall rating boost
    specific_boost = xp_boost * 5  # Larger boost for the specific skill
    
    # Update specific attribute based on challenge category
    if challenge.category.lower() == "passing":
        stats.passing += specific_boost
        stats.first_touch += specific_boost * 0.5
    elif challenge.category.lower() == "shooting":
        stats.shooting += specific_boost
    elif challenge.category.lower() == "dribbling":
        stats.dribbling += specific_boost
        stats.first_touch += specific_boost * 0.3
    elif challenge.category.lower() == "fitness":
        stats.pace += specific_boost 
    elif challenge.category.lower() == "juggles":
        stats.juggles += specific_boost
        stats.first_touch += specific_boost * 0.3
    elif challenge.category.lower() == "first_touch" or challenge.category.lower() == "first touch":
        stats.first_touch += specific_boost
        stats.dribbling += specific_boost * 0.3
    elif challenge.category.lower() == "tactical":
        # Tactical challenges improve all stats
        all_stats_boost = specific_boost / 2
        stats.passing += all_stats_boost
        stats.shooting += all_stats_boost
        stats.dribbling += all_stats_boost
        stats.pace += all_stats_boost
        stats.juggles += all_stats_boost
        stats.first_touch += all_stats_boost
    
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
    
    # Update the last_updated timestamp
    stats.last_updated = now
    
    # 5. Unlock next challenge in the progression if available
    next_challenge = db.query(Challenge).filter(
        Challenge.prerequisite_id == challenge_id
    ).first()
    
    if next_challenge:
        # Check if player already has a status for this challenge
        next_status = db.query(ChallengeStatus).filter(
            ChallengeStatus.user_id == current_user.id,
            ChallengeStatus.challenge_id == next_challenge.id
        ).first()
        
        if not next_status:
            # Create new status record
            next_status = ChallengeStatus(
                user_id=current_user.id,
                challenge_id=next_challenge.id,
                status="AVAILABLE",
                unlocked_at=now
            )
            db.add(next_status)
        else:
            # Update existing status record
            next_status.status = "AVAILABLE"
            next_status.unlocked_at = now
    
    db.commit()
    db.refresh(challenge_status)
    return challenge_status

# -------------- Challenge Completion Endpoints --------------

@router.post("/completion", response_model=ChallengeCompletionResponse)
async def record_challenge_completion(
    completion: ChallengeCompletionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Check if the challenge exists
    challenge = db.query(Challenge).filter(Challenge.id == completion.challenge_id).first()
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    # Create the challenge completion record
    challenge_completion = ChallengeCompletion(
        user_id=current_user.id,
        challenge_id=completion.challenge_id,
        status=ChallengeStatus.ACTIVE,
        progress=0.0,
        notes=completion.notes if hasattr(completion, 'notes') else None
    )
    
    db.add(challenge_completion)
    db.commit()
    db.refresh(challenge_completion)
    
    # Award a badge for completing the challenge
    # Check if the user already has a badge for this challenge
    existing_badge = db.query(Badge).filter(
        Badge.user_id == current_user.id,
        Badge.id == challenge.badge_id
    ).first()
    
    if not existing_badge and challenge.badge_id:
        # Create a new badge award (Achievement)
        new_achievement = Achievement(
            user_id=current_user.id,
            badge_id=challenge.badge_id,
            earned_at=datetime.utcnow()
        )
        
        db.add(new_achievement)
        db.commit()
    
    return challenge_completion

@router.get("/completions", response_model=List[ChallengeCompletionWithDetails])
async def get_user_completions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    completions = db.query(ChallengeCompletion).filter(
        ChallengeCompletion.user_id == current_user.id
    ).all()
    
    return completions

@router.get("/completions/{challenge_id}", response_model=List[ChallengeCompletionResponse])
async def get_challenge_completions(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    completions = db.query(ChallengeCompletion).filter(
        ChallengeCompletion.user_id == current_user.id,
        ChallengeCompletion.challenge_id == challenge_id
    ).all()
    
    if not completions:
        raise HTTPException(status_code=404, detail="No completions found for this challenge")
    
    return completions

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

