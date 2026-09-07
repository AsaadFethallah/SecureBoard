from fastapi import FastAPI

app = FastAPI(
    title="SecureBoard API",
    version="0.1.0",
)


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