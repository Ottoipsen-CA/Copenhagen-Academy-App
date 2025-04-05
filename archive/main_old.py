from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import logging
import os

from config import settings
from database import engine, Base
from middleware.cors import add_cors_middleware
from middleware.logging import LoggingMiddleware

# Import routers
from routers import (
    auth,
    skill_tests,
    challenges,
    league_table,
    training_plan,
    exercise_library
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="""
    Football Academy API provides endpoints for managing player profiles, training plans, 
    challenges, achievements, and player statistics. 
    
    This API allows players to track their progress, complete challenges, and improve their football skills.
    """,
    version="2.0.0",
    openapi_url=f"/openapi.json",
    docs_url=None,
    redoc_url=None,
)

# Add middleware
add_cors_middleware(app)
app.add_middleware(LoggingMiddleware)

# Create database tables
Base.metadata.create_all(bind=engine)

# Mount static files
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Create v1 and v2 sub-applications with their own documentation
v1_app = FastAPI(
    title=f"{settings.PROJECT_NAME} - V1",
    description="Legacy API endpoints (v1)",
    version="1.0.0",
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

v2_app = FastAPI(
    title=f"{settings.PROJECT_NAME} - V2",
    description="New consolidated API endpoints (v2)",
    version="2.0.0",
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Include routers in v1 app
v1_app.include_router(auth.router)
v1_app.include_router(skill_tests.router)
v1_app.include_router(challenges.router)
v1_app.include_router(league_table.router)
v1_app.include_router(training_plan.router)
v1_app.include_router(exercise_library.router)

# Include consolidated routers in v2 app
v2_app.include_router(auth.router)
v2_app.include_router(skill_tests.router)
v2_app.include_router(challenges.router)
v2_app.include_router(league_table.router)
v2_app.include_router(training_plan.router)
v2_app.include_router(exercise_library.router)

# Mount sub-applications
app.mount(settings.API_V1_STR, v1_app)
app.mount(settings.API_V2_STR, v2_app)

@app.get("/")
async def root():
    return {
        "message": "Welcome to Football Academy API",
        "docs_v1_url": f"{settings.API_V1_STR}/docs",
        "docs_v2_url": f"{settings.API_V2_STR}/docs",
        "version": "2.0.0"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}