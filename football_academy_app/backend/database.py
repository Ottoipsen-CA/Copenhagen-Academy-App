from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from config import settings
import sys

# Ensure we're using PostgreSQL
if not settings.DATABASE_URL.startswith("postgresql"):
    print("ERROR: Database URL must be a PostgreSQL connection string")
    print(f"Current DATABASE_URL: {settings.DATABASE_URL}")
    sys.exit(1)

# Create SQLAlchemy engine - PostgreSQL only
engine = create_engine(
    settings.DATABASE_URL
)

# Create async engine - PostgreSQL only
async_engine = create_async_engine(
    settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")
)

# Create session factory
SessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine,
    expire_on_commit=False
)

# Create async session factory
AsyncSessionLocal = sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Create base class for models
Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Async dependency to get DB session
async def get_async_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close() 