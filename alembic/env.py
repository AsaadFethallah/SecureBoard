from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.core.database import Base, DATABASE_URL

# Import models so Alembic can discover their metadata
# when using --autogenerate.
import app.models  # noqa: F401


# Alembic Config object, which provides access
# to values within alembic.ini.
config = context.config


# DATABASE_URL is resolved by app.core.database.
#
# It supports:
#   DATABASE_URL
# or:
#   DATABASE_URL_FILE
#
# The replace is important because Alembic/ConfigParser
# interprets "%" as interpolation syntax.
config.set_main_option(
    "sqlalchemy.url",
    DATABASE_URL.replace("%", "%%"),
)


# Configure Python logging from alembic.ini.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)


# SQLAlchemy metadata used by Alembic autogenerate.
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """
    Run migrations in 'offline' mode.

    In this mode Alembic does not create a database connection.
    SQL statements are generated using only the configured URL.
    """

    url = config.get_main_option("sqlalchemy.url")

    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={
            "paramstyle": "named",
        },
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """
    Run migrations in 'online' mode.

    In this mode Alembic creates a SQLAlchemy engine
    and connects directly to PostgreSQL.
    """

    connectable = engine_from_config(
        config.get_section(
            config.config_ini_section,
        ),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
