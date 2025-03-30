from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
import logging
from datetime import datetime

from models import User as UserModel, ChallengeStatus, Challenge
from database import get_db
from auth import get_password_hash, get_current_active_user
from schemas import UserCreate, UserBase, UserResponse

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={
        404: {"description": "User not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

logger = logging.getLogger(__name__)


@router.post("/", 
             response_model=UserResponse,
             status_code=status.HTTP_201_CREATED,
             summary="Create a new user",
             description="Create a new user with the provided information and return the created user details",
             responses={
                 201: {
                     "description": "User created successfully",
                     "content": {
                         "application/json": {
                             "example": {
                                 "id": 1,
                                 "email": "player@example.com",
                                 "full_name": "John Doe",
                                 "position": "Striker",
                                 "current_club": "FC Example",
                                 "date_of_birth": "2000-01-01"
                             }
                         }
                     }
                 },
                 400: {"description": "Email already registered"}
             })
async def create_user(user: UserCreate, db: Session = Depends(get_db), request: Request = None):
    try:
        logger.info(f"Registration attempt for email: {user.email}")

        if request:
            body = await request.body()
            logger.info(f"Raw request body: {body}")
            logger.info(f"Request headers: {request.headers}")

        existing_user = db.query(UserModel).filter(UserModel.email == user.email).first()
        if existing_user:
            logger.warning(f"Email already registered: {user.email}")
            raise HTTPException(status_code=400, detail="Email already registered")

        hashed_password = get_password_hash(user.password)

        db_user = UserModel(
            email=user.email,
            hashed_password=hashed_password,
            full_name=user.full_name,
            position=user.position,
            current_club=user.current_club,
            date_of_birth=user.date_of_birth
        )

        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        logger.info(f"User registered successfully: {user.email}")
        return db_user

    except Exception as e:
        logger.error(f"Error registering user: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        raise


@router.get("/me", 
            response_model=UserResponse, 
            summary="Get current user details",
            description="Get details of the currently authenticated user")
def read_users_me(current_user: UserModel = Depends(get_current_active_user)):
    return current_user


@router.get("/{user_id}", 
            response_model=UserResponse,
            summary="Get user by ID",
            description="Get details of a specific user by their ID",
            responses={404: {"description": "User not found"}})
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user


@router.put("/me", 
            response_model=UserResponse,
            summary="Update current user",
            description="Update details of the currently authenticated user")
def update_user(
    user_update: UserBase,
    current_user: UserModel = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    for field, value in user_update.dict().items():
        setattr(current_user, field, value)

    db.commit()
    db.refresh(current_user)
    return current_user


@router.delete("/me", 
               status_code=status.HTTP_204_NO_CONTENT,
               summary="Delete current user",
               description="Delete the currently authenticated user's account",
               responses={204: {"description": "User deleted successfully"}})
def delete_user(
    current_user: UserModel = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    db.delete(current_user)
    db.commit()
    return None


# -----------------------------
# Update Challenge Status and Unlock Next Challenge
# -----------------------------
@router.patch("/update_challenge_status")
async def update_challenge_status(
    user_id: int,
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_active_user)
):
    # Find udfordringen for den pågældende bruger
    challenge_status = db.query(ChallengeStatus).filter(
        ChallengeStatus.user_id == user_id,
        ChallengeStatus.challenge_id == challenge_id
    ).first()

    if not challenge_status:
        raise HTTPException(status_code=404, detail="Challenge not found for the user")

    # Hvis udfordringen er låst (LOCKED), gør den til tilgængelig (AVAILABLE)
    if challenge_status.status == "LOCKED":
        challenge_status.status = "AVAILABLE"
        db.commit()

    # Hvis udfordringen er fuldført (COMPLETED), gør den det officielt
    if challenge_status.status == "AVAILABLE":
        challenge_status.status = "COMPLETED"
        challenge_status.completed_at = datetime.utcnow()  # Mark as completed at current time
        db.commit()

    # Find næste udfordring og opdater dens status
    next_challenge = db.query(Challenge).filter(
        Challenge.prerequisite_id == challenge_id
    ).first()

    if next_challenge:
        # Sæt næste udfordring som tilgængelig
        next_challenge_status = ChallengeStatus(
            user_id=user_id,
            challenge_id=next_challenge.id,
            status="AVAILABLE",
            unlocked_at=datetime.utcnow()  # Mark as unlocked at current time
        )
        db.add(next_challenge_status)
        db.commit()

    return {"message": "Challenge status updated successfully!"}
