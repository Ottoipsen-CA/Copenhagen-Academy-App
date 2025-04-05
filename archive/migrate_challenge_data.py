import os
import sys
from datetime import datetime
from sqlalchemy.orm import Session

# Add parent directory to path
parent_dir = os.path.dirname(os.path.abspath(__file__))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

import models
from database import get_db, engine

def migrate_challenge_data():
    """
    Migrate existing UserChallenge data to the new ChallengeStatus system.
    This script should be run once after updating the database schema.
    """
    # Create the new tables if they don't exist
    models.Base.metadata.create_all(bind=engine)
    
    # Get database session
    db = next(get_db())
    
    try:
        # Get all users
        users = db.query(models.User).all()
        print(f"Found {len(users)} users to migrate")
        
        # For each user
        for user in users:
            print(f"Migrating challenges for user: {user.email}")
            
            # Get user's completed challenges (from old model)
            user_challenges = db.query(models.UserChallenge).filter(
                models.UserChallenge.user_id == user.id
            ).all()
            
            # Check if user already has challenge statuses
            existing_statuses = db.query(models.ChallengeStatus).filter(
                models.ChallengeStatus.user_id == user.id
            ).first()
            
            if existing_statuses:
                print(f"User {user.email} already has challenge statuses, skipping")
                continue
            
            # Get all challenges
            challenges = db.query(models.Challenge).all()
            
            # Create dictionary of completed challenges
            completed_challenges = {uc.challenge_id: uc.completed_at for uc in user_challenges}
            
            # Group challenges by category and level
            challenges_by_category = {}
            for challenge in challenges:
                if challenge.category not in challenges_by_category:
                    challenges_by_category[challenge.category] = {}
                
                if challenge.level not in challenges_by_category[challenge.category]:
                    challenges_by_category[challenge.category][challenge.level] = []
                
                challenges_by_category[challenge.category][challenge.level].append(challenge)
            
            # Create challenge statuses for the user
            statuses_to_add = []
            now = datetime.utcnow()
            
            # For each category and level
            for category, levels in challenges_by_category.items():
                # Sort levels
                sorted_levels = sorted(levels.keys())
                
                # Initialize variables to track highest completed level
                highest_completed_level = 0
                
                # Determine highest completed level for this category
                for level in sorted_levels:
                    challenges_in_level = levels[level]
                    all_completed = True
                    
                    for challenge in challenges_in_level:
                        if challenge.id not in completed_challenges:
                            all_completed = False
                            break
                    
                    if all_completed:
                        highest_completed_level = level
                    else:
                        break
                
                # Create statuses for all challenges in this category
                for level in sorted_levels:
                    challenges_in_level = levels[level]
                    
                    for challenge in challenges_in_level:
                        # Determine status
                        if challenge.id in completed_challenges:
                            # Challenge was completed
                            status = "COMPLETED"
                            unlocked_at = completed_challenges[challenge.id] - datetime.timedelta(minutes=30)  # Approximate
                            completed_at = completed_challenges[challenge.id]
                        elif level <= highest_completed_level + 1 or challenge.is_weekly:
                            # Challenge should be available (next level after highest completed or weekly)
                            status = "AVAILABLE"
                            unlocked_at = now
                            completed_at = None
                        else:
                            # Challenge should be locked
                            status = "LOCKED"
                            unlocked_at = None
                            completed_at = None
                        
                        # Create status record
                        status_record = models.ChallengeStatus(
                            user_id=user.id,
                            challenge_id=challenge.id,
                            status=status,
                            unlocked_at=unlocked_at,
                            completed_at=completed_at
                        )
                        statuses_to_add.append(status_record)
            
            # Add all statuses in batch
            db.add_all(statuses_to_add)
            print(f"Added {len(statuses_to_add)} challenge statuses for user {user.email}")
        
        # Commit changes
        db.commit()
        print("Migration completed successfully")
    
    except Exception as e:
        db.rollback()
        print(f"Error during migration: {str(e)}")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()

if __name__ == "__main__":
    migrate_challenge_data() 