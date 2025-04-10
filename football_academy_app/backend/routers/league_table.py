from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import func, desc, asc

from models import User, LeagueTableEntry, ChallengeEntry, Test, TestEntry, Challenge, ChallengeCompletion, ChallengeResult
from database import get_db
from services.auth import get_current_user_dependency
from schemas import LeagueTableEntryResponse
from schemas import ChallengeLeagueTableEntry, ChallengeLeagueTableResponse

router = APIRouter(
    prefix="/league-table",
    tags=["league_table"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

@router.get("/", response_model=List[LeagueTableEntryResponse])
async def get_league_table(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get all league table entries
    league_entries = db.query(LeagueTableEntry).filter(
    ).all()
    
    # If there are no entries, return empty list
    if not league_entries:
        return []
    
    # Sort entries by total points (descending)
    league_entries.sort(key=lambda x: x.total_points, reverse=True)
    
    # Update rankings
    for i, entry in enumerate(league_entries):
        entry.rank = i + 1
    
    db.commit()
    
    return league_entries

@router.get("/user/{user_id}", response_model=LeagueTableEntryResponse)
async def get_user_league_entry(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get user's league table entry
    league_entry = db.query(LeagueTableEntry).filter(
        LeagueTableEntry.user_id == user_id,
    ).first()
    
    if not league_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="League table entry not found for this user"
        )
    
    return league_entry

@router.post("/recalculate", response_model=List[LeagueTableEntryResponse])
async def recalculate_league_table(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can recalculate the league table"
        )
    
    # Get all active players
    players = db.query(User).filter(
        User.is_active == True,
        User.is_coach == False
    ).all()
    
    # Process each player
    for player in players:
        # Calculate challenge points
        challenge_points = db.query(ChallengeEntry).filter(
            ChallengeEntry.user_id == player.id,
            ChallengeEntry.status == "approved"
        ).with_entities(ChallengeEntry.points_awarded).all()
        
        total_challenge_points = sum(point[0] for point in challenge_points) if challenge_points else 0
        
        # Calculate test points
        test_entries = db.query(TestEntry, Test).join(
            Test, TestEntry.test_id == Test.id
        ).filter(
            TestEntry.user_id == player.id
        ).all()
        
        total_test_points = int(sum(entry.score * test.points_scale for entry, test in test_entries)) if test_entries else 0
        
        # Get or create league table entry
        league_entry = db.query(LeagueTableEntry).filter(
            LeagueTableEntry.user_id == player.id,
        ).first()
        
        if not league_entry:
            league_entry = LeagueTableEntry(
                user_id=player.id,
                challenge_points=total_challenge_points,
                test_points=total_test_points,
                total_points=total_challenge_points + total_test_points,
                last_calculated=datetime.utcnow()
            )
            db.add(league_entry)
        else:
            league_entry.challenge_points = total_challenge_points
            league_entry.test_points = total_test_points
            league_entry.total_points = total_challenge_points + total_test_points
            league_entry.last_calculated = datetime.utcnow()
    
    db.commit()
    
    # Get all entries and sort by total points
    league_entries = db.query(LeagueTableEntry).filter(
    ).all()
    
    league_entries.sort(key=lambda x: x.total_points, reverse=True)
    
    # Update rankings
    for i, entry in enumerate(league_entries):
        entry.rank = i + 1
    
    db.commit()
    
    return league_entries

    # Get all active players
    players = db.query(User).filter(
        User.is_active == True,
        User.is_coach == False
    ).all()
    

@router.get("/challenge/{challenge_id}", response_model=ChallengeLeagueTableResponse)
async def get_challenge_league_table(
    challenge_id: int,
    sort_order: str = "desc",  # 'asc' for lowest-is-best metrics (like time), 'desc' for highest-is-best (like counts)
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    """
    Create a league table for a specific challenge showing the best result from each user.
    For challenges where higher is better (like number of juggles), use sort_order='desc'.
    For challenges where lower is better (like time), use sort_order='asc'.
    """
    # First check if the challenge exists
    challenge = db.query(Challenge).filter(Challenge.id == challenge_id).first()
    if not challenge:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Challenge with ID {challenge_id} not found"
        )
    
    # Use a CTE (Common Table Expression) to find the best result for each user
    # This subquery finds the result with the maximum or minimum value for each user
    if sort_order.lower() == "desc":
        # For metrics where higher is better (e.g., number of juggles, points)
        # First get the max value for each user
        max_values = db.query(
            ChallengeCompletion.user_id,
            func.max(ChallengeResult.result_value).label("best_result")
        ).join(
            ChallengeResult, ChallengeResult.completion_id == ChallengeCompletion.id
        ).filter(
            ChallengeCompletion.challenge_id == challenge_id
        ).group_by(
            ChallengeCompletion.user_id
        ).subquery()
        
        # Then find the actual result records that match these max values
        best_results = db.query(
            ChallengeCompletion.user_id,
            ChallengeResult.result_value.label("best_result"),
            ChallengeResult.submitted_at
        ).join(
            ChallengeResult, ChallengeResult.completion_id == ChallengeCompletion.id
        ).join(
            max_values, 
            (ChallengeCompletion.user_id == max_values.c.user_id) & 
            (ChallengeResult.result_value == max_values.c.best_result)
        ).filter(
            ChallengeCompletion.challenge_id == challenge_id
        ).subquery()
    else:
        # For metrics where lower is better (e.g., time)
        # First get the min value for each user
        min_values = db.query(
            ChallengeCompletion.user_id,
            func.min(ChallengeResult.result_value).label("best_result")
        ).join(
            ChallengeResult, ChallengeResult.completion_id == ChallengeCompletion.id
        ).filter(
            ChallengeCompletion.challenge_id == challenge_id
        ).group_by(
            ChallengeCompletion.user_id
        ).subquery()
        
        # Then find the actual result records that match these min values
        best_results = db.query(
            ChallengeCompletion.user_id,
            ChallengeResult.result_value.label("best_result"),
            ChallengeResult.submitted_at
        ).join(
            ChallengeResult, ChallengeResult.completion_id == ChallengeCompletion.id
        ).join(
            min_values, 
            (ChallengeCompletion.user_id == min_values.c.user_id) & 
            (ChallengeResult.result_value == min_values.c.best_result)
        ).filter(
            ChallengeCompletion.challenge_id == challenge_id
        ).subquery()

    # Now join with the users table to get user information
    results = db.query(
        User.user_id,
        User.full_name,
        User.position,
        User.current_club,
        best_results.c.best_result,
        best_results.c.submitted_at
    ).join(
        best_results, User.user_id == best_results.c.user_id
    )
    
    # Sort the results
    if sort_order.lower() == "desc":
        results = results.order_by(desc(best_results.c.best_result))
    else:
        results = results.order_by(asc(best_results.c.best_result))
    
    # Execute query and format results
    league_entries = []
    for idx, (user_id, full_name, position, current_club, best_result, submitted_at) in enumerate(results.all()):
        league_entries.append({
            "user_id": user_id,
            "full_name": full_name,
            "position": position,
            "current_club": current_club,
            "best_result": best_result,
            "submitted_at": submitted_at,
            "rank": idx + 1  # Add rank based on the sorted order
        })
    
    return {
        "challenge_id": challenge.id,
        "challenge_title": challenge.title,
        "challenge_description": challenge.description,
        "entries": league_entries
    } 