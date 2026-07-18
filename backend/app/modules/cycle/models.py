from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import String, Integer, Boolean
from sqlalchemy import ForeignKey
from typing import Optional
from app.common.models import Base, UUIDMixin, TimestampMixin

class CycleAssignment(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "cycle_assignments"

    group_id: Mapped[str] = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    cycle_number: Mapped[int] = mapped_column(Integer, nullable=False)
    
    assigned_member_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    actual_recipient_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    delegation_id: Mapped[Optional[str]] = mapped_column(String, nullable=True) # Will not use strict foreign key to avoid circular import issues in alembic or if delegation_requests is dropped
    
    status: Mapped[str] = mapped_column(String(50), default="pending", nullable=False) # pending, ready, paid, failed

class DelegationRequest(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "delegation_requests"

    group_id: Mapped[str] = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    cycle_number: Mapped[int] = mapped_column(Integer, nullable=False)
    
    from_member_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    to_member_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    status: Mapped[str] = mapped_column(String(50), default="pending_admin_approval", nullable=False)

class SwapRequest(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "swap_requests"

    group_id: Mapped[str] = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    
    initiator_member_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    target_member_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    initiator_cycle_number: Mapped[int] = mapped_column(Integer, nullable=False)
    target_cycle_number: Mapped[int] = mapped_column(Integer, nullable=False)
    
    status: Mapped[str] = mapped_column(String(50), default="pending_counterpart", nullable=False) # pending_counterpart, pending_admin_approval, accepted, rejected
