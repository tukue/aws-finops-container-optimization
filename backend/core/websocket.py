import json
from typing import List, Dict, Set
from fastapi import WebSocket
from core.events import Event


class ConnectionManager:
    """Manages WebSocket connections and event subscriptions"""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.subscriptions: Dict[WebSocket, Set[str]] = {}
    
    async def connect(self, websocket: WebSocket):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        self.active_connections.append(websocket)
        self.subscriptions[websocket] = set()
    
    def disconnect(self, websocket: WebSocket):
        """Remove a WebSocket connection"""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if websocket in self.subscriptions:
            del self.subscriptions[websocket]
    
    async def subscribe(self, websocket: WebSocket, event_types: List[str]):
        """Subscribe a connection to specific event types"""
        if websocket in self.subscriptions:
            self.subscriptions[websocket].update(event_types)
            await websocket.send_text(json.dumps({
                "type": "subscription_confirmed",
                "event_types": list(self.subscriptions[websocket])
            }))
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        """Send a message to a specific connection"""
        try:
            await websocket.send_text(message)
        except Exception:
            self.disconnect(websocket)
    
    async def broadcast(self, message: str):
        """Broadcast a message to all connections"""
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                disconnected.append(connection)
        
        # Clean up disconnected connections
        for connection in disconnected:
            self.disconnect(connection)
    
    async def broadcast_event(self, event: Event):
        """Broadcast an event to subscribed connections"""
        event_data = json.dumps({
            "type": "event",
            "event": event.to_dict()
        })
        
        disconnected = []
        for connection in self.active_connections:
            # Check if connection is subscribed to this event type
            subscriptions = self.subscriptions.get(connection, set())
            if not subscriptions or event.type in subscriptions or "*" in subscriptions:
                try:
                    await connection.send_text(event_data)
                except Exception:
                    disconnected.append(connection)
        
        # Clean up disconnected connections
        for connection in disconnected:
            self.disconnect(connection)