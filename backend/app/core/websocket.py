import json
import logging
from typing import Dict, List, Set
from fastapi import WebSocket

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # Maps group_id to a set of active WebSockets
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, group_id: str):
        await websocket.accept()
        if group_id not in self.active_connections:
            self.active_connections[group_id] = set()
        self.active_connections[group_id].add(websocket)
        logger.debug(f"Client connected to group {group_id}. Total connections: {len(self.active_connections[group_id])}")

    def disconnect(self, websocket: WebSocket, group_id: str):
        if group_id in self.active_connections:
            if websocket in self.active_connections[group_id]:
                self.active_connections[group_id].remove(websocket)
                logger.debug(f"Client disconnected from group {group_id}. Total connections: {len(self.active_connections[group_id])}")
            if not self.active_connections[group_id]:
                del self.active_connections[group_id]

    async def broadcast(self, group_id: str, message: dict):
        if group_id in self.active_connections:
            # Convert dictionary to JSON string to ensure proper encoding,
            # but FastAPI's send_json also handles dicts. We will use send_json.
            disconnected_sockets = set()
            for connection in self.active_connections[group_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending message to websocket in group {group_id}: {e}")
                    disconnected_sockets.add(connection)
            
            # Clean up dead connections
            for dead_conn in disconnected_sockets:
                self.disconnect(dead_conn, group_id)

manager = ConnectionManager()
