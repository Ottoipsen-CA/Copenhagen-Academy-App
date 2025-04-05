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
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized"}
    },
)

# Complete a challenge
@router.post(
    "/complete", 
    response_model=schemas.ChallengeCompletion,
    summary="Complete a challenge",
    description="Record a completed challenge for the current user and award a badge if applicable",
    responses={
        200: {
            "description": "Challenge completed successfully",
            "content": {
                "application/json": {
                    "example": {
                        "id": 1,
                        "player_id": 5,
                        "challenge_id": 3,
                        "completion_time": 120,
                        "score": 95,
                        "stats": {"passes": 25, "shots": 10, "goals": 3},
                        "completion_date": "2023-03-15T14:30:00"
                    }
                }
            }
        },
        404: {"description": "Challenge not found"}
    }
)
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
@router.get(
    "/completions", 
    response_model=List[schemas.ChallengeCompletionWithDetails],
    summary="Get user's challenge completions",
    description="Retrieve all challenge completions for the currently authenticated user",
    responses={
        200: {
            "description": "List of all challenge completions",
            "content": {
                "application/json": {
                    "example": [
                        {
                            "id": 1,
                            "player_id": 5,
                            "challenge_id": 3,
                            "challenge": {
                                "id": 3,
                                "name": "Accuracy Challenge",
                                "description": "Complete 10 accurate passes",
                                "category": "passing"
                            },
                            "completion_time": 120,
                            "score": 95,
                            "stats": {"passes": 25, "shots": 10, "goals": 3},
                            "completion_date": "2023-03-15T14:30:00"
                        }
                    ]
                }
            }
        }
    }
)
async def get_user_completions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    completions = db.query(models.ChallengeCompletion).filter(
        models.ChallengeCompletion.player_id == current_user.id
    ).all()
    
    return completions

# Get completion details for a specific challenge
@router.get(
    "/completions/{challenge_id}", 
    response_model=List[schemas.ChallengeCompletion],
    summary="Get completions for a specific challenge",
    description="Retrieve all completions for a specific challenge by the currently authenticated user",
    responses={
        200: {
            "description": "List of challenge completions for the specified challenge",
            "content": {
                "application/json": {
                    "example": [
                        {
                            "id": 1,
                            "player_id": 5,
                            "challenge_id": 3,
                            "completion_time": 120,
                            "score": 95,
                            "stats": {"passes": 25, "shots": 10, "goals": 3},
                            "completion_date": "2023-03-15T14:30:00"
                        }
                    ]
                }
            }
        },
        404: {"description": "No completions found for this challenge"}
    }
)
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
@router.get(
    "/badges", 
    response_model=List[schemas.BadgeWithChallenge],
    summary="Get user's badges",
    description="Retrieve all badges earned by the currently authenticated user",
    responses={
        200: {
            "description": "List of all badges earned by the user",
            "content": {
                "application/json": {
                    "example": [
                        {
                            "id": 1,
                            "player_id": 5,
                            "challenge_id": 3,
                            "name": "Accuracy Master",
                            "description": "Awarded for completing the Accuracy Challenge",
                            "image_url": "/badges/accuracy_badge.png",
                            "earned_at": "2023-03-15T14:30:00",
                            "challenge": {
                                "id": 3,
                                "name": "Accuracy Challenge",
                                "description": "Complete 10 accurate passes",
                                "category": "passing"
                            }
                        }
                    ]
                }
            }
        }
    }
)
async def get_user_badges(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    badges = db.query(models.Badge).filter(
        models.Badge.player_id == current_user.id
    ).all()
    
    return badges

# Get all badge stats (count by category)
@router.get(
    "/badge-stats", 
    response_model=Dict[str, int],
    summary="Get badge statistics",
    description="Retrieve statistics about badges earned by the currently authenticated user, grouped by category",
    responses={
        200: {
            "description": "Badge counts by category",
            "content": {
                "application/json": {
                    "example": {
                        "passing": 3,
                        "shooting": 2,
                        "dribbling": 1,
                        "fitness": 4
                    }
                }
            }
        }
    }
)
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
@router.get(
    "/statistics", 
    response_model=Dict[str, Any],
    summary="Get user's challenge statistics",
    description="Retrieve comprehensive statistics about challenges completed by the currently authenticated user",
    responses={
        200: {
            "description": "Comprehensive challenge statistics",
            "content": {
                "application/json": {
                    "example": {
                        "total_completed": 15,
                        "best_scores": {
                            "passing": {
                                "challenge_name": "Passing Master",
                                "score": 98,
                                "completion_time": 115,
                                "completion_date": "2023-03-20T16:45:00"
                            },
                            "shooting": {
                                "challenge_name": "Accuracy Shooter",
                                "score": 92,
                                "completion_time": 180,
                                "completion_date": "2023-03-18T12:30:00"
                            }
                        },
                        "recent_completions": [
                            {
                                "challenge_name": "Speed Dribbler",
                                "category": "dribbling",
                                "score": 88,
                                "completion_time": 45,
                                "completion_date": "2023-03-25T09:15:00"
                            }
                        ],
                        "category_counts": {
                            "passing": 5,
                            "shooting": 4,
                            "dribbling": 3,
                            "fitness": 3
                        }
                    }
                }
            }
        }
    }
)
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