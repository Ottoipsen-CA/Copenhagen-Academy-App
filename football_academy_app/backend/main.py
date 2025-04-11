from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os

from database import engine, Base

# Import routers
from routers import (
    auth, 
    skill_tests, 
    challenges, 
    league_table,
    development_plans
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Football Academy API",
    description="""
    Football Academy API provides endpoints for managing player profiles, training plans, 
    challenges, achievements, and player statistics. 
    
    This API allows players to track their progress, complete challenges, and improve their football skills.
    """,
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables
Base.metadata.create_all(bind=engine)

# Mount static files if they exist
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    from fastapi.staticfiles import StaticFiles
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Include routers with the v2 prefix
app.include_router(auth.router, prefix="/api/v2")
app.include_router(skill_tests.router, prefix="/api/v2")
app.include_router(challenges.router, prefix="/api/v2")
app.include_router(league_table.router, prefix="/api/v2")
app.include_router(development_plans.router, prefix="/api/v2")

@app.get("/")
async def root():
    return {
        "message": "Welcome to Football Academy API",
        "docs_url": "/docs",
        "version": "2.0.0"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/debug/routes")
async def list_routes():
    routes = []
    for route in app.routes:
        if hasattr(route, "path"):
            routes.append({
                "path": route.path,
                "name": route.name,
                "methods": route.methods if hasattr(route, "methods") else None
            })
    return routes 