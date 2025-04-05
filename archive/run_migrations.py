import os
import sys

# Add parent directory to path
parent_dir = os.path.dirname(os.path.abspath(__file__))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

import models
from database import engine

def run_migrations():
    """
    Run database migrations to create new tables.
    
    This script only creates tables that don't already exist and doesn't drop existing tables,
    making it safe to run on an existing database.
    """
    print("Running database migrations...")
    models.Base.metadata.create_all(bind=engine)
    print("Migrations completed successfully!")

if __name__ == "__main__":
    run_migrations()
    
    # Ask if user wants to run test data script
    user_input = input("Do you want to add test data for challenges? (y/n): ")
    if user_input.lower() == 'y':
        from test_data import add_test_data
        add_test_data()
        print("Test data added successfully!")
    
    # Ask if user wants to migrate existing challenge data
    user_input = input("Do you want to migrate existing challenge data? (y/n): ")
    if user_input.lower() == 'y':
        from migrate_challenge_data import migrate_challenge_data
        migrate_challenge_data()
        print("Existing data migrated successfully!") 