"""
Database configuration and session management
"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.core.config import settings
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse

# Create async engine (supports both PostgreSQL and SQLite)
database_url = settings.DATABASE_URL
connect_args = {}

if database_url.startswith("postgresql://"):
    # Convert PostgreSQL URL to asyncpg format
    database_url = database_url.replace("postgresql://", "postgresql+asyncpg://")
    
    # Parse URL to extract SSL parameters
    parsed = urlparse(database_url)
    query_params = parse_qs(parsed.query)
    
    # Extract SSL parameters and build connect_args
    if 'sslmode' in query_params:
        ssl_mode = query_params.pop('sslmode')[0]
        if ssl_mode == 'require':
            connect_args['ssl'] = 'require'
    
    # Remove channel_binding from URL (asyncpg doesn't support it as URL param)
    query_params.pop('channel_binding', None)
    
    # Rebuild URL without SSL parameters
    new_query = urlencode(query_params, doseq=True)
    database_url = urlunparse((
        parsed.scheme,
        parsed.netloc,
        parsed.path,
        parsed.params,
        new_query,
        parsed.fragment
    ))

engine = create_async_engine(
    database_url,
    echo=settings.DEBUG,
    future=True,
    connect_args=connect_args
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Create declarative base
Base = declarative_base()

# Dependency to get database session
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

