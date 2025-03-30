from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from database import engine, get_db
from datetime import timedelta
import logging
import models
import auth
import os

# Import all routers
from routers import (
    users,
    training_plans,
    exercises,
    achievements,
    player_stats,
    challenge_progress,
    test_player_stats,  # 👈 NY router til test
    challenges,  # Added challenges router
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create tables
models.Base.metadata.create_all(bind=engine)

# Enhanced FastAPI app with detailed documentation
app = FastAPI(
    title="Football Academy API",
    description="""
    Football Academy API provides endpoints for managing player profiles, training plans, 
    challenges, achievements, and player statistics. 
    
    This API allows players to track their progress, complete challenges, and improve their football skills.
    """,
    version="1.0.0",
    contact={
        "name": "Football Academy Support",
        "email": "support@football-academy.app",
    },
    license_info={
        "name": "MIT License",
    },
    openapi_tags=[
        {
            "name": "users",
            "description": "Operations for managing user accounts and profiles",
        },
        {
            "name": "training_plans",
            "description": "Training plan management and progress tracking",
        },
        {
            "name": "exercises",
            "description": "Exercise library and details",
        },
        {
            "name": "achievements",
            "description": "Player achievements and badges",
        },
        {
            "name": "player_stats",
            "description": "Player statistics and performance metrics",
        },
        {
            "name": "challenge_progress",
            "description": "Challenge completion and progress tracking",
        },
    ]
)

# CORS settings for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"]
)

# Mount static files directory if it exists
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Include all routers
app.include_router(users.router)
app.include_router(training_plans.router)
app.include_router(exercises.router)
app.include_router(achievements.router)
app.include_router(player_stats.router)
app.include_router(challenge_progress.router)
app.include_router(test_player_stats.router)  # 👈 NY test-router
app.include_router(challenges.router)  # Challenge router for progression system

# Token login endpoint
@app.post("/token", 
          summary="Create access token for user",
          description="Authenticate user and create JWT access token",
          tags=["authentication"])
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    logger.info(f"Login attempt: {form_data.username}")
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        logger.warning("Login failed")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    logger.info("Login success")
    return {"access_token": access_token, "token_type": "bearer"}

# Root endpoint redirects to documentation
@app.get("/", 
         summary="API Root",
         description="Redirects to static welcome page or API documentation",
         tags=["health"])
async def root():
    # Check if static directory exists with index.html
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        return RedirectResponse(url="/static/index.html")
    else:
        # Fallback to Swagger UI
        return RedirectResponse(url="/docs")

@app.get("/health", 
         summary="Health Check",
         description="Endpoint to verify API health status",
         tags=["health"])
async def health_check():
    return {"status": "healthy"}