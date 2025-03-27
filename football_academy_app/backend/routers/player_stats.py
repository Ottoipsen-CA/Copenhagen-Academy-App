from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import sys
import os

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

router = APIRouter(
    prefix="/player-stats",
    tags=["player_stats"]
)

@router.post("/", response_model=schemas.PlayerStats)
def create_player_stats(
    player_stats: schemas.PlayerStatsCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify player ownership
    if player_stats.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    # Check if stats already exist
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

@router.get("/{player_id}", response_model=schemas.PlayerStats)
def read_player_stats(
    player_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify access rights
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
    return player_stats

@router.put("/{player_id}", response_model=schemas.PlayerStats)
def update_player_stats(
    player_id: int,
    stats_update: schemas.PlayerStatsBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify access rights
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
    # Verify access rights
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