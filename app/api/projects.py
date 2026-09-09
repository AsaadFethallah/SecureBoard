from fastapi import (
    APIRouter,
    Depends,
    status,
)
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.project import Project
from app.schemas.project import (
    ProjectCreate,
    ProjectResponse,
)


router = APIRouter(
    prefix="/projects",
    tags=["projects"],
)


@router.get(
    "/",
    response_model=list[ProjectResponse],
)
def list_projects(
    db: Session = Depends(get_db),
):
    statement = (
        select(Project)
        .order_by(Project.id)
    )

    projects = db.scalars(
        statement
    ).all()

    return projects


@router.post(
    "/",
    response_model=ProjectResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_project(
    project: ProjectCreate,
    db: Session = Depends(get_db),
):
    new_project = Project(
        name=project.name,
        description=project.description,
    )

    db.add(new_project)
    db.commit()
    db.refresh(new_project)

    return new_project