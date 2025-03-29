from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any
from sqlalchemy.orm import Session
import json
from datetime import datetime

import models
import schemas
import auth
from database import get_db

router = APIRouter(
    prefix="/challenge-progress",
    tags=["challenge-progress"],
    responses={404: {"description": "Not found"}},
)

# Complete a challenge
@router.post("/complete", response_model=schemas.ChallengeCompletion)
async def complete_challenge(
    completion: schemas.ChallengeCompletionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Check if the challenge exists
    challenge = db.query(models.Challenge).filter(models.Challenge.id == completion.challenge_id).first()
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    # Create the challenge completion record
    challenge_completion = models.ChallengeCompletion(
        player_id=current_user.id,
        challenge_id=completion.challenge_id,
        completion_time=completion.completion_time,
        score=completion.score,
        stats=completion.stats,
        completion_date=datetime.utcnow()
    )
    
    db.add(challenge_completion)
    db.commit()
    db.refresh(challenge_completion)
    
    # Award a badge for completing the challenge
    # Check if the user already has a badge for this challenge
    existing_badge = db.query(models.Badge).filter(
        models.Badge.player_id == current_user.id,
        models.Badge.challenge_id == completion.challenge_id
    ).first()
    
    if not existing_badge:
        # Create a new badge
        new_badge = models.Badge(
            player_id=current_user.id,
            challenge_id=completion.challenge_id,
            name=f"{challenge.name} Badge",
            description=f"Awarded for completing the {challenge.name} challenge",
            image_url=challenge.badge_image_url or "/badges/default_badge.png",
            earned_at=datetime.utcnow()
        )
        
        db.add(new_badge)
        db.commit()
    
    return challenge_completion

# Get completions for current user
@router.get("/completions", response_model=List[schemas.ChallengeCompletionWithDetails])
async def get_user_completions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    completions = db.query(models.ChallengeCompletion).filter(
        models.ChallengeCompletion.player_id == current_user.id
    ).all()
    
    return completions

# Get completion details for a specific challenge
@router.get("/completions/{challenge_id}", response_model=List[schemas.ChallengeCompletion])
async def get_challenge_completions(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    completions = db.query(models.ChallengeCompletion).filter(
        models.ChallengeCompletion.player_id == current_user.id,
        models.ChallengeCompletion.challenge_id == challenge_id
    ).all()
    
    if not completions:
        raise HTTPException(status_code=404, detail="No completions found for this challenge")
    
    return completions

# Get all badges for current user
@router.get("/badges", response_model=List[schemas.BadgeWithChallenge])
async def get_user_badges(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    badges = db.query(models.Badge).filter(
        models.Badge.player_id == current_user.id
    ).all()
    
    return badges

# Get all badge stats (count by category)
@router.get("/badge-stats", response_model=Dict[str, int])
async def get_badge_stats(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Get all user badges with their associated challenges
    badges_with_challenges = db.query(models.Badge, models.Challenge).join(
        models.Challenge, models.Badge.challenge_id == models.Challenge.id
    ).filter(
        models.Badge.player_id == current_user.id
    ).all()
    
    # Count badges by category
    badge_counts = {}
    for badge, challenge in badges_with_challenges:
        category = challenge.category
        if category in badge_counts:
            badge_counts[category] += 1
        else:
            badge_counts[category] = 1
    
    return badge_counts

# Get challenge statistics for a user
@router.get("/statistics", response_model=Dict[str, Any])
async def get_challenge_statistics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Get all completions for the user
    completions = db.query(models.ChallengeCompletion).filter(
        models.ChallengeCompletion.player_id == current_user.id
    ).all()
    
    # Get all challenges completed by the user
    completed_challenges = db.query(models.Challenge).join(
        models.ChallengeCompletion, models.Challenge.id == models.ChallengeCompletion.challenge_id
    ).filter(
        models.ChallengeCompletion.player_id == current_user.id
    ).distinct().all()
    
    # Total number of challenges completed
    total_completed = len(completed_challenges)
    
    # Best scores by category
    best_scores = {}
    for completion in completions:
        challenge = db.query(models.Challenge).filter(
            models.Challenge.id == completion.challenge_id
        ).first()
        
        if not challenge:
            continue
            
        category = challenge.category
        if category not in best_scores or completion.score > best_scores[category]["score"]:
            best_scores[category] = {
                "challenge_name": challenge.name,
                "score": completion.score,
                "completion_time": completion.completion_time,
                "completion_date": completion.completion_date
            }
    
    # Recent completions (last 5)
    recent_completions = db.query(models.ChallengeCompletion, models.Challenge).join(
        models.Challenge, models.ChallengeCompletion.challenge_id == models.Challenge.id
    ).filter(
        models.ChallengeCompletion.player_id == current_user.id
    ).order_by(
        models.ChallengeCompletion.completion_date.desc()
    ).limit(5).all()
    
    recent_completions_data = [{
        "challenge_name": challenge.name,
        "category": challenge.category,
        "score": completion.score,
        "completion_time": completion.completion_time,
        "completion_date": completion.completion_date
    } for completion, challenge in recent_completions]
    
    # Completion counts by category
    category_counts = {}
    for challenge in completed_challenges:
        if challenge.category in category_counts:
            category_counts[challenge.category] += 1
        else:
            category_counts[challenge.category] = 1
    
    return {
        "total_completed": total_completed,
        "best_scores": best_scores,
        "recent_completions": recent_completions_data,
        "category_counts": category_counts
    } 