from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_security_headers():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["cross-origin-resource-policy"] == "same-origin"
