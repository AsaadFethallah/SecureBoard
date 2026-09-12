from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import hash_password
from app.models.user import User
from app.schemas.user import (
    UserCreate,
    UserResponse,
)


router = APIRouter(
    prefix="/users",
    tags=["users"],
)


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
):
    existing_user = db.scalar(
        select(User).where(
            or_(
                User.email == user.email,
                User.username == user.username,
            )
        )
    )

    if existing_user:
        if existing_user.email == user.email:
            detail = "Email already registered"
        else:
            detail = "Username already registered"

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail,
        )

    new_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hash_password(
            user.password
        ),
    )

    db.add(new_user)

    try:
        db.commit()

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already exists",
        )

    db.refresh(new_user)

    return new_user