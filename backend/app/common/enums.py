from enum import Enum

class GroupStatus(str, Enum):
    GATHERING = "gathering"
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"

class CycleFrequency(str, Enum):
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"

class ShortfallPolicy(str, Enum):
    HOLD = "hold"
    PARTIAL = "partial"
    ADMIN_DECIDES = "admin_decides"

class MembershipStatus(str, Enum):
    INVITED = "invited"
    PENDING_APPROVAL = "pending_approval"
    ACTIVE = "active"
    REMOVED = "removed"

class GroupInviteStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"

class KYCStatus(str, Enum):
    PENDING = "pending"
    MOCKED_VERIFIED = "mocked_verified"
    MOCKED_FAILED = "mocked_failed"

class ContributionStatus(str, Enum):
    CONFIRMED = "confirmed"

class PayoutStatus(str, Enum):
    PENDING_AUTHORIZATION = "pending_authorization"
    SUCCESS = "success"
    FAILED = "failed"

class WalletLedgerEntryType(str, Enum):
    TOPUP = "topup"
    PAY_GROUP = "pay_group"
    PAYOUT_RECEIVED = "payout_received"
    RECEIVE_DELEGATION = "receive_delegation"
    WITHDRAWAL = "withdrawal"
    WALLET_TRANSFER_SENT = "wallet_transfer_sent"
    WALLET_TRANSFER_RECEIVED = "wallet_transfer_received"
    CORRECTION = "correction"

class GroupLedgerEntryType(str, Enum):
    CONTRIBUTION_WALLET = "contribution_wallet"
    CONTRIBUTION_DIRECT = "contribution_direct"
    PAYOUT = "payout"
    CORRECTION = "correction"

class SwapRequestStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
