import os
from pathlib import Path

from dotenv import load_dotenv


load_dotenv()


def read_secret(name: str) -> str:
    """
    Read a sensitive configuration value.

    Priority:
    1. <NAME>_FILE
    2. <NAME> environment variable

    This allows Kubernetes secrets to be mounted as files
    while preserving normal .env/environment usage locally.
    """

    file_path = os.getenv(f"{name}_FILE")

    if file_path:
        try:
            value = Path(file_path).read_text(
                encoding="utf-8"
            ).strip()
        except OSError as exc:
            raise RuntimeError(
                f"{name}_FILE could not be read"
            ) from exc

        if not value:
            raise RuntimeError(
                f"{name}_FILE is empty"
            )

        return value

    value = os.getenv(name)

    if value:
        return value

    raise RuntimeError(
        f"{name} or {name}_FILE is not configured"
    )
