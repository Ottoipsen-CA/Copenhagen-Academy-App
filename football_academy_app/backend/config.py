from pydantic import BaseSettings
from typing import Optional
import os
from dotenv import load_dotenv
from pathlib import Path

load_dotenv()

# Get the directory where this config file is located
BACKEND_DIR = Path(__file__).resolve().parent

class Settings(BaseSettings):
    # API Settings
    API_V1_STR: str = "/api/v1"
    API_V2_STR: str = "/api/v2"
    PROJECT_NAME: str = "Football Academy API"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-here")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    # Construct the default path relative to the backend directory
    DEFAULT_DB_PATH = BACKEND_DIR / "football_academy.db"
    DATABASE_URL: str = os.getenv("DATABASE_URL", f"sqlite:///{DEFAULT_DB_PATH}")
    
    # CORS
    BACKEND_CORS_ORIGINS: list = ["*"]
    
    # File Upload
    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    
    class Config:
        case_sensitive = True

settings = Settings() 