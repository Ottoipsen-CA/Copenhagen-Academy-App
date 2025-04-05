import sys
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

def make_all_challenges_available():
    """Make all challenges available for all users in the database."""
    db = SessionLocal()
    try:
        # Get all users
        users = db.query(models.User).all()
        print(f"Found {len(users)} users")
        
        for user in users:
            print(f"\nProcessing user: {user.email} (ID: {user.id})")
            
            # Get all challenges
            all_challenges = db.query(models.Challenge).all()
            print(f"Found {len(all_challenges)} total challenges")
            
            # Get existing challenge statuses for this user
            existing_statuses = db.query(models.ChallengeStatus).filter(
                models.ChallengeStatus.user_id == user.id
            ).all()
            
            existing_challenge_ids = {status.challenge_id for status in existing_statuses}
            print(f"User has {len(existing_statuses)} existing challenge statuses")
            
            # Update all existing statuses to AVAILABLE
            for status in existing_statuses:
                if status.status != "AVAILABLE":
                    print(f"  Updating challenge {status.challenge_id} from {status.status} to AVAILABLE")
                    status.status = "AVAILABLE"
                    status.unlocked_at = models.datetime.utcnow()
            
            # Add new AVAILABLE statuses for challenges that don't have a status yet
            new_statuses = []
            for challenge in all_challenges:
                if challenge.id not in existing_challenge_ids:
                    print(f"  Creating new AVAILABLE status for challenge {challenge.id} ({challenge.title})")
                    new_status = models.ChallengeStatus(
                        user_id=user.id,
                        challenge_id=challenge.id,
                        status="AVAILABLE",
                        unlocked_at=models.datetime.utcnow()
                    )
                    new_statuses.append(new_status)
            
            if new_statuses:
                db.add_all(new_statuses)
                print(f"Added {len(new_statuses)} new challenge statuses")
            
            db.commit()
            print(f"All challenges are now AVAILABLE for user {user.email}")
    
    finally:
        db.close()

if __name__ == "__main__":
    make_all_challenges_available() 