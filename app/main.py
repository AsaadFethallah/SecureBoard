from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.api.projects import router as projects_router
from app.api.users import router as users_router

app = FastAPI(
    title="SecureBoard API",
    version="0.1.0",
)


@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"

    return response


app.include_router(auth_router)
app.include_router(projects_router)
app.include_router(users_router)


@app.get("/")
def root():
    return {"message": "SecureBoard API"}


@app.get("/health")
def health():
    return {"status": "ok"}