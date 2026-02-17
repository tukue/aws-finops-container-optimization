import redis.asyncio as redis
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from core.config import settings
from typing import AsyncGenerator

# SQLAlchemy async engine and session
DATABASE_URL = "sqlite+aiosqlite:///./events.db"  # Default SQLite for demo
engine = create_async_engine(DATABASE_URL, echo=settings.debug)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
Base = declarative_base()


class RedisDatabase:
    """Redis database connection manager"""
    
    def __init__(self):
        self.redis_client = None
    
    async def connect(self):
        """Connect to Redis"""
        self.redis_client = redis.from_url(settings.redis_url, decode_responses=True)
        return self.redis_client
    
    async def disconnect(self):
        """Disconnect from Redis"""
        if self.redis_client:
            await self.redis_client.close()
    
    async def get_client(self):
        """Get Redis client"""
        if not self.redis_client:
            await self.connect()
        return self.redis_client


# Global Redis instance
redis_db = RedisDatabase()


async def get_redis() -> AsyncGenerator[redis.Redis, None]:
    """Dependency to get Redis client"""
    client = await redis_db.get_client()
    try:
        yield client
    finally:
        # Connection is managed by the global instance
        pass