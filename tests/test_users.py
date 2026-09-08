from fastapi.testclient import TestClient

from app.api.users import users
from app.main import app


client = TestClient(app)


def setup_function():
    users.clear()


def test_create_user():
    response = client.post(
        "/users/",
        json={
            "username": "asaad",
            "email": "asaad@example.com",
            "password": "SecurePassword123",
        },
    )

    assert response.status_code == 201

    data = response.json()

    assert data["username"] == "asaad"
    assert data["email"] == "asaad@example.com"
    assert "password" not in data
    assert "hashed_password" not in data


def test_invalid_user():
    response = client.post(
        "/users/",
        json={
            "username": "ab",
            "email": "invalid-email",
            "password": "123",
        },
    )

    assert response.status_code == 422


def test_duplicate_email():
    user = {
        "username": "asaad",
        "email": "asaad@example.com",
        "password": "SecurePassword123",
    }

    first_response = client.post("/users/", json=user)
    second_response = client.post("/users/", json=user)

    assert first_response.status_code == 201
    assert second_response.status_code == 409