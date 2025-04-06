from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import logging
from datetime import timedelta
from typing import Optional

from models import User as UserModel
from database import get_db
from services.auth import AuthService, oauth2_scheme
from schemas import UserCreate, UserUpdate, UserResponse, Token, TokenData

# Update the OAuth2 scheme to point to the correct token endpoint with full path
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v2/auth/token")

router = APIRouter(
    prefix="/auth",
    tags=["authentication"],
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"},
        403: {"description": "Not authorized to perform requested action"}
    }
)

logger = logging.getLogger(__name__)

def get_auth_service(db: Session = Depends(get_db)) -> AuthService:
    return AuthService(db)

async def get_current_user(token: str = Depends(oauth2_scheme), service: AuthService = Depends(get_auth_service)) -> UserModel:
    user = service.get_current_user(token=token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

async def get_current_active_user(current_user: UserModel = Depends(get_current_user)) -> UserModel:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# Token expiration time (minutes)
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

@router.post("/register", 
             response_model=UserResponse,
             status_code=status.HTTP_201_CREATED,
             summary="Register a new user",
             description="Register a new user with the provided information and return the created user details")
async def register(
    user: UserCreate, 
    service: AuthService = Depends(get_auth_service),
    request: Request = None
):
    try:
        logger.info(f"Registration attempt for email: {user.email}")

        if request:
            body = await request.body()
            logger.info(f"Raw request body: {body}")
            logger.info(f"Request headers: {request.headers}")

        existing_user = service.get_user_by_email(email=user.email)
        if existing_user:
            logger.warning(f"Email already registered: {user.email}")
            raise HTTPException(status_code=400, detail="Email already registered")

        db_user = service.create_user(user=user)

        logger.info(f"User registered successfully: {user.email}")
        return db_user

    except HTTPException as http_ex:
        logger.warning(f"Registration failed for {user.email}: {http_ex.detail}")
        raise http_ex
    except Exception as e:
        logger.error(f"Error registering user {user.email}: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail="Internal server error during registration.")

@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    service: AuthService = Depends(get_auth_service)
):
    user = service.authenticate_user(email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = service.create_access_token(
        data={"sub": user.email, "user_id": user.user_id}, expires_delta=access_token_expires
    )
    service.update_last_login(user.user_id)
    return {"access_token": access_token, "token_type": "bearer"}

# Keep the /login endpoint for backward compatibility
@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    service: AuthService = Depends(get_auth_service)
):
    return await login_for_access_token(form_data, service)

@router.get("/me", 
            response_model=UserResponse, 
            summary="Get current user details",
            description="Get details of the currently authenticated user")
def read_users_me(current_user: UserModel = Depends(get_current_active_user)):
    return current_user

@router.put("/me", 
            response_model=UserResponse,
            summary="Update current user",
            description="Update details of the currently authenticated user")
def update_user_me(
    user_update: UserUpdate,
    current_user: UserModel = Depends(get_current_active_user),
    service: AuthService = Depends(get_auth_service)
):
    updated_user = service.update_user(user_id=current_user.user_id, user_update=user_update)
    return updated_user

@router.delete("/me", 
               status_code=status.HTTP_204_NO_CONTENT,
               summary="Delete current user",
               description="Delete the currently authenticated user's account")
def delete_user_me(
    current_user: UserModel = Depends(get_current_active_user),
    service: AuthService = Depends(get_auth_service)
):
    deleted = service.delete(id=current_user.user_id)
    if not deleted:
         raise HTTPException(status_code=500, detail="Failed to delete user.")
    logger.info(f"User deleted: {current_user.email}")
    return None 