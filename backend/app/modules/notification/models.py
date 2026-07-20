from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import String, Boolean
from sqlalchemy import ForeignKey
from app.common.models import Base, UUIDMixin, TimestampMixin

class Notification(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "notifications"

    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(String(1000), nullable=False)
    
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(50), nullable=False) # payout_received, swap_request, delegation_approved, etc.
    action_id: Mapped[str] = mapped_column(String, nullable=True) # ID of the related swap, delegation, or group

