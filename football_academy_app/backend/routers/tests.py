from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

import models
import schemas
import auth
from database import get_db

router = APIRouter(
    prefix="/tests",
    tags=["tests"],
    responses={404: {"description": "Not found"}},
)

# Create a test (coach only)
@router.post("/", response_model=schemas.Test)
async def create_test(
    test: schemas.TestCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create tests"
        )
    
    db_test = models.Test(
        **test.dict(),
        created_by=current_user.id
    )
    db.add(db_test)
    db.commit()
    db.refresh(db_test)
    return db_test

# Get all tests
@router.get("/", response_model=List[schemas.Test])
async def get_tests(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    tests = db.query(models.Test).offset(skip).limit(limit).all()
    return tests

# Get a specific test
@router.get("/{test_id}", response_model=schemas.Test)
async def get_test(
    test_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    return test

# Update a test (coach only)
@router.put("/{test_id}", response_model=schemas.Test)
async def update_test(
    test_id: int,
    test: schemas.TestCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update tests"
        )
    
    db_test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    
    # Update test attributes
    for key, value in test.dict().items():
        setattr(db_test, key, value)
    
    db_test.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_test)
    return db_test

# Delete a test (coach only)
@router.delete("/{test_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_test(
    test_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete tests"
        )
    
    db_test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    
    db.delete(db_test)
    db.commit()
    return {"status": "success"}

# --- Test Entries ---

# Create a test entry (coach only - coaches record test results)
@router.post("/entries/", response_model=schemas.TestEntry)
async def create_test_entry(
    entry: schemas.TestEntryCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can record test results"
        )
    
    # Check if test exists
    test = db.query(models.Test).filter(models.Test.id == entry.test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Test not found")
    
    # Check if user exists
    user = db.query(models.User).filter(models.User.id == entry.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Create new entry
    db_entry = models.TestEntry(**entry.dict())
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    
    # Update league table
    league_entry = db.query(models.LeagueTableEntry).filter(
        models.LeagueTableEntry.user_id == entry.user_id
    ).first()
    
    if not league_entry:
        league_entry = models.LeagueTableEntry(
            user_id=entry.user_id,
            challenge_points=0,
            test_points=0,
            total_points=0
        )
        db.add(league_entry)
    
    # Calculate test points
    # Sum all test scores multiplied by the test's points_scale
    test_entries = db.query(models.TestEntry, models.Test).join(
        models.Test, models.TestEntry.test_id == models.Test.id
    ).filter(
        models.TestEntry.user_id == entry.user_id
    ).all()
    
    # Calculate total test points
    test_points = sum(entry.score * test.points_scale for entry, test in test_entries)
    
    # Update league table
    league_entry.test_points = int(test_points)  # Convert to int for consistency
    league_entry.total_points = league_entry.challenge_points + league_entry.test_points
    league_entry.last_calculated = datetime.utcnow()
    
    db.commit()
    db.refresh(league_entry)
    
    return db_entry

# Get all test entries for a specific test (coach only)
@router.get("/entries/test/{test_id}", response_model=List[schemas.TestEntry])
async def get_test_entries(
    test_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can view all test entries"
        )
    
    entries = db.query(models.TestEntry).filter(
        models.TestEntry.test_id == test_id
    ).all()
    
    return entries

# Get all test entries for a user
@router.get("/entries/user/{user_id}", response_model=List[schemas.TestEntry])
async def get_user_test_entries(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach or the user themselves
    if not current_user.is_coach and current_user.id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own test entries"
        )
    
    entries = db.query(models.TestEntry).filter(
        models.TestEntry.user_id == user_id
    ).all()
    
    return entries

# Update a test entry (coach only)
@router.put("/entries/{entry_id}", response_model=schemas.TestEntry)
async def update_test_entry(
    entry_id: int,
    entry: schemas.TestEntryCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update test entries"
        )
    
    db_entry = db.query(models.TestEntry).filter(models.TestEntry.id == entry_id).first()
    if db_entry is None:
        raise HTTPException(status_code=404, detail="Test entry not found")
    
    # Update entry attributes
    for key, value in entry.dict().items():
        setattr(db_entry, key, value)
    
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    # Update league table
    league_entry = db.query(models.LeagueTableEntry).filter(
        models.LeagueTableEntry.user_id == db_entry.user_id
    ).first()
    
    if league_entry:
        # Recalculate test points
        test_entries = db.query(models.TestEntry, models.Test).join(
            models.Test, models.TestEntry.test_id == models.Test.id
        ).filter(
            models.TestEntry.user_id == db_entry.user_id
        ).all()
        
        test_points = sum(entry.score * test.points_scale for entry, test in test_entries)
        
        # Update league table
        league_entry.test_points = int(test_points)
        league_entry.total_points = league_entry.challenge_points + league_entry.test_points
        league_entry.last_calculated = datetime.utcnow()
        
        db.commit()
    
    return db_entry

# Delete a test entry (coach only)
@router.delete("/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_test_entry(
    entry_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete test entries"
        )
    
    db_entry = db.query(models.TestEntry).filter(models.TestEntry.id == entry_id).first()
    if db_entry is None:
        raise HTTPException(status_code=404, detail="Test entry not found")
    
    user_id = db_entry.user_id
    
    db.delete(db_entry)
    db.commit()
    
    # Update league table
    league_entry = db.query(models.LeagueTableEntry).filter(
        models.LeagueTableEntry.user_id == user_id
    ).first()
    
    if league_entry:
        # Recalculate test points
        test_entries = db.query(models.TestEntry, models.Test).join(
            models.Test, models.TestEntry.test_id == models.Test.id
        ).filter(
            models.TestEntry.user_id == user_id
        ).all()
        
        test_points = sum(entry.score * test.points_scale for entry, test in test_entries)
        
        # Update league table
        league_entry.test_points = int(test_points)
        league_entry.total_points = league_entry.challenge_points + league_entry.test_points
        league_entry.last_calculated = datetime.utcnow()
        
        db.commit()
    
    return {"status": "success"} 