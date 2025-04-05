from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from models import User, LeagueTableEntry, ChallengeEntry, Test, TestEntry
from database import get_db
from services.auth import get_current_user_dependency
from schemas import LeagueTableEntry as LeagueTableEntrySchema

router = APIRouter(
    prefix="/league-table",
    tags=["league_table"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

@router.get("/", response_model=List[LeagueTableEntrySchema])
async def get_league_table(
    season: Optional[str] = "current",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get all league table entries
    league_entries = db.query(LeagueTableEntry).filter(
        LeagueTableEntry.season == season
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

@router.get("/user/{user_id}", response_model=LeagueTableEntrySchema)
async def get_user_league_entry(
    user_id: int,
    season: Optional[str] = "current",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get user's league table entry
    league_entry = db.query(LeagueTableEntry).filter(
        LeagueTableEntry.user_id == user_id,
        LeagueTableEntry.season == season
    ).first()
    
    if not league_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="League table entry not found for this user"
        )
    
    return league_entry

@router.post("/recalculate", response_model=List[LeagueTableEntrySchema])
async def recalculate_league_table(
    season: Optional[str] = "current",
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
            LeagueTableEntry.season == season
        ).first()
        
        if not league_entry:
            league_entry = LeagueTableEntry(
                user_id=player.id,
                season=season,
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
        LeagueTableEntry.season == season
    ).all()
    
    league_entries.sort(key=lambda x: x.total_points, reverse=True)
    
    # Update rankings
    for i, entry in enumerate(league_entries):
        entry.rank = i + 1
    
    db.commit()
    
    return league_entries

@router.post("/seasons/{season_name}", status_code=status.HTTP_201_CREATED)
async def create_new_season(
    season_name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create new seasons"
        )
    
    # Check if season already exists
    existing_entries = db.query(LeagueTableEntry).filter(
        LeagueTableEntry.season == season_name
    ).count()
    
    if existing_entries > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Season '{season_name}' already exists"
        )
    
    # Get all active players
    players = db.query(User).filter(
        User.is_active == True,
        User.is_coach == False
    ).all()
    
    # Create new season entries for all players
    for player in players:
        new_entry = LeagueTableEntry(
            user_id=player.id,
            season=season_name,
            challenge_points=0,
            test_points=0,
            total_points=0,
            rank=0,
            last_calculated=datetime.utcnow()
        )
        db.add(new_entry)
    
    db.commit()
    
    return {"message": f"Season '{season_name}' created successfully"}

@router.get("/seasons", response_model=List[str])
async def get_seasons(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_dependency)
):
    # Get distinct season values
    seasons = db.query(LeagueTableEntry.season).distinct().all()
    return [season[0] for season in seasons] 