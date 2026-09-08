from fastapi import APIRouter, HTTPException, status

from app.core.security import hash_password
from app.schemas.user import UserCreate, UserResponse


router = APIRouter(
    prefix="/users",
    tags=["users"],
)


users = []


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_user(user: UserCreate):
    for existing_user in users:
        if existing_user["email"] == user.email:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )

    new_user = {
        "id": len(users) + 1,
        "username": user.username,
        "email": user.email,
        "hashed_password": hash_password(user.password),
    }

    users.append(new_user)

    return new_user