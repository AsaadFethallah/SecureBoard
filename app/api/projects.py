from fastapi import APIRouter

from app.schemas.project import ProjectCreate


router = APIRouter(
    prefix="/projects",
    tags=["projects"],
)


projects = []


@router.get("/")
def list_projects():
    return projects


@router.post("/", status_code=201)
def create_project(project: ProjectCreate):
    new_project = {
        "id": len(projects) + 1,
        "name": project.name,
        "description": project.description,
    }

    projects.append(new_project)

    return new_project