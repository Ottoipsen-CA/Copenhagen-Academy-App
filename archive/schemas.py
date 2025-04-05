from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


# -------- USER --------
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    position: Optional[str] = None
    current_club: Optional[str] = None
    date_of_birth: Optional[datetime] = None


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: int
    is_active: bool
    is_coach: bool

    class Config:
        from_attributes = True


# -------- TRAINING PLANS --------
class TrainingPlanBase(BaseModel):
    title: str
    description: Optional[str] = None


class TrainingPlanCreate(TrainingPlanBase):
    pass


class TrainingPlan(TrainingPlanBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# -------- EXERCISES --------
class ExerciseBase(BaseModel):
    name: str
    description: Optional[str] = None
    video_url: Optional[str] = None


class ExerciseCreate(ExerciseBase):
    pass


class Exercise(ExerciseBase):
    id: int
    training_plan_id: int

    class Config:
        from_attributes = True


# -------- PLAYER STATS --------
class PlayerStatBase(BaseModel):
    pace: int
    shooting: int
    passing: int
    dribbling: int
    juggles: int
    first_touch: int
    overall_rating: int


class PlayerStatCreate(PlayerStatBase):
    player_id: int


class PlayerStat(PlayerStatBase):
    id: int
    player_id: int
    last_updated: datetime

    class Config:
        from_attributes = True


# Create an alias for PlayerStatsResponse to match the endpoint
class PlayerStatsResponse(PlayerStat):
    pass


# -------- ACHIEVEMENTS --------
class AchievementBase(BaseModel):
    title: str
    description: Optional[str] = None


class AchievementCreate(AchievementBase):
    pass


class Achievement(AchievementBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# -------- AUTH --------
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


# -------- CHALLENGES --------
class ChallengeBase(BaseModel):
    title: str
    description: Optional[str] = None
    xp_reward: int
    category: Optional[str] = None
    is_weekly: Optional[bool] = False
    level: Optional[int] = 1
    prerequisite_id: Optional[int] = None


class ChallengeCreate(ChallengeBase):
    pass


class ChallengeResponse(ChallengeBase):
    id: int

    class Config:
        from_attributes = True


# -------- CHALLENGE STATUS --------
class ChallengeStatusBase(BaseModel):
    user_id: int
    challenge_id: int
    status: str = "LOCKED"  # LOCKED, AVAILABLE, COMPLETED
    unlocked_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class ChallengeStatusCreate(BaseModel):
    challenge_id: int
    status: str = "LOCKED"


class ChallengeStatusResponse(ChallengeStatusBase):
    id: int

    class Config:
        from_attributes = True


# -------- CHALLENGE WITH STATUS --------
class ChallengeWithStatus(ChallengeResponse):
    status: str = "LOCKED"
    unlocked_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# -------- USER CHALLENGES --------
class UserChallengeResponse(BaseModel):
    id: int
    user_id: int
    challenge_id: int
    completed_at: datetime

    class Config:
        from_attributes = True


# -------- BADGES --------
class UserBadgeResponse(BaseModel):
    id: int
    user_id: int
    badge_name: str
    awarded_at: datetime

    class Config:
        from_attributes = True


# -------- CHALLENGE COMPLETION --------
class ChallengeCompletionCreate(BaseModel):
    challenge_id: int


class ChallengeCompletionWithDetails(BaseModel):
    id: int
    user_id: int
    challenge_id: int
    completed_at: datetime
    challenge_title: Optional[str]

    class Config:
        from_attributes = True


# -------- USER PROGRESS --------
class UserProgressResponse(BaseModel):
    user: UserResponse
    completed_challenges: List[UserChallengeResponse]
    badges: List[UserBadgeResponse]
    total_xp: int

    class Config:
        from_attributes = True


# -------- BADGE WITH CHALLENGE --------
class BadgeWithChallenge(BaseModel):
    id: int
    badge_name: str
    challenge_id: int
    challenge_title: str

    class Config:
        from_attributes = True


# -------------------------------
# ChallengeCompletion Schemas
# -------------------------------
class ChallengeCompletionBase(BaseModel):
    user_id: int
    challenge_id: int


class ChallengeCompletionCreate(ChallengeCompletionBase):
    pass

class ChallengeCompletion(ChallengeCompletionBase):
    id: int
    completed_at: datetime

    class Config:
        from_attributes = True

# -------- SIMPLE PLAYER STATS TEST (til test route) --------
class SimplePlayerStatBase(BaseModel):
    pace: int
    shooting: int
    passing: int
    player_id: int

class SimplePlayerStatCreate(SimplePlayerStatBase):
    pass

class SimplePlayerStat(SimplePlayerStatBase):
    id: int

    class Config:
        from_attributes = True

# -------- LEAGUE TABLE --------
class LeagueTableEntry(BaseModel):
    id: int
    player_id: int
    player_name: Optional[str] = None # We might need to join tables to get the name
    rank: Optional[int] = None
    points: int = 0
    matches_played: Optional[int] = 0
    wins: Optional[int] = 0
    draws: Optional[int] = 0
    losses: Optional[int] = 0

    class Config:
        from_attributes = True

# -------- TESTS --------
class TestBase(BaseModel):
    name: str
    description: Optional[str] = None
    test_type: Optional[str] = None # e.g., Sprint, Agility, Shooting
    metric: Optional[str] = None # e.g., Seconds, Score, Accuracy %

class TestCreate(TestBase):
    pass

class Test(TestBase):
    id: int

    class Config:
        from_attributes = True

# -------- TEST ENTRIES / RESULTS --------
class TestEntryBase(BaseModel):
    test_id: int
    player_id: int
    result: Optional[str] = None # Could be time, score, etc. depending on test metric
    notes: Optional[str] = None
    date_recorded: Optional[datetime] = datetime.now()

class TestEntryCreate(TestEntryBase):
    pass

class TestEntry(TestEntryBase):
    id: int

    class Config:
        from_attributes = True

# -------- TRAINING DAYS --------
class TrainingDayBase(BaseModel):
    training_plan_id: int
    day_number: int # e.g., Day 1, Day 2
    focus: Optional[str] = None # e.g., Endurance, Skills, Tactics
    date_scheduled: Optional[datetime] = None

class TrainingDayCreate(TrainingDayBase):
    pass

class TrainingDay(TrainingDayBase):
    id: int
    # Potentially add a list of exercises for this day later
    # exercises: List[Exercise] = []

    class Config:
        from_attributes = True

# -------- TRAINING DAY ENTRIES (Exercises for a day) --------
class TrainingDayEntryBase(BaseModel):
    training_day_id: int
    exercise_id: int
    sets: Optional[int] = None
    reps: Optional[int] = None
    duration_minutes: Optional[int] = None
    order: Optional[int] = None # Order of exercise within the day

class TrainingDayEntryCreate(TrainingDayEntryBase):
    pass

class TrainingDayEntry(TrainingDayEntryBase):
    id: int
    exercise: Optional[Exercise] = None # Include exercise details

    class Config:
        from_attributes = True

# -------- EXERCISE LIBRARY --------
class ExerciseLibraryBase(BaseModel):
    name: str
    description: Optional[str] = None
    video_url: Optional[str] = None
    category: Optional[str] = None # e.g., Dribbling, Shooting, Agility
    difficulty: Optional[str] = None # e.g., Beginner, Intermediate, Advanced

class ExerciseLibraryCreate(ExerciseLibraryBase):
    pass

class ExerciseLibrary(ExerciseLibraryBase):
    id: int

    class Config:
        from_attributes = True

# -------- PLAYER TEST RESULTS --------
class PlayerTestResultBase(BaseModel):
    player_id: int
    test_id: int
    result: Optional[str] = None # e.g., time, score, count
    notes: Optional[str] = None
    date_taken: Optional[datetime] = datetime.now()

class PlayerTestCreate(PlayerTestResultBase):
    pass

# Renaming to match the usage in player_tests.py router
class PlayerTestResponse(PlayerTestResultBase):
    id: int
    test: Optional[Test] = None # Include Test details

    class Config:
        from_attributes = True

class PlayerTestUpdate(BaseModel):
    result: Optional[str] = None
    notes: Optional[str] = None
    date_taken: Optional[datetime] = None
