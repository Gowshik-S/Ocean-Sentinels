"""
WebSocket router for real-time updates
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import List, Dict
import json
import asyncio
from datetime import datetime

from app.routers.auth import get_current_user
from app.models.user import User

router = APIRouter()

class ConnectionManager:
    """Manages WebSocket connections"""
    
    def __init__(self):
        # Store connections by user role and user ID
        self.active_connections: Dict[str, List[WebSocket]] = {
            "public": [],
            "admin": [],
            "authority": []
        }
        self.user_connections: Dict[int, WebSocket] = {}
    
    async def connect(self, websocket: WebSocket, user: User):
        """Accept a WebSocket connection"""
        await websocket.accept()
        
        # Store connection by role
        if user.role in self.active_connections:
            self.active_connections[user.role].append(websocket)
        
        # Store connection by user ID
        self.user_connections[user.id] = websocket
        
        # Send welcome message
        await self.send_personal_message({
            "type": "connection_established",
            "message": f"Connected as {user.role}",
            "timestamp": datetime.utcnow().isoformat()
        }, websocket)
    
    def disconnect(self, websocket: WebSocket, user: User):
        """Remove a WebSocket connection"""
        if user.role in self.active_connections:
            if websocket in self.active_connections[user.role]:
                self.active_connections[user.role].remove(websocket)
        
        if user.id in self.user_connections:
            del self.user_connections[user.id]
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        """Send message to a specific WebSocket"""
        try:
            await websocket.send_text(json.dumps(message))
        except:
            pass  # Connection might be closed
    
    async def broadcast_to_role(self, message: dict, role: str):
        """Broadcast message to all connections of a specific role"""
        if role in self.active_connections:
            for connection in self.active_connections[role]:
                try:
                    await connection.send_text(json.dumps(message))
                except:
                    # Remove dead connections
                    self.active_connections[role].remove(connection)
    
    async def broadcast_to_all(self, message: dict):
        """Broadcast message to all active connections"""
        for role_connections in self.active_connections.values():
            for connection in role_connections:
                try:
                    await connection.send_text(json.dumps(message))
                except:
                    pass  # Skip dead connections

# Global connection manager
manager = ConnectionManager()

@router.websocket("/incidents")
async def websocket_incidents(websocket: WebSocket):
    """WebSocket endpoint for real-time incident updates"""
    
    try:
        # Accept connection first
        await websocket.accept()
        print(f"WebSocket connection accepted from {websocket.client}")
        
        # Send initial connection message
        await websocket.send_text(json.dumps({
            "type": "connection_established",
            "message": "Connected to Ocean Hazard incident updates",
            "timestamp": datetime.utcnow().isoformat()
        }))
        
        # For demo purposes, we'll allow connections without strict auth
        # In production, you would validate JWT tokens here
        user_role = "public"  # Default role
        
        # Keep connection alive and handle incoming messages
        while True:
            try:
                # Wait for messages from client
                data = await websocket.receive_text()
                message = json.loads(data)
                
                # Handle different message types
                if message.get("type") == "ping":
                    await websocket.send_text(json.dumps({
                        "type": "pong",
                        "timestamp": datetime.utcnow().isoformat()
                    }))
                elif message.get("type") == "auth":
                    # Handle authentication
                    token = message.get("token")
                    if token:
                        # In production, validate the JWT token here
                        await websocket.send_text(json.dumps({
                            "type": "auth_success",
                            "message": "Authentication successful",
                            "timestamp": datetime.utcnow().isoformat()
                        }))
                        user_role = "authenticated"
                    else:
                        await websocket.send_text(json.dumps({
                            "type": "auth_failed",
                            "message": "Authentication failed",
                            "timestamp": datetime.utcnow().isoformat()
                        }))
                elif message.get("type") == "subscribe":
                    # Handle subscription to specific incident types
                    await websocket.send_text(json.dumps({
                        "type": "subscription_confirmed",
                        "message": f"Subscribed to incident updates as {user_role}",
                        "timestamp": datetime.utcnow().isoformat()
                    }))
                
            except WebSocketDisconnect:
                print("WebSocket client disconnected")
                break
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format",
                    "timestamp": datetime.utcnow().isoformat()
                }))
            except Exception as e:
                print(f"WebSocket message error: {e}")
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": f"Message processing error: {str(e)}",
                    "timestamp": datetime.utcnow().isoformat()
                }))
    
    except WebSocketDisconnect:
        print("WebSocket disconnected during setup")
    except Exception as e:
        print(f"WebSocket setup error: {e}")
        try:
            await websocket.close()
        except:
            pass

# Utility functions for sending real-time updates
async def send_incident_update(incident_data: dict, user_role: str = None):
    """Send incident update to relevant users"""
    message = {
        "type": "incident_update",
        "data": incident_data,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    if user_role:
        await manager.broadcast_to_role(message, user_role)
    else:
        await manager.broadcast_to_all(message)

async def send_new_incident_alert(incident_data: dict):
    """Send new incident alert to admin/authority users"""
    message = {
        "type": "new_incident",
        "data": incident_data,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    # Send to admin and authority users
    await manager.broadcast_to_role(message, "admin")
    await manager.broadcast_to_role(message, "authority")

async def send_incident_status_update(incident_data: dict, reporter_id: int):
    """Send status update to incident reporter"""
    message = {
        "type": "status_update",
        "data": incident_data,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    # Send to specific user if connected
    if reporter_id in manager.user_connections:
        await manager.send_personal_message(message, manager.user_connections[reporter_id])



