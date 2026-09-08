from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_create_project():
    response = client.post(
        "/projects/",
        json={
            "name": "SecureBoard",
            "description": "DevSecOps project",
        },
    )

    assert response.status_code == 201

    data = response.json()

    assert data["name"] == "SecureBoard"
    assert data["description"] == "DevSecOps project"
    assert "id" in data


def test_create_project_without_name():
    response = client.post(
        "/projects/",
        json={
            "description": "Missing name",
        },
    )

    assert response.status_code == 422