"""create tables

Revision ID: 3a6e27661a1e
Revises: 
Create Date: 2025-04-12 09:22:26.522204

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# Import our SQLAlchemy models
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent.parent))

from database import Base
import models  # This will import all models through __init__.py

# revision identifiers, used by Alembic.
revision: str = '3a6e27661a1e'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create all tables in the database."""
    # Get the SQLAlchemy engine connection
    connection = op.get_bind()
    
    # Create all tables defined in our models
    Base.metadata.create_all(connection)


def downgrade() -> None:
    """Drop all tables in the database."""
    # Get the SQLAlchemy engine connection
    connection = op.get_bind()
    
    # Drop all tables defined in our models
    Base.metadata.drop_all(connection)
