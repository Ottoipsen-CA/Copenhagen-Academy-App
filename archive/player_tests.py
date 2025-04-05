from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from sqlalchemy import desc
import sys
import os
from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional
import traceback
import logging

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

router = APIRouter(
    prefix="/player-tests",
    tags=["player-tests"],
    dependencies=[Depends(get_db)],
    responses={404: {"description": "Not found"}},
)

# Setup logger
logger = logging.getLogger("player_tests")
logger.setLevel(logging.DEBUG)

# Debug endpoint
@router.get("/debug", include_in_schema=True)
def debug_endpoint():
    """Debug endpoint to check if the API is working"""
    logger.debug("Debug endpoint called")
    return {"status": "ok", "message": "Player Tests API is working"}

# Define maximum test results by position
class Position(str, Enum):
    STRIKER = "Striker"
    MIDFIELDER = "Midfielder"
    DEFENDER = "Defender"
    GOALKEEPER = "Goalkeeper"

# Maximum result values for each test by position
MAX_RESULTS = {
    "passing_test": {
        Position.STRIKER: 40,
        Position.MIDFIELDER: 45,
        Position.DEFENDER: 40,
        Position.GOALKEEPER: 35
    },
    "sprint_test": {  # Lower is better for sprint
        Position.STRIKER: 1.9,
        Position.MIDFIELDER: 1.9,
        Position.DEFENDER: 1.9,
        Position.GOALKEEPER: 2.0
    },
    "first_touch_test": {
        Position.STRIKER: 35,
        Position.MIDFIELDER: 40,
        Position.DEFENDER: 35,
        Position.GOALKEEPER: 30
    },
    "shooting_test": {
        Position.STRIKER: 14,
        Position.MIDFIELDER: 12,
        Position.DEFENDER: 11,
        Position.GOALKEEPER: 10
    },
    "juggling_test": {
        Position.STRIKER: 150,
        Position.MIDFIELDER: 150,
        Position.DEFENDER: 150,
        Position.GOALKEEPER: 130
    },
    "dribbling_test": {  # Lower is better for dribbling time
        Position.STRIKER: 12,
        Position.MIDFIELDER: 11,
        Position.DEFENDER: 12,
        Position.GOALKEEPER: 13
    }
}

# Mapping of test fields to player stat fields
TEST_TO_STAT_MAPPING = {
    "passing_test": "passing",
    "sprint_test": "pace",
    "first_touch_test": "first_touch",
    "shooting_test": "shooting",
    "juggling_test": "juggles",
    "dribbling_test": "dribbling"
}

def calculate_rating(test_value: float, test_type: str, position: str) -> int:
    """Calculate the rating (0-99) based on test result and position"""
    if position not in [p.value for p in Position]:
        position = Position.MIDFIELDER.value  # Default to midfielder if position not recognized
    
    max_value = MAX_RESULTS[test_type].get(position, MAX_RESULTS[test_type][Position.MIDFIELDER.value])
    
    # For tests where lower is better (sprint, dribbling)
    if test_type in ["sprint_test", "dribbling_test"]:
        if test_value <= 0:  # Protect against division by zero or negative values
            return 50
            
        # Inverse calculation: better (lower) times get higher ratings
        # We set a minimum reasonable value (50% of max) to avoid unreasonable ratings
        min_reasonable_value = max_value * 0.5
        
        if test_value < min_reasonable_value:
            return 99  # Cap at 99 for exceptional results
        elif test_value > max_value * 1.5:
            return 50  # Minimum rating for very poor results
        else:
            # Linear scale between max result (which gives 99) and 1.5x max result (which gives 50)
            ratio = 1 - ((test_value - min_reasonable_value) / (max_value * 1.5 - min_reasonable_value))
            return max(50, min(99, int(50 + (ratio * 49))))
    
    # For tests where higher is better (all others)
    else:
        if max_value <= 0:  # Protect against division by zero
            return 50
            
        ratio = test_value / max_value
        if ratio > 1:
            return 99  # Cap at 99 for exceptional results
        else:
            # Linear scale from 50 to 99
            return max(50, min(99, int(50 + (ratio * 49))))

def calculate_overall_rating(ratings: Dict[str, int]) -> int:
    """Calculate the overall rating as a weighted average of all ratings"""
    if not ratings or all(v is None for v in ratings.values()):
        return 50
        
    valid_ratings = {k: v for k, v in ratings.items() if v is not None}
    if not valid_ratings:
        return 50
        
    return int(sum(valid_ratings.values()) / len(valid_ratings))

def get_player_activity_level(db: Session, player_id: int) -> float:
    """Calculate player activity level based on completed challenges and training sessions"""
    # Get count of completed challenges
    challenge_count = db.query(models.ChallengeStatus).filter(
        models.ChallengeStatus.user_id == player_id,
        models.ChallengeStatus.status == "COMPLETED"
    ).count()
    
    # In a real implementation, you would also count training sessions
    # For now, just return a value 0-1 based on challenges
    return min(1.0, challenge_count / 20)  # Cap at 1.0 after 20 challenges

@router.post("/", response_model=schemas.PlayerTestResponse)
def create_player_test(
    test_data: schemas.PlayerTestCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    try:
        logger.debug(f"Creating player test: {test_data.dict()}")
        
        # Ensure the user can only submit their own test results (unless they're a coach)
        if test_data.player_id != current_user.id and not current_user.is_coach:
            logger.warning(f"User {current_user.id} not authorized to submit test for player {test_data.player_id}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to submit test results for this player"
            )
        
        # Get the player's position
        player = db.query(models.User).filter(models.User.id == test_data.player_id).first()
        if not player:
            logger.warning(f"Player {test_data.player_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Player not found"
            )
        
        logger.debug(f"Player position: {player.position}")
        position = player.position or Position.MIDFIELDER.value
        
        # Calculate ratings for each test
        ratings = {}
        test_values = test_data.dict()
        
        for test_field, stat_field in TEST_TO_STAT_MAPPING.items():
            test_value = test_values.get(test_field)
            if test_value is not None:
                # Fix the naming to match model field names
                if test_field == "sprint_test":
                    rating_field = "pace_rating"
                elif test_field == "first_touch_test":
                    rating_field = "first_touch_rating"
                else:
                    # For other fields, strip "_test" and add "_rating"
                    rating_field = f"{test_field.split('_')[0]}_rating"
                
                # Log the field mappings for debugging
                logger.debug(f"Setting {rating_field} from {test_field} value: {test_value}")
                ratings[rating_field] = calculate_rating(test_value, test_field, position)
        
        logger.debug(f"Calculated ratings: {ratings}")
        
        # Create the test record
        db_test = models.PlayerTest(**test_data.dict(), **ratings)
        db.add(db_test)
        db.commit()
        db.refresh(db_test)
        
        logger.debug(f"Test record created with ID: {db_test.id}")
        
        # Update player stats based on test results and activity level
        try:
            update_player_stats_from_test(db, db_test, position)
            logger.debug("Player stats updated successfully")
        except Exception as e:
            logger.error(f"Error updating player stats: {str(e)}")
            logger.error(traceback.format_exc())
            # Continue even if updating stats fails
        
        return db_test
        
    except Exception as e:
        logger.error(f"Error creating player test: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating player test: {str(e)}"
        )

def update_player_stats_from_test(db: Session, test: models.PlayerTest, position: str):
    """Update player stats based on test results and activity level"""
    try:
        logger.debug(f"Updating player stats from test ID: {test.id}")
        
        # Get player stats
        stats = db.query(models.PlayerStats).filter(
            models.PlayerStats.player_id == test.player_id
        ).first()
        
        if not stats:
            logger.debug(f"No stats found for player {test.player_id}, creating default stats")
            # Create default stats if they don't exist
            stats = models.PlayerStats(
                player_id=test.player_id,
                pace=50,
                shooting=50,
                passing=50,
                dribbling=50,
                juggles=50,
                first_touch=50,
                overall_rating=50
            )
            db.add(stats)
        else:
            logger.debug(f"Found existing stats for player {test.player_id}")
        
        # Get player activity level (0.0 to 1.0)
        activity_level = get_player_activity_level(db, test.player_id)
        logger.debug(f"Player activity level: {activity_level}")
        
        # Apply weightings: 60% test results, 40% activity (at max activity)
        test_weight = 0.6
        activity_weight = min(0.4, activity_level * 0.02)  # 0.02 per completed challenge up to 0.4
        current_weight = 1.0 - test_weight - activity_weight
        logger.debug(f"Weights: test={test_weight}, activity={activity_weight}, current={current_weight}")
        
        # Update each stat
        # For pace (from sprint_test)
        if test.pace_rating is not None:
            old_pace = stats.pace
            stats.pace = int(
                (stats.pace * current_weight) + 
                (test.pace_rating * test_weight) + 
                (stats.pace * activity_weight)  # Assuming current level influences activity bonus
            )
            logger.debug(f"Updated pace: {old_pace} -> {stats.pace}")
        
        # For shooting
        if test.shooting_rating is not None:
            old_shooting = stats.shooting
            stats.shooting = int(
                (stats.shooting * current_weight) + 
                (test.shooting_rating * test_weight) + 
                (stats.shooting * activity_weight)
            )
            logger.debug(f"Updated shooting: {old_shooting} -> {stats.shooting}")
        
        # For passing
        if test.passing_rating is not None:
            old_passing = stats.passing
            stats.passing = int(
                (stats.passing * current_weight) + 
                (test.passing_rating * test_weight) + 
                (stats.passing * activity_weight)
            )
            logger.debug(f"Updated passing: {old_passing} -> {stats.passing}")
        
        # For dribbling
        if test.dribbling_rating is not None:
            old_dribbling = stats.dribbling
            stats.dribbling = int(
                (stats.dribbling * current_weight) + 
                (test.dribbling_rating * test_weight) + 
                (stats.dribbling * activity_weight)
            )
            logger.debug(f"Updated dribbling: {old_dribbling} -> {stats.dribbling}")
        
        # For juggles
        if test.juggling_rating is not None:
            old_juggles = stats.juggles
            stats.juggles = int(
                (stats.juggles * current_weight) + 
                (test.juggling_rating * test_weight) + 
                (stats.juggles * activity_weight)
            )
            logger.debug(f"Updated juggles: {old_juggles} -> {stats.juggles}")
        
        # For first touch
        if test.first_touch_rating is not None:
            old_first_touch = stats.first_touch
            stats.first_touch = int(
                (stats.first_touch * current_weight) + 
                (test.first_touch_rating * test_weight) + 
                (stats.first_touch * activity_weight)
            )
            logger.debug(f"Updated first_touch: {old_first_touch} -> {stats.first_touch}")
        
        # Recalculate overall rating
        old_overall = stats.overall_rating
        stats.overall_rating = int(
            (stats.pace + stats.shooting + stats.passing + stats.dribbling + stats.juggles + stats.first_touch) / 6
        )
        logger.debug(f"Updated overall_rating: {old_overall} -> {stats.overall_rating}")
        
        # Update last_updated timestamp
        stats.last_updated = datetime.utcnow()
        
        db.commit()
        logger.debug("Player stats committed to database")
        
    except Exception as e:
        logger.error(f"Error in update_player_stats_from_test: {str(e)}")
        logger.error(traceback.format_exc())
        raise

@router.get("/{player_id}/latest", response_model=schemas.PlayerTestResponse)
def get_latest_player_test(
    player_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Check authorization
    if player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this player's test results"
        )
    
    # Get the latest test
    latest_test = db.query(models.PlayerTest).filter(
        models.PlayerTest.player_id == player_id
    ).order_by(desc(models.PlayerTest.test_date)).first()
    
    if not latest_test:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No test results found for this player"
        )
    
    return latest_test

@router.get("/{player_id}", response_model=List[schemas.PlayerTestResponse])
def get_player_tests(
    player_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Check authorization
    if player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this player's test results"
        )
    
    # Get all tests for the player
    tests = db.query(models.PlayerTest).filter(
        models.PlayerTest.player_id == player_id
    ).order_by(desc(models.PlayerTest.test_date)).all()
    
    return tests

@router.put("/{test_id}", response_model=schemas.PlayerTestResponse)
def update_player_test(
    test_id: int,
    test_data: schemas.PlayerTestUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    try:
        logger.debug(f"Updating player test {test_id} with data: {test_data.dict()}")
        
        # Get the test
        test = db.query(models.PlayerTest).filter(models.PlayerTest.id == test_id).first()
        if not test:
            logger.warning(f"Test {test_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Test not found"
            )
        
        # Check authorization
        if test.player_id != current_user.id and not current_user.is_coach:
            logger.warning(f"User {current_user.id} not authorized to update test {test_id} for player {test.player_id}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this test"
            )
        
        # Get the player's position
        player = db.query(models.User).filter(models.User.id == test.player_id).first()
        position = player.position or Position.MIDFIELDER.value
        logger.debug(f"Player position: {position}")
        
        # Update test data
        update_data = test_data.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(test, key, value)
        
        # Recalculate ratings
        for test_field, stat_field in TEST_TO_STAT_MAPPING.items():
            test_value = getattr(test, test_field, None)
            if test_value is not None:
                # Fix the naming to match model field names
                if test_field == "sprint_test":
                    rating_field = "pace_rating"
                elif test_field == "first_touch_test":
                    rating_field = "first_touch_rating"
                else:
                    # For other fields, strip "_test" and add "_rating"
                    rating_field = f"{test_field.split('_')[0]}_rating"
                
                # Log the field mappings for debugging
                logger.debug(f"Setting {rating_field} from {test_field} value: {test_value}")
                setattr(test, rating_field, calculate_rating(test_value, test_field, position))
        
        db.commit()
        db.refresh(test)
        logger.debug(f"Test {test_id} updated successfully")
        
        # Update player stats
        try:
            update_player_stats_from_test(db, test, position)
            logger.debug("Player stats updated successfully")
        except Exception as e:
            logger.error(f"Error updating player stats: {str(e)}")
            logger.error(traceback.format_exc())
            # Continue even if updating stats fails
        
        return test
        
    except Exception as e:
        logger.error(f"Error updating player test: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating player test: {str(e)}"
        ) 