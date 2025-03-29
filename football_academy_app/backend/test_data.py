from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import models
from database import engine, SessionLocal
import auth

# Create database tables if they don't exist
models.Base.metadata.create_all(bind=engine)

def insert_test_data():
    db = SessionLocal()
    try:
        # Check if coach user already exists
        coach = db.query(models.User).filter(models.User.email == "coach@example.com").first()
        if not coach:
            # Create a coach user
            coach = models.User(
                email="coach@example.com",
                hashed_password=auth.get_password_hash("coach123"),
                full_name="Coach Smith",
                position="Coach",
                current_club="FC Test",
                is_active=True,
                is_coach=True
            )
            db.add(coach)
            db.commit()
            db.refresh(coach)
            print(f"Created coach user: {coach.full_name} (ID: {coach.id})")
        else:
            print(f"Coach user already exists: {coach.full_name} (ID: {coach.id})")
        
        # Check if player user already exists
        player = db.query(models.User).filter(models.User.email == "player@example.com").first()
        if not player:
            # Create a player user
            player = models.User(
                email="player@example.com",
                hashed_password=auth.get_password_hash("player123"),
                full_name="Player Jones",
                position="ST",
                current_club="FC Test",
                is_active=True,
                is_coach=False
            )
            db.add(player)
            db.commit()
            db.refresh(player)
            print(f"Created player user: {player.full_name} (ID: {player.id})")
        else:
            print(f"Player user already exists: {player.full_name} (ID: {player.id})")
        
        # Create player stats for the player
        player_stats = db.query(models.PlayerStats).filter(models.PlayerStats.player_id == player.id).first()
        if not player_stats:
            player_stats = models.PlayerStats(
                player_id=player.id,
                pace=80,
                shooting=75,
                passing=70,
                dribbling=82,
                defense=65,
                physical=78,
                overall_rating=75
            )
            db.add(player_stats)
            db.commit()
            db.refresh(player_stats)
            print(f"Created player stats for {player.full_name}")
        else:
            print(f"Player stats already exist for {player.full_name}")
        
        # Create a challenge
        challenge = db.query(models.Challenge).filter(models.Challenge.title == "Test Challenge").first()
        if not challenge:
            challenge = models.Challenge(
                title="Test Challenge",
                description="This is a test challenge for testing purposes",
                points_value=10,
                created_by=coach.id,
                start_date=datetime.utcnow(),
                end_date=datetime.utcnow() + timedelta(days=7)
            )
            db.add(challenge)
            db.commit()
            db.refresh(challenge)
            print(f"Created challenge: {challenge.title} (ID: {challenge.id})")
        else:
            print(f"Challenge already exists: {challenge.title} (ID: {challenge.id})")
        
        # Create a challenge entry
        challenge_entry = db.query(models.ChallengeEntry).filter(
            models.ChallengeEntry.challenge_id == challenge.id,
            models.ChallengeEntry.user_id == player.id
        ).first()
        
        if not challenge_entry:
            challenge_entry = models.ChallengeEntry(
                challenge_id=challenge.id,
                user_id=player.id,
                submission_text="This is my submission for the test challenge",
                status="pending"
            )
            db.add(challenge_entry)
            db.commit()
            db.refresh(challenge_entry)
            print(f"Created challenge entry for {player.full_name}")
        else:
            print(f"Challenge entry already exists for {player.full_name}")
        
        # Create a test
        test = db.query(models.Test).filter(models.Test.title == "Fitness Test").first()
        if not test:
            test = models.Test(
                title="Fitness Test",
                description="A test to measure fitness levels",
                test_type="fitness",
                created_by=coach.id,
                points_scale=2.0
            )
            db.add(test)
            db.commit()
            db.refresh(test)
            print(f"Created test: {test.title} (ID: {test.id})")
        else:
            print(f"Test already exists: {test.title} (ID: {test.id})")
        
        # Create a test entry
        test_entry = db.query(models.TestEntry).filter(
            models.TestEntry.test_id == test.id,
            models.TestEntry.user_id == player.id
        ).first()
        
        if not test_entry:
            test_entry = models.TestEntry(
                test_id=test.id,
                user_id=player.id,
                score=85.5,
                notes="Good performance"
            )
            db.add(test_entry)
            db.commit()
            db.refresh(test_entry)
            print(f"Created test entry for {player.full_name}")
        else:
            print(f"Test entry already exists for {player.full_name}")
        
        # Create a training day
        training_day = db.query(models.TrainingDay).filter(models.TrainingDay.title == "Shooting Practice").first()
        if not training_day:
            training_day = models.TrainingDay(
                title="Shooting Practice",
                description="Practice shooting techniques",
                date=datetime.utcnow() + timedelta(days=2),
                instructions="Focus on accuracy and power",
                created_by=coach.id
            )
            db.add(training_day)
            db.commit()
            db.refresh(training_day)
            print(f"Created training day: {training_day.title} (ID: {training_day.id})")
        else:
            print(f"Training day already exists: {training_day.title} (ID: {training_day.id})")
        
        # Create a training day entry
        training_day_entry = db.query(models.TrainingDayEntry).filter(
            models.TrainingDayEntry.training_day_id == training_day.id,
            models.TrainingDayEntry.user_id == player.id
        ).first()
        
        if not training_day_entry:
            training_day_entry = models.TrainingDayEntry(
                training_day_id=training_day.id,
                user_id=player.id,
                pre_session_notes="Looking forward to improving my shooting",
                attendance_status="pending"
            )
            db.add(training_day_entry)
            db.commit()
            db.refresh(training_day_entry)
            print(f"Created training day entry for {player.full_name}")
        else:
            print(f"Training day entry already exists for {player.full_name}")
        
        # Create a league table entry for the player
        league_entry = db.query(models.LeagueTableEntry).filter(
            models.LeagueTableEntry.user_id == player.id
        ).first()
        
        if not league_entry:
            # Calculate points
            challenge_points = 10  # Example value
            test_points = int(test_entry.score * test.points_scale)
            
            league_entry = models.LeagueTableEntry(
                user_id=player.id,
                season="current",
                challenge_points=challenge_points,
                test_points=test_points,
                total_points=challenge_points + test_points,
                rank=1,
                last_calculated=datetime.utcnow()
            )
            db.add(league_entry)
            db.commit()
            db.refresh(league_entry)
            print(f"Created league table entry for {player.full_name}")
        else:
            print(f"League table entry already exists for {player.full_name}")
            
        # Create an exercise library item
        exercise = db.query(models.ExerciseLibrary).filter(models.ExerciseLibrary.title == "Shooting Drill").first()
        if not exercise:
            exercise = models.ExerciseLibrary(
                title="Shooting Drill",
                description="A drill to improve shooting accuracy",
                category="Shooting",
                difficulty_level="Intermediate",
                created_by=coach.id
            )
            db.add(exercise)
            db.commit()
            db.refresh(exercise)
            print(f"Created exercise: {exercise.title} (ID: {exercise.id})")
        else:
            print(f"Exercise already exists: {exercise.title} (ID: {exercise.id})")
        
    finally:
        db.close()

if __name__ == "__main__":
    insert_test_data()
    print("Test data insertion complete!") 