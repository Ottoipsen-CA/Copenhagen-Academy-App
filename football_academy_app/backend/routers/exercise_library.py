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
    prefix="/exercise-library",
    tags=["exercise library"],
    responses={404: {"description": "Not found"}},
)

# Create an exercise (coach only)
@router.post("/", response_model=schemas.ExerciseLibrary)
async def create_exercise(
    exercise: schemas.ExerciseLibraryCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can create exercises"
        )
    
    db_exercise = models.ExerciseLibrary(
        **exercise.dict(),
        created_by=current_user.id
    )
    db.add(db_exercise)
    db.commit()
    db.refresh(db_exercise)
    return db_exercise

# Get all exercises with optional filtering
@router.get("/", response_model=List[schemas.ExerciseLibrary])
async def get_exercises(
    category: Optional[str] = None,
    difficulty_level: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    query = db.query(models.ExerciseLibrary)
    
    # Apply filters if provided
    if category:
        query = query.filter(models.ExerciseLibrary.category == category)
    if difficulty_level:
        query = query.filter(models.ExerciseLibrary.difficulty_level == difficulty_level)
    
    exercises = query.offset(skip).limit(limit).all()
    return exercises

# Get a specific exercise
@router.get("/{exercise_id}", response_model=schemas.ExerciseLibrary)
async def get_exercise(
    exercise_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    exercise = db.query(models.ExerciseLibrary).filter(models.ExerciseLibrary.id == exercise_id).first()
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    return exercise

# Update an exercise (coach only)
@router.put("/{exercise_id}", response_model=schemas.ExerciseLibrary)
async def update_exercise(
    exercise_id: int,
    exercise: schemas.ExerciseLibraryCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can update exercises"
        )
    
    db_exercise = db.query(models.ExerciseLibrary).filter(models.ExerciseLibrary.id == exercise_id).first()
    if db_exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    # Update exercise attributes
    for key, value in exercise.dict().items():
        setattr(db_exercise, key, value)
    
    db_exercise.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_exercise)
    return db_exercise

# Delete an exercise (coach only)
@router.delete("/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_exercise(
    exercise_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can delete exercises"
        )
    
    db_exercise = db.query(models.ExerciseLibrary).filter(models.ExerciseLibrary.id == exercise_id).first()
    if db_exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    # If exercise has a video, delete it
    if db_exercise.video_url and os.path.exists(db_exercise.video_url):
        try:
            os.remove(db_exercise.video_url)
        except:
            # If the file cannot be deleted, just continue
            pass
    
    db.delete(db_exercise)
    db.commit()
    return {"status": "success"}

# Upload video for an exercise (coach only)
@router.post("/{exercise_id}/upload", response_model=schemas.ExerciseLibrary)
async def upload_exercise_video(
    exercise_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Check if user is a coach
    if not current_user.is_coach:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only coaches can upload exercise videos"
        )
    
    # Check if exercise exists
    db_exercise = db.query(models.ExerciseLibrary).filter(models.ExerciseLibrary.id == exercise_id).first()
    if db_exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    # Create uploads directory if it doesn't exist
    os.makedirs("uploads/exercises", exist_ok=True)
    
    # Generate unique filename
    file_extension = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{file_extension}"
    filepath = f"uploads/exercises/{filename}"
    
    # Save the file
    with open(filepath, "wb") as buffer:
        buffer.write(await file.read())
    
    # Update exercise with video URL
    db_exercise.video_url = filepath
    db_exercise.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_exercise)
    
    return db_exercise

# Get available categories
@router.get("/categories", response_model=List[str])
async def get_categories(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Get distinct category values
    categories = db.query(models.ExerciseLibrary.category).distinct().all()
    return [category[0] for category in categories if category[0]]

# Get available difficulty levels
@router.get("/difficulty-levels", response_model=List[str])
async def get_difficulty_levels(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Get distinct difficulty level values
    difficulty_levels = db.query(models.ExerciseLibrary.difficulty_level).distinct().all()
    return [level[0] for level in difficulty_levels if level[0]] 