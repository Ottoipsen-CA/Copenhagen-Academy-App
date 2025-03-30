from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
import sys
import os
from datetime import datetime

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

router = APIRouter(
    prefix="/player-stats",
    tags=["player_stats"]
)

@router.post("/", response_model=schemas.PlayerStat)
def create_player_stats(
    player_stats: schemas.PlayerStatCreate = Body(...),  # <-- 🔧 fix her
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    if player_stats.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    existing_stats = db.query(models.PlayerStats).filter(
        models.PlayerStats.player_id == player_stats.player_id
    ).first()
    
    if existing_stats:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Player stats already exist"
        )
    
    db_player_stats = models.PlayerStats(**player_stats.dict())
    db.add(db_player_stats)
    db.commit()
    db.refresh(db_player_stats)
    return db_player_stats

@router.get("/{player_id}", response_model=schemas.PlayerStatsResponse)
async def get_player_stats(
    player_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Authorization check - only allow users to access their own stats
    # or admins to access anyone's stats
    if player_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this player's stats"
        )
    
    # Get player stats from database
    stats = db.query(models.PlayerStats).filter(
        models.PlayerStats.player_id == player_id
    ).first()
    
    if not stats:
        # If no stats exist yet, create default stats
        print(f"Creating default player stats for player {player_id}")
        stats = models.PlayerStats(
            player_id=player_id,
            pace=50,
            shooting=50,
            passing=50,
            dribbling=50,
            defense=50,
            physical=50,
            overall_rating=50,
            last_updated=datetime.utcnow()
        )
        db.add(stats)
        db.commit()
        db.refresh(stats)
    
    print(f"Returning player stats for player {player_id}: pace={stats.pace}, shooting={stats.shooting}, passing={stats.passing}, overall={stats.overall_rating}")
    return stats

@router.put("/{player_id}", response_model=schemas.PlayerStat)
def update_player_stats(
    player_id: int,
    stats_update: schemas.PlayerStatBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    if player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db_player_stats = db.query(models.PlayerStats).filter(
        models.PlayerStats.player_id == player_id
    ).first()
    if db_player_stats is None:
        raise HTTPException(status_code=404, detail="Player stats not found")
    
    for field, value in stats_update.dict().items():
        setattr(db_player_stats, field, value)
    
    db.commit()
    db.refresh(db_player_stats)
    return db_player_stats

@router.delete("/{player_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_player_stats(
    player_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    if player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    player_stats = db.query(models.PlayerStats).filter(
        models.PlayerStats.player_id == player_id
    ).first()
    if player_stats is None:
        raise HTTPException(status_code=404, detail="Player stats not found")
    
    db.delete(player_stats)
    db.commit()
    return None
