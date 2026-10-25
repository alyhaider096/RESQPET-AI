"""Organization-scoped WebSocket manager."""

from collections import defaultdict

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self.connections: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(self, organization_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self.connections[organization_id].add(websocket)

    def disconnect(self, organization_id: str, websocket: WebSocket) -> None:
        self.connections[organization_id].discard(websocket)

    async def broadcast(self, organization_id: str, event: dict) -> None:
        stale: list[WebSocket] = []
        for websocket in tuple(self.connections[organization_id]):
            try:
                await websocket.send_json(event)
            except Exception:
                stale.append(websocket)
        for websocket in stale:
            self.disconnect(organization_id, websocket)


manager = ConnectionManager()
