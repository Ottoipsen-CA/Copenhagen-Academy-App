from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime

from models.league_table import LeagueTableEntry, ChallengeEntry
from models.skill_tests import PlayerStats
from models.challenges import Challenge, ChallengeCompletion, ChallengeStatus
from schemas.league_table import (
    LeagueTableEntryCreate, LeagueTableEntryUpdate,
    ChallengeEntryCreate, ChallengeEntryUpdate
)
from .base import BaseService

class LeagueTableService:
    def __init__(self, db: Session):
        self.db = db
        self.table_service = BaseService[LeagueTableEntry, LeagueTableEntryCreate, LeagueTableEntryUpdate, LeagueTableEntry](LeagueTableEntry, db)
        self.challenge_entry_service = BaseService[ChallengeEntry, ChallengeEntryCreate, ChallengeEntryUpdate, ChallengeEntry](ChallengeEntry, db)
    
    # League Table methods
    def get_league_table(self, skip: int = 0, limit: int = 100) -> List[LeagueTableEntry]:
        return self.db.query(LeagueTableEntry).order_by(LeagueTableEntry.rank).offset(skip).limit(limit).all()
    
    def get_player_rank(self, player_id: int) -> Optional[LeagueTableEntry]:
        return self.db.query(LeagueTableEntry).filter(LeagueTableEntry.player_id == player_id).first()
    
    def create_player_entry(self, entry: LeagueTableEntryCreate) -> LeagueTableEntry:
        # Check if player already has an entry
        existing = self.get_player_rank(entry.player_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Player already has a league table entry"
            )
        
        return self.table_service.create(entry)
    
    def update_player_entry(self, player_id: int, data: Dict[str, Any]) -> LeagueTableEntry:
        entry = self.get_player_rank(player_id)
        if not entry:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Player not found in league table"
            )
        
        # Store current rank for calculating rank change
        current_rank = entry.rank
        
        # Update entry
        for field, value in data.items():
            if hasattr(entry, field):
                setattr(entry, field, value)
        
        # Update rank change if rank has changed
        if 'rank' in data and data['rank'] != current_rank:
            entry.previous_rank = current_rank
            entry.rank_change = current_rank - data['rank']  # Positive = improved, negative = dropped
        
        entry.last_updated = datetime.utcnow()
        
        self.db.add(entry)
        self.db.commit()
        self.db.refresh(entry)
        return entry
    
    def recalculate_rankings(self) -> List[LeagueTableEntry]:
        """Recalculate all player rankings based on points and ratings"""
        # Get all entries
        entries = self.db.query(LeagueTableEntry).order_by(LeagueTableEntry.points.desc(), LeagueTableEntry.average_rating.desc()).all()
        
        # Update rankings
        for i, entry in enumerate(entries, 1):
            previous_rank = entry.rank
            entry.previous_rank = previous_rank
            entry.rank = i
            entry.rank_change = previous_rank - i if previous_rank else 0
            entry.last_updated = datetime.utcnow()
        
        self.db.add_all(entries)
        self.db.commit()
        
        # Return the updated table
        return self.get_league_table()
    
    # Challenge Entry methods
    def get_challenge_entries_by_player(self, player_id: int) -> List[ChallengeEntry]:
        return self.db.query(ChallengeEntry).filter(ChallengeEntry.player_id == player_id).all()
    
    def get_challenge_entries_by_challenge(self, challenge_id: int) -> List[ChallengeEntry]:
        return self.db.query(ChallengeEntry).filter(ChallengeEntry.challenge_id == challenge_id).all()
    
    def create_challenge_entry(self, entry: ChallengeEntryCreate) -> ChallengeEntry:
        # Create the challenge entry
        challenge_entry = self.challenge_entry_service.create(entry)
        
        # Update the player's league table entry
        self._update_player_table_from_challenge(entry.player_id, entry.challenge_id, entry.points_earned)
        
        return challenge_entry
    
    def _update_player_table_from_challenge(self, player_id: int, challenge_id: int, points_earned: int) -> None:
        """Update player's league table entry with challenge results"""
        # Get player's league table entry
        entry = self.get_player_rank(player_id)
        if not entry:
            # Create new league table entry if it doesn't exist
            # First, get player stats to calculate average rating
            player_stats = self.db.query(PlayerStats).filter(PlayerStats.player_id == player_id).first()
            avg_rating = player_stats.overall_rating if player_stats else 50.0
            
            # Count existing challenges
            challenges_completed = self.db.query(ChallengeCompletion).filter(
                ChallengeCompletion.user_id == player_id,
                ChallengeCompletion.status == ChallengeStatus.COMPLETED
            ).count()
            
            # Create table entry
            new_entry = LeagueTableEntryCreate(
                player_id=player_id,
                points=points_earned,
                challenges_completed=challenges_completed + 1,
                tests_completed=0,  # Will be updated when tests are added
                average_rating=avg_rating,
                rank=0  # Will be set by recalculate_rankings
            )
            self.create_player_entry(new_entry)
        else:
            # Update existing entry
            update_data = {
                "points": entry.points + points_earned,
                "challenges_completed": entry.challenges_completed + 1
            }
            self.update_player_entry(player_id, update_data)
        
        # Recalculate rankings
        self.recalculate_rankings()
    
    def update_table_from_skill_test(self, player_id: int) -> None:
        """Update player's league table entry after a skill test"""
        # Get player stats
        player_stats = self.db.query(PlayerStats).filter(PlayerStats.player_id == player_id).first()
        if not player_stats:
            return  # No stats to update
        
        # Get or create league table entry
        entry = self.get_player_rank(player_id)
        if not entry:
            # Create new entry
            tests_completed = self.db.query(PlayerStats).filter(PlayerStats.player_id == player_id).count()
            
            new_entry = LeagueTableEntryCreate(
                player_id=player_id,
                points=0,  # No points for tests, only challenges
                challenges_completed=0,
                tests_completed=tests_completed,
                average_rating=player_stats.overall_rating,
                rank=0  # Will be set by recalculate_rankings
            )
            self.create_player_entry(new_entry)
        else:
            # Update existing entry
            update_data = {
                "tests_completed": entry.tests_completed + 1,
                "average_rating": player_stats.overall_rating
            }
            self.update_player_entry(player_id, update_data)
        
        # Recalculate rankings
        self.recalculate_rankings() 