from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status
from sqlalchemy import select

from models.skill_tests import PlayerStats, PlayerTest
from models.users import User
from constants.position_weights import Position, POSITION_WEIGHTS
from schemas.skill_tests import (
    PlayerStatsCreate, PlayerStatsUpdate, PlayerStatsResponse,
    PlayerTestCreate, PlayerTestUpdate, PlayerTestResponse
)
from services.base import BaseService
from constants.test_scores import (
    MAX_PACE_SCORE, MAX_SHOOTING_SCORE, MAX_PASSING_SCORE,
    MAX_DRIBBLING_SCORE, MAX_JUGGLES_SCORE, MAX_FIRST_TOUCH_SCORE,
    MIN_PACE_SCORE, MIN_SHOOTING_SCORE, MIN_PASSING_SCORE,
    MIN_DRIBBLING_SCORE, MIN_JUGGLES_SCORE, MIN_FIRST_TOUCH_SCORE,
    MAX_RATING, MIN_RATING
)

class SkillTestsService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.player_stats_service = BaseService[PlayerStats, PlayerStatsCreate, PlayerStatsUpdate, PlayerStatsResponse](PlayerStats, db)
        self.player_test_service = BaseService[PlayerTest, PlayerTestCreate, PlayerTestUpdate, PlayerTestResponse](PlayerTest, db)
    
    # Player Stats methods
    async def get_player_stats(self, player_id: int) -> Optional[PlayerStats]:
        result = self.db.execute(
            select(PlayerStats).where(PlayerStats.player_id == player_id)
        )
        return result.scalar_one_or_none()
    
    async def create_player_stats(self, stats: PlayerStatsCreate) -> PlayerStats:
        if self.get_player_stats(stats.player_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Player stats already exist for this player"
            )
        return self.player_stats_service.create(stats)
    
    async def update_player_stats(self, player_id: int, stats: Dict[str, Any]) -> PlayerStats:
        db_stats =  self.get_player_stats(player_id)
        if not db_stats:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Player stats not found"
            )
        
        # Update fields
        for field, value in stats.items():
            if hasattr(db_stats, field) and value is not None:
                setattr(db_stats, field, value)
        
        db_stats.last_updated = datetime.utcnow()
        self.db.add(db_stats)
        self.db.commit()
        self.db.refresh(db_stats)
        return db_stats
    
    async def calculate_overall_rating(self, player_id: int) -> float:
        """Calculate and update the player's overall rating based on all attributes weighted by position"""
        # Get player stats and position
        result = await self.db.execute(
            select(PlayerStats, User.position)
            .join(User, PlayerStats.player_id == User.id)
            .where(PlayerStats.player_id == player_id)
        )
        stats, position = result.first()
        
        if not stats:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Player stats not found"
            )
        
        # Get position weights
        weights = POSITION_WEIGHTS.get(position, POSITION_WEIGHTS[Position.MIDFIELDER])  # Default to midfielder weights
        
        # Calculate weighted average of all non-None attributes
        weighted_sum = 0.0
        total_weight = 0.0
        
        if stats.pace is not None:
            weighted_sum += stats.pace * weights["pace"]
            total_weight += weights["pace"]
        if stats.shooting is not None:
            weighted_sum += stats.shooting * weights["shooting"]
            total_weight += weights["shooting"]
        if stats.passing is not None:
            weighted_sum += stats.passing * weights["passing"]
            total_weight += weights["passing"]
        if stats.dribbling is not None:
            weighted_sum += stats.dribbling * weights["dribbling"]
            total_weight += weights["dribbling"]
        if stats.juggles is not None:
            weighted_sum += stats.juggles * weights["juggles"]
            total_weight += weights["juggles"]
        if stats.first_touch is not None:
            weighted_sum += stats.first_touch * weights["first_touch"]
            total_weight += weights["first_touch"]
        
        if total_weight == 0:
            return MIN_RATING  # Return minimum rating if no valid attributes
            
        overall = weighted_sum / total_weight
        
        # Update the player's overall rating
        stats.overall_rating = round(overall, 1)
        stats.last_updated = datetime.utcnow()
        self.db.add(stats)
        await self.db.commit()
        await self.db.refresh(stats)
        return stats.overall_rating
    
    def _convert_raw_to_rating(self, test_type: str, raw_value: float) -> float:
        """Convert raw test result to a 1-99 rating based on test type."""
        if test_type == "pace":
            # Convert seconds to rating (lower is better)
            # Invert the calculation since lower time is better
            normalized_score = MAX_PACE_SCORE / raw_value
            return min(normalized_score * MAX_RATING, MAX_RATING)
        elif test_type == "shooting":
            # Convert score out of 10 to rating
            normalized_score = raw_value / MAX_SHOOTING_SCORE
            return min(normalized_score * MAX_RATING, MAX_RATING)
        elif test_type == "passing":
            # Convert score out of 10 to rating
            normalized_score = raw_value / MAX_PASSING_SCORE
            return min(normalized_score * MAX_RATING, MAX_RATING)
        elif test_type == "dribbling":
            # Convert seconds to rating (lower is better)
            # Invert the calculation since lower time is better
            normalized_score = MAX_DRIBBLING_SCORE / raw_value
            return min(normalized_score * MAX_RATING, MAX_RATING)
        elif test_type == "juggles":
            # Convert number of juggles to rating
            normalized_score = raw_value / MAX_JUGGLES_SCORE
            return min(normalized_score * MAX_RATING, MAX_RATING)
        elif test_type == "first_touch":
            # Convert score out of 10 to rating
            normalized_score = raw_value / MAX_FIRST_TOUCH_SCORE
            return min(normalized_score * MAX_RATING, MAX_RATING)
        return MIN_RATING  # Default rating if test type not recognized
    
    async def _update_player_stats(self, player_id: int, test: PlayerTest) -> None:
        """Update player stats based on test results."""
        result = await self.db.execute(
            select(PlayerStats).where(PlayerStats.player_id == player_id)
        )
        stats = result.scalar_one_or_none()
        
        if not stats:
            # Initialize new PlayerStats with test ratings
            stats = PlayerStats(
                player_id=player_id,
                pace=test.pace_rating,
                shooting=test.shooting_rating,
                passing=test.passing_rating,
                dribbling=test.dribbling_rating,
                juggles=test.juggles_rating,
                first_touch=test.first_touch_rating
            )
            self.db.add(stats)
        else:
            # Update existing stats with weighted average (70% old, 30% new)
            if test.pace is not None:
                stats.pace = (stats.pace * 0.7) + (test.pace_rating * 0.3) if stats.pace else test.pace_rating
            if test.shooting is not None:
                stats.shooting = (stats.shooting * 0.7) + (test.shooting_rating * 0.3) if stats.shooting else test.shooting_rating
            if test.passing is not None:
                stats.passing = (stats.passing * 0.7) + (test.passing_rating * 0.3) if stats.passing else test.passing_rating
            if test.dribbling is not None:
                stats.dribbling = (stats.dribbling * 0.7) + (test.dribbling_rating * 0.3) if stats.dribbling else test.dribbling_rating
            if test.juggles is not None:
                stats.juggles = (stats.juggles * 0.7) + (test.juggles_rating * 0.3) if stats.juggles else test.juggles_rating
            if test.first_touch is not None:
                stats.first_touch = (stats.first_touch * 0.7) + (test.first_touch_rating * 0.3) if stats.first_touch else test.first_touch_rating
        
        # Calculate overall rating based on position
        stats.overall_rating = await self.calculate_overall_rating(player_id)
        
        await self.db.commit()
    
    # Player Test methods
    async def get_player_tests(self, player_id: int) -> List[PlayerTest]:
        result = await self.db.execute(
            select(PlayerTest)
            .where(PlayerTest.player_id == player_id)
            .order_by(PlayerTest.test_date.desc())
        )
        tests = result.scalars().all()
        return list(tests)
    
    async def get_player_test_by_id(self, test_id: int) -> Optional[PlayerTest]:
        result = await self.db.execute(
            select(PlayerTest).where(PlayerTest.id == test_id)
        )
        return result.scalar_one_or_none()
    
    async def create_player_test(
        self,
        test_data: PlayerTestCreate,
        current_user: User
    ) -> PlayerTest:
        # Get the player's position from their user record
        result = await self.db.execute(
            select(User).where(User.id == test_data.player_id)
        )
        player = result.scalar_one_or_none()
        if not player:
            raise HTTPException(status_code=404, detail="Player not found")
        
        # Ensure users can only submit their own test results unless they are coaches
        if current_user.role != "coach" and current_user.id != test_data.player_id:
            raise HTTPException(
                status_code=403,
                detail="Not authorized to submit test results for this player"
            )
        
        # Calculate ratings based on raw values
        ratings = {}
        if test_data.pace is not None:
            ratings["pace"] = self._convert_raw_to_rating("pace", test_data.pace)
        if test_data.shooting is not None:
            ratings["shooting"] = self._convert_raw_to_rating("shooting", test_data.shooting)
        if test_data.passing is not None:
            ratings["passing"] = self._convert_raw_to_rating("passing", test_data.passing)
        if test_data.dribbling is not None:
            ratings["dribbling"] = self._convert_raw_to_rating("dribbling", test_data.dribbling)
        if test_data.juggles is not None:
            ratings["juggles"] = self._convert_raw_to_rating("juggles", test_data.juggles)
        if test_data.first_touch is not None:
            ratings["first_touch"] = self._convert_raw_to_rating("first_touch", test_data.first_touch)
        
        # Calculate overall rating for this test session
        weights = POSITION_WEIGHTS.get(player.position, POSITION_WEIGHTS[Position.MIDFIELDER])
        weighted_sum = 0.0
        total_weight = 0.0
        
        if "pace" in ratings:
            weighted_sum += ratings["pace"] * weights["pace"]
            total_weight += weights["pace"]
        if "shooting" in ratings:
            weighted_sum += ratings["shooting"] * weights["shooting"]
            total_weight += weights["shooting"]
        if "passing" in ratings:
            weighted_sum += ratings["passing"] * weights["passing"]
            total_weight += weights["passing"]
        if "dribbling" in ratings:
            weighted_sum += ratings["dribbling"] * weights["dribbling"]
            total_weight += weights["dribbling"]
        if "juggles" in ratings:
            weighted_sum += ratings["juggles"] * weights["juggles"]
            total_weight += weights["juggles"]
        if "first_touch" in ratings:
            weighted_sum += ratings["first_touch"] * weights["first_touch"]
            total_weight += weights["first_touch"]
        
        test_overall_rating = round(weighted_sum / total_weight, 1) if total_weight > 0 else MIN_RATING
        
        # Create new player test record
        db_test = PlayerTest(
            player_id=test_data.player_id,
            test_date=test_data.test_date or datetime.utcnow(),
            position=player.position,  # Store the player's position at test time
            pace=test_data.pace,
            shooting=test_data.shooting,
            passing=test_data.passing,
            dribbling=test_data.dribbling,
            juggles=test_data.juggles,
            first_touch=test_data.first_touch,
            pace_rating=ratings.get("pace"),
            shooting_rating=ratings.get("shooting"),
            passing_rating=ratings.get("passing"),
            dribbling_rating=ratings.get("dribbling"),
            juggles_rating=ratings.get("juggles"),
            first_touch_rating=ratings.get("first_touch"),
            overall_rating=test_overall_rating,  # Add the calculated overall rating
            notes=test_data.notes,
            recorded_by=current_user.id
        )
        
        self.db.add(db_test)
        await self.db.commit()
        await self.db.refresh(db_test)
        
        # Update player stats with weighted averages
        await self._update_player_stats(test_data.player_id, db_test)
        
        return db_test
    
    async def delete_player_test(self, test_id: int) -> bool:
        """Delete a player test"""
        test = await self.get_player_test_by_id(test_id)
        if not test:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Test not found"
            )
        
        await self.db.delete(test)
        await self.db.commit()
        return True 