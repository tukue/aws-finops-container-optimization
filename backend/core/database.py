import redis.asyncio as redis
from core.config import settings
from typing import AsyncGenerator


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