from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ChatMessageCreate(BaseModel):
    message: Optional[str] = None

class ChatMessageResponse(BaseModel):
    id: str
    group_id: str
    sender_id: Optional[str]
    message: Optional[str] = None
    image_url: Optional[str] = None
    is_system: bool
    is_edited: bool = False
    is_deleted: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}
