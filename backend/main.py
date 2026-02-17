from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import json
import asyncio
from typing import List

from core.config import settings
from core.database import engine, Base
from core.events import EventBus, EventStore
from core.websocket import ConnectionManager
from api.routes import events, users, tasks
from models.events import Event


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Initialize event bus and store
    app.state.event_bus = EventBus()
    app.state.event_store = EventStore()
    app.state.connection_manager = ConnectionManager()
    
    yield
    
    # Shutdown
    await app.state.event_bus.close()


app = FastAPI(
    title="Event-Driven API",
    description="FastAPI backend with event-driven architecture",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(events.router, prefix="/api/events", tags=["events"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(tasks.router, prefix="/api/tasks", tags=["tasks"])


@app.get("/")
async def root():
    return {"message": "Event-Driven API is running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await app.state.connection_manager.connect(websocket)
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            if message.get("type") == "subscribe":
                # Subscribe to specific event types
                event_types = message.get("event_types", [])
                await app.state.connection_manager.subscribe(websocket, event_types)
            
            elif message.get("type") == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
                
    except WebSocketDisconnect:
        app.state.connection_manager.disconnect(websocket)


# Event handlers
@app.on_event("startup")
async def setup_event_handlers():
    """Setup event handlers for real-time notifications"""
    
    async def broadcast_event(event: Event):
        """Broadcast events to connected WebSocket clients"""
        await app.state.connection_manager.broadcast_event(event)
    
    # Subscribe to all events for broadcasting
    app.state.event_bus.subscribe("*", broadcast_event)