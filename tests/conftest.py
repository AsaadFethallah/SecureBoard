import os

import pytest
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app

# Import models so SQLAlchemy registers their tables
# inside Base.metadata.
from app.models import Project, User  # noqa: F401


load_dotenv()


TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL")

if not TEST_DATABASE_URL:
    raise RuntimeError(
        "TEST_DATABASE_URL environment variable is not configured"
    )


# Safety guard:
# Never allow the test suite to wipe the normal development database.
database_name = make_url(TEST_DATABASE_URL).database

if not database_name or not database_name.endswith("_test"):
    raise RuntimeError(
        "Refusing to run tests: TEST_DATABASE_URL must point "
        "to a database whose name ends with '_test'"
    )


test_engine = create_engine(
    TEST_DATABASE_URL,
    pool_pre_ping=True,
)


TestingSessionLocal = sessionmaker(
    bind=test_engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


def override_get_db():
    db = TestingSessionLocal()

    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def reset_test_database():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)

    yield

    Base.metadata.drop_all(bind=test_engine)