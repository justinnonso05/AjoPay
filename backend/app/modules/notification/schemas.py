from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    title: str
    message: str
    type: str
    is_read: bool
    action_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class MarkReadRequest(BaseModel):
    notification_ids: Optional[list[str]] = None # If None, mark all as read
