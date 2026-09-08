from fastapi import FastAPI

from app.api.projects import router as projects_router


app = FastAPI(
    title="SecureBoard API",
    version="0.1.0",
)

app.include_router(projects_router)


@app.get("/")
def root():
    return {
        "message": "SecureBoard API"
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }