import asyncio
import json
import uuid
from datetime import datetime
from typing import Dict, List, Callable, Any, Optional
from dataclasses import dataclass, asdict
import redis.asyncio as redis
from sqlalchemy import select, insert
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import settings
from core.database import AsyncSessionLocal
from models.events import Event as EventModel


@dataclass
class Event:
    """Event data structure"""
    id: str
    type: str
    data: Dict[str, Any]
    timestamp: datetime
    user_id: Optional[str] = None
    correlation_id: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.type,
            "data": self.data,
            "timestamp": self.timestamp.isoformat(),
            "user_id": self.user_id,
            "correlation_id": self.correlation_id
        }


class EventBus:
    """In-memory event bus with Redis pub/sub support"""
    
    def __init__(self):
        self.subscribers: Dict[str, List[Callable]] = {}
        self.redis_client = None
        self._setup_redis()
    
    def _setup_redis(self):
        """Setup Redis connection for pub/sub"""
        try:
            self.redis_client = redis.from_url(settings.redis_url)
        except Exception as e:
            print(f"Redis connection failed: {e}")
    
    def subscribe(self, event_type: str, handler: Callable[[Event], None]):
        """Subscribe to events of a specific type"""
        if event_type not in self.subscribers:
            self.subscribers[event_type] = []
        self.subscribers[event_type].append(handler)
    
    async def publish(self, event: Event):
        """Publish an event to all subscribers"""
        # Local subscribers
        await self._notify_local_subscribers(event)
        
        # Redis pub/sub for distributed systems
        if self.redis_client:
            try:
                await self.redis_client.publish(
                    f"events:{event.type}",
                    json.dumps(event.to_dict())
                )
            except Exception as e:
                print(f"Redis publish failed: {e}")
    
    async def _notify_local_subscribers(self, event: Event):
        """Notify local subscribers"""
        # Notify specific event type subscribers
        if event.type in self.subscribers:
            for handler in self.subscribers[event.type]:
                try:
                    if asyncio.iscoroutinefunction(handler):
                        await handler(event)
                    else:
                        handler(event)
                except Exception as e:
                    print(f"Event handler error: {e}")
        
        # Notify wildcard subscribers
        if "*" in self.subscribers:
            for handler in self.subscribers["*"]:
                try:
                    if asyncio.iscoroutinefunction(handler):
                        await handler(event)
                    else:
                        handler(event)
                except Exception as e:
                    print(f"Wildcard event handler error: {e}")
    
    async def close(self):
        """Close Redis connection"""
        if self.redis_client:
            await self.redis_client.close()


class EventStore:
    """Event store for persisting events"""
    
    async def save_event(self, event: Event):
        """Save event to database"""
        async with AsyncSessionLocal() as session:
            try:
                event_model = EventModel(
                    id=event.id,
                    type=event.type,
                    data=event.data,
                    timestamp=event.timestamp,
                    user_id=event.user_id,
                    correlation_id=event.correlation_id
                )
                session.add(event_model)
                await session.commit()
            except Exception as e:
                await session.rollback()
                raise e
    
    async def get_events(
        self,
        event_type: Optional[str] = None,
        user_id: Optional[str] = None,
        limit: int = 100
    ) -> List[Event]:
        """Retrieve events from database"""
        async with AsyncSessionLocal() as session:
            query = select(EventModel)
            
            if event_type:
                query = query.where(EventModel.type == event_type)
            if user_id:
                query = query.where(EventModel.user_id == user_id)
            
            query = query.order_by(EventModel.timestamp.desc()).limit(limit)
            
            result = await session.execute(query)
            events = result.scalars().all()
            
            return [
                Event(
                    id=e.id,
                    type=e.type,
                    data=e.data,
                    timestamp=e.timestamp,
                    user_id=e.user_id,
                    correlation_id=e.correlation_id
                )
                for e in events
            ]


def create_event(
    event_type: str,
    data: Dict[str, Any],
    user_id: Optional[str] = None,
    correlation_id: Optional[str] = None
) -> Event:
    """Create a new event"""
    return Event(
        id=str(uuid.uuid4()),
        type=event_type,
        data=data,
        timestamp=datetime.utcnow(),
        user_id=user_id,
        correlation_id=correlation_id
    )