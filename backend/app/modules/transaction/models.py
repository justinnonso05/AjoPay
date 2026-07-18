from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import String, Numeric
from sqlalchemy import ForeignKey
from app.common.models import Base, UUIDMixin, TimestampMixin


class WalletLedgerEntry(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "wallet_ledger_entries"

    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(50), nullable=False) # WalletLedgerEntryType
    amount: Mapped[float] = mapped_column(Numeric(precision=18, scale=2), nullable=False)
    
    related_group_id: Mapped[str] = mapped_column(String, ForeignKey("groups.id", ondelete="SET NULL"), nullable=True, index=True)
    related_contribution_id: Mapped[str] = mapped_column(String, nullable=True) # ID of corresponding GroupLedgerEntry
    
    monnify_transaction_reference: Mapped[str] = mapped_column(String(255), unique=True, nullable=True, index=True)
    monnify_payment_reference: Mapped[str] = mapped_column(String(255), nullable=True)
    
    narration: Mapped[str] = mapped_column(String(500), nullable=True)

class GroupLedgerEntry(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "group_ledger_entries"

    group_id: Mapped[str] = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(50), nullable=False) # GroupLedgerEntryType
    amount: Mapped[float] = mapped_column(Numeric(precision=18, scale=2), nullable=False)
    
    member_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    cycle_number: Mapped[int] = mapped_column(nullable=False)
    
    monnify_transaction_reference: Mapped[str] = mapped_column(String(255), unique=True, nullable=True, index=True)
    monnify_payment_reference: Mapped[str] = mapped_column(String(255), nullable=True)
    narration: Mapped[str] = mapped_column(String(500), nullable=True)
