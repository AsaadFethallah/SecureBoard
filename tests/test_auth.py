from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def register_user():
    return client.post(
        "/users/",
        json={
            "username": "asaad",
            "email": "asaad@example.com",
            "password": "SecurePassword123",
        },
    )


def test_login():
    register_user()

    response = client.post(
        "/auth/login",
        data={
            "username": "asaad",
            "password": "SecurePassword123",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password():
    register_user()

    response = client.post(
        "/auth/login",
        data={
            "username": "asaad",
            "password": "WrongPassword",
        },
    )

    assert response.status_code == 401


def test_protected_endpoint_without_token():
    response = client.get(
        "/auth/me"
    )

    assert response.status_code == 401


def test_protected_endpoint_with_token():
    register_user()

    login_response = client.post(
        "/auth/login",
        data={
            "username": "asaad",
            "password": "SecurePassword123",
        },
    )

    token = login_response.json()[
        "access_token"
    ]

    response = client.get(
        "/auth/me",
        headers={
            "Authorization": f"Bearer {token}"
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["username"] == "asaad"
    assert data["email"] == "asaad@example.com"