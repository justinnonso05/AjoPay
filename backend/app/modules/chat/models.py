from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import String, Boolean, DateTime
from app.common.models import Base, UUIDMixin, TimestampMixin
from sqlalchemy import ForeignKey
from datetime import datetime

class ChatMessage(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "chat_messages"

    group_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    # nullable=True for system messages that have no sender
    sender_id: Mapped[str] = mapped_column(String, nullable=True) 
    message: Mapped[str] = mapped_column(String, nullable=False)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_edited: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
