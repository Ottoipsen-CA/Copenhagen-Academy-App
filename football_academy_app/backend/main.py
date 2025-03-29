from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from database import engine, get_db
from datetime import timedelta
import logging
import models
import auth

# Import all routers
from routers import (
    users,
    training_plans,
    exercises,
    achievements,
    player_stats,
    challenge_progress,
    test_player_stats  # 👈 NY router til test
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Football Academy API")

# CORS settings for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"]
)

# Include all routers
app.include_router(users.router)
app.include_router(training_plans.router)
app.include_router(exercises.router)
app.include_router(achievements.router)
app.include_router(player_stats.router)
app.include_router(challenge_progress.router)
app.include_router(test_player_stats.router)  # 👈 NY test-router

# Token login endpoint
@app.post("/token")
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

# Health checks
@app.get("/")
async def root():
    return {"message": "Welcome to Football Academy API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}