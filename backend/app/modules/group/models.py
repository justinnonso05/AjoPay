from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import String, Integer, Float, DateTime, Time
from datetime import datetime, time
from typing import Optional
from app.common.models import Base, UUIDMixin, TimestampMixin

class Group(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "groups"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    admin_user_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    
    contribution_amount: Mapped[float] = mapped_column(Float, nullable=False)
    
    cycle_frequency: Mapped[str] = mapped_column(String(50), nullable=False)
    payout_day_of_week: Mapped[int] = mapped_column(Integer, nullable=True)
    payout_day_of_month: Mapped[int] = mapped_column(Integer, nullable=True)
    payout_month: Mapped[int] = mapped_column(Integer, nullable=True)
    
    quorum_percent: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    
    requires_approval_for_delegate: Mapped[bool] = mapped_column(default=True, nullable=False)
    requires_approval_for_swap: Mapped[bool] = mapped_column(default=True, nullable=False)
    
    invite_code: Mapped[str] = mapped_column(String(10), unique=True, nullable=True, index=True)
    invite_code_active: Mapped[bool] = mapped_column(default=True, nullable=False)
    
    pool_balance: Mapped[float] = mapped_column(Float, default=0.00, nullable=False)
    member_cap: Mapped[int] = mapped_column(Integer, nullable=True)
    
    rotation_order: Mapped[str] = mapped_column(String, nullable=True) # JSON serialized list
    
    current_rotation_index: Mapped[int] = mapped_column(Integer, default=0)
    current_cycle_number: Mapped[int] = mapped_column(Integer, default=1)
    
    status: Mapped[str] = mapped_column(String(50), nullable=False) # Enum as string
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    next_payout_date: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    payout_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)


class ReminderTracking(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "reminder_tracking"

    group_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    cycle_number: Mapped[int] = mapped_column(Integer, nullable=False)
    reminder_type: Mapped[str] = mapped_column(String(50), nullable=False) # e.g. "T-2", "daily"
    last_sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
