from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form, status
from typing import List, Optional
from sqlalchemy.orm import Session
import os
import uuid
from datetime import datetime

import models
import schemas
import auth
from database import get_db

router = APIRouter(
    prefix="/challenges",
    tags=["challenges"],
    responses={404: {"description": "Not found"}},
)

# Create a challenge (coach only)
@router.post("/", response_model=schemas.Challenge)
async def create_challenge(
    challenge: schemas.ChallengeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create challenges"
        )
    
    db_challenge = models.Challenge(
        **challenge.dict(),
        created_by=current_user.id
    )
    db.add(db_challenge)
    db.commit()
    db.refresh(db_challenge)
    return db_challenge

# Get all challenges
@router.get("/", response_model=List[schemas.Challenge])
async def get_challenges(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    challenges = db.query(models.Challenge).offset(skip).limit(limit).all()
    return challenges

# Get a specific challenge
@router.get("/{challenge_id}", response_model=schemas.Challenge)
async def get_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    challenge = db.query(models.Challenge).filter(models.Challenge.id == challenge_id).first()
    if challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")
    return challenge

# Update a challenge (coach only)
@router.put("/{challenge_id}", response_model=schemas.Challenge)
async def update_challenge(
    challenge_id: int,
    challenge: schemas.ChallengeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update challenges"
        )
    
    db_challenge = db.query(models.Challenge).filter(models.Challenge.id == challenge_id).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    # Update challenge attributes
    for key, value in challenge.dict().items():
        setattr(db_challenge, key, value)
    
    db_challenge.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_challenge)
    return db_challenge

# Delete a challenge (coach only)
@router.delete("/{challenge_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete challenges"
        )
    
    db_challenge = db.query(models.Challenge).filter(models.Challenge.id == challenge_id).first()
    if db_challenge is None:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    db.delete(db_challenge)
    db.commit()
    return {"status": "success"}

# --- Challenge Entries ---

# Create a challenge entry (submit a solution to a challenge)
@router.post("/entries/", response_model=schemas.ChallengeEntry)
async def create_challenge_entry(
    entry: schemas.ChallengeEntryCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if challenge exists
    challenge = db.query(models.Challenge).filter(models.Challenge.id == entry.challenge_id).first()
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    
    # Check if user already has an entry for this challenge
    existing_entry = db.query(models.ChallengeEntry).filter(
        models.ChallengeEntry.challenge_id == entry.challenge_id,
        models.ChallengeEntry.user_id == current_user.id
    ).first()
    
    if existing_entry:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have a submission for this challenge"
        )
    
    # Create new entry
    db_entry = models.ChallengeEntry(
        **entry.dict(),
        user_id=current_user.id,
        status="pending"
    )
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    return db_entry

# Get all entries for a challenge (coach only)
@router.get("/entries/challenge/{challenge_id}", response_model=List[schemas.ChallengeEntry])
async def get_challenge_entries(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can view all entries"
        )
    
    entries = db.query(models.ChallengeEntry).filter(
        models.ChallengeEntry.challenge_id == challenge_id
    ).all()
    
    return entries

# Get all entries for current user
@router.get("/entries/user/", response_model=List[schemas.ChallengeEntry])
async def get_user_entries(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    entries = db.query(models.ChallengeEntry).filter(
        models.ChallengeEntry.user_id == current_user.id
    ).all()
    
    return entries

# Update a challenge entry (coach only - for approval and points)
@router.put("/entries/{entry_id}", response_model=schemas.ChallengeEntry)
async def update_challenge_entry(
    entry_id: int,
    entry_update: schemas.ChallengeEntryUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update entries"
        )
    
    db_entry = db.query(models.ChallengeEntry).filter(models.ChallengeEntry.id == entry_id).first()
    if db_entry is None:
        raise HTTPException(status_code=404, detail="Challenge entry not found")
    
    # Update entry attributes
    for key, value in entry_update.dict(exclude_unset=True).items():
        if value is not None:
            setattr(db_entry, key, value)
    
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    # If the entry was approved, update league table
    if entry_update.status == "approved":
        # Get or create league table entry
        league_entry = db.query(models.LeagueTableEntry).filter(
            models.LeagueTableEntry.user_id == db_entry.user_id
        ).first()
        
        if not league_entry:
            league_entry = models.LeagueTableEntry(
                user_id=db_entry.user_id,
                challenge_points=0,
                test_points=0,
                total_points=0
            )
            db.add(league_entry)
        
        # Sum all approved challenge points for this user
        challenge_points = db.query(models.ChallengeEntry).filter(
            models.ChallengeEntry.user_id == db_entry.user_id,
            models.ChallengeEntry.status == "approved"
        ).with_entities(models.ChallengeEntry.points_awarded).all()
        
        # Update league table
        league_entry.challenge_points = sum(point[0] for point in challenge_points)
        league_entry.total_points = league_entry.challenge_points + league_entry.test_points
        league_entry.last_calculated = datetime.utcnow()
        
        db.commit()
        db.refresh(league_entry)
    
    return db_entry

# Upload video for challenge entry
@router.post("/entries/{entry_id}/upload", response_model=schemas.ChallengeEntry)
async def upload_challenge_video(
    entry_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if entry exists and belongs to user
    db_entry = db.query(models.ChallengeEntry).filter(
        models.ChallengeEntry.id == entry_id,
        models.ChallengeEntry.user_id == current_user.id
    ).first()
    
    if not db_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge entry not found or doesn't belong to you"
        )
    
    # Create uploads directory if it doesn't exist
    os.makedirs("uploads/challenges", exist_ok=True)
    
    # Generate unique filename
    file_extension = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{file_extension}"
    filepath = f"uploads/challenges/{filename}"
    
    # Save the file
    with open(filepath, "wb") as buffer:
        buffer.write(await file.read())
    
    # Update entry with video URL
    db_entry.submission_video_url = filepath
    db_entry.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_entry)
    
    return db_entry 