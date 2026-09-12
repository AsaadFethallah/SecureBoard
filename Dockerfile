FROM python:3.14-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Apply available Debian security updates
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip uninstall -y pip setuptools wheel

COPY app ./app
COPY alembic ./alembic
COPY alembic.ini .

RUN useradd --create-home --shell /usr/sbin/nologin secureboard \
    && chown -R secureboard:secureboard /app

USER secureboard

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]