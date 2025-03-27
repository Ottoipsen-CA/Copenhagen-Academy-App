from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
import sys
import os

# Add the parent directory to the path so we can import modules from the backend package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import models, schemas, auth
from database import get_db

router = APIRouter(
    prefix="/exercises",
    tags=["exercises"]
)

@router.post("/", response_model=schemas.Exercise)
async def create_exercise(
    exercise: schemas.ExerciseCreate,
    video: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify training plan ownership
    training_plan = db.query(models.TrainingPlan).filter(
        models.TrainingPlan.id == exercise.training_plan_id,
        models.TrainingPlan.player_id == current_user.id
    ).first()
    if training_plan is None:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    # Save video file
    video_dir = "uploads/videos"
    os.makedirs(video_dir, exist_ok=True)
    video_path = f"{video_dir}/{video.filename}"
    with open(video_path, "wb") as buffer:
        content = await video.read()
        buffer.write(content)
    
    # Create exercise record
    db_exercise = models.Exercise(
        **exercise.dict(),
        video_url=video_path
    )
    db.add(db_exercise)
    db.commit()
    db.refresh(db_exercise)
    return db_exercise

@router.get("/", response_model=List[schemas.Exercise])
def read_exercises(
    training_plan_id: int,
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    exercises = db.query(models.Exercise).filter(
        models.Exercise.training_plan_id == training_plan_id
    ).offset(skip).limit(limit).all()
    return exercises

@router.get("/{exercise_id}", response_model=schemas.Exercise)
def read_exercise(
    exercise_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    exercise = db.query(models.Exercise).filter(
        models.Exercise.id == exercise_id
    ).first()
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    return exercise

@router.put("/{exercise_id}", response_model=schemas.Exercise)
def update_exercise(
    exercise_id: int,
    exercise_update: schemas.ExerciseBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_exercise = db.query(models.Exercise).filter(
        models.Exercise.id == exercise_id
    ).first()
    if db_exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    for field, value in exercise_update.dict().items():
        setattr(db_exercise, field, value)
    
    db.commit()
    db.refresh(db_exercise)
    return db_exercise

@router.delete("/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_exercise(
    exercise_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_exercise = db.query(models.Exercise).filter(
        models.Exercise.id == exercise_id
    ).first()
    if db_exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    # Delete video file
    if os.path.exists(db_exercise.video_url):
        os.remove(db_exercise.video_url)
    
    db.delete(db_exercise)
    db.commit()
    return None 