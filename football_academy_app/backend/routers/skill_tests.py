from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from typing import List
import logging

from models import User, PlayerTest
from database import get_async_db
from services.auth import get_current_user_dependency
from schemas import PlayerTestCreate, PlayerTestResponse
from services.skill_tests import SkillTestsService

router = APIRouter(
    prefix="/skill-tests",
    tags=["skill_tests"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

logger = logging.getLogger(__name__)

# -------------- Player Tests Endpoints --------------

@router.post("/player-tests", response_model=PlayerTestResponse)
async def create_player_test(
    test_data: PlayerTestCreate,
    current_user: User = Depends(get_current_user_dependency),
    db: AsyncSession = Depends(get_async_db)
):
    """Create a new player test and update their stats"""
    service = SkillTestsService(db)
    
    # Ensure the user can only submit their own test results (unless they're a coach)
    if test_data.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to submit test results for this player"
        )
    
    try:
        return await service.create_player_test(test_data, current_user)
    except Exception as e:
        logger.error(f"Error creating player test: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating player test: {str(e)}"
        )

@router.get("/player-tests/player/{player_id}", response_model=List[PlayerTestResponse])
async def get_player_tests(
    player_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user_dependency)
):
    """Get all tests for a specific player"""
    service = SkillTestsService(db)
    
    # Check permissions
    if player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this player's tests"
        )
    
    return await service.get_player_tests(player_id)

@router.delete("/player-tests/{test_id}")
async def delete_player_test(
    test_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user_dependency)
):
    """Delete a specific player test"""
    service = SkillTestsService(db)
    
    # Get the test to check ownership
    test = await service.get_player_test_by_id(test_id)
    if not test:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Test not found"
        )
    
    # Check permissions
    if test.player_id != current_user.id and not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this test"
        )
    
    return await service.delete_player_test(test_id) 