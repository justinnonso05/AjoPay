from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any

from app.core.database import get_db
from app.core.security import get_current_user
from app.common.schemas import BaseResponse
from app.modules.user.models import User
from .schemas import UserResponse, SetPayoutBankRequest, MockKycRequest, UserSearchResponse
from .service import request_bank_change_otp, set_payout_bank, get_banks_list, mock_kyc_and_create_wallet
from sqlalchemy import select

router = APIRouter(prefix="/users", tags=["Users"])

@router.get(
    "/search",
    response_model=BaseResponse[UserSearchResponse],
    summary="Search for a user by email or username",
)
async def search_user(
    q: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Search for a user by exact email or username.
    Returns their profile and risk score, so an admin can view details before sending an invite.
    """
    result = await db.execute(
        select(User).where((User.email == q) | (User.username == q))
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
        
    return BaseResponse(
        success=True,
        message="User found",
        data=user
    )



@router.post(
    "/me/kyc/mock-verify",
    response_model=BaseResponse[UserResponse],
    summary="Mock KYC verification and Wallet Creation",
)
async def verify_kyc(
    data: MockKycRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Step 2 of Onboarding: Verifies the user's BVN (mock) and generates 
    their Personal Reserved Account on Monnify.
    Updates the user's kyc_status and has_wallet flags.
    """
    updated_user = await mock_kyc_and_create_wallet(current_user, data.bvn, db)
    return BaseResponse(
        success=True,
        message="KYC verified and personal wallet created successfully",
        data=UserResponse.from_orm_with_pin(updated_user)
    )

@router.get(
    "/me",
    response_model=BaseResponse[UserResponse],
    summary="Get current user profile",
)
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Returns the authenticated user's full profile including:
    - Wallet balance
    - Personal reserved account (for topping up wallet)
    - Payout bank details
    - Whether a transaction PIN is set
    """
    return BaseResponse(
        success=True,
        message="Profile fetched successfully",
        data=UserResponse.from_orm_with_pin(current_user)
    )


@router.post(
    "/me/payout-bank/request-otp",
    response_model=BaseResponse[None],
    summary="Step 1: Request OTP to change payout bank",
)
async def request_payout_bank_otp(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Sends a 6-digit OTP to the user's registered email.
    Required before updating the payout bank account.

    OTP is used (not PIN) because the payout bank determines where real money
    eventually lands — a high-consequence action requiring independent channel proof.
    """
    await request_bank_change_otp(current_user, db)
    return BaseResponse(
        success=True,
        message=f"Verification code sent to {current_user.email}",
        data=None
    )


@router.post(
    "/me/payout-bank",
    response_model=BaseResponse[UserResponse],
    summary="Step 2: Set and validate payout bank account (OTP required)",
)
async def update_payout_bank(
    data: SetPayoutBankRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Verifies the OTP, calls Monnify Name Enquiry to validate the account,
    then saves the resolved account details.

    The user sees the resolved account name (e.g. 'CHIDI OKAFOR') before
    this endpoint is called — the frontend should run a Name Enquiry preview
    first via GET /users/banks/validate, then submit with the OTP to confirm.
    """
    updated_user = await set_payout_bank(current_user, data, db)
    return BaseResponse(
        success=True,
        message=f"Payout account set to {updated_user.payout_account_name}",
        data=UserResponse.from_orm_with_pin(updated_user)
    )


from app.services.monnify import monnify_client

@router.get(
    "/banks/validate",
    response_model=BaseResponse[Any],
    summary="Validate bank account details (Name Enquiry)",
)
async def validate_bank_account(
    account_number: str,
    bank_code: str,
):
    """
    Calls Monnify Name Enquiry to resolve the account name.
    The frontend calls this *before* submitting the OTP to confirm.
    """
    try:
        enquiry = await monnify_client.validate_bank_account(
            account_number=account_number,
            bank_code=bank_code,
        )
        return BaseResponse(
            success=True,
            message="Account validated successfully",
            data=enquiry
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Bank account validation failed: {str(e)}"
        )


@router.get(
    "/banks",
    response_model=BaseResponse[Any],
    summary="Get list of supported banks",
)
async def list_banks():
    """
    Returns Monnify's full list of banks for the bank picker UI.
    No authentication required.
    """
    banks = await get_banks_list()
    return BaseResponse(
        success=True,
        message="Banks fetched successfully",
        data=banks
    )

from app.modules.transaction.models import WalletLedgerEntry
from .schemas import WalletLedgerEntryResponse
from sqlalchemy import select

@router.get(
    "/me/wallet/transactions",
    response_model=BaseResponse[list[WalletLedgerEntryResponse]],
    summary="Get user's wallet transaction history",
)
async def get_wallet_transactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(WalletLedgerEntry)
        .where(WalletLedgerEntry.user_id == current_user.id)
        .order_by(WalletLedgerEntry.created_at.desc())
    )
    transactions = result.scalars().all()
    return BaseResponse(
        success=True,
        message="Wallet transactions fetched successfully",
        data=transactions
    )

from .schemas import WithdrawRequest
from .service import withdraw_from_wallet

@router.post(
    "/me/wallet/withdraw",
    response_model=BaseResponse[WalletLedgerEntryResponse],
    summary="Withdraw from wallet to payout bank",
)
async def withdraw_funds(
    data: WithdrawRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Withdraw money from the personal wallet to the user's validated external payout bank.
    Requires the user's Transaction PIN.
    """
    entry = await withdraw_from_wallet(current_user, data.amount, data.pin, db)
    return BaseResponse(
        success=True,
        message=f"Withdrawal of NGN {data.amount} initiated successfully",
        data=entry
    )

from app.modules.membership.models import Membership
from app.modules.group.models import Group
from .schemas import UserGroupMembershipResponse

@router.get(
    "/me/groups",
    response_model=BaseResponse[list[UserGroupMembershipResponse]],
    summary="Get user's groups",
)
async def get_my_groups(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get all groups the current user is a member of, along with their role and group details.
    """
    result = await db.execute(
        select(Membership, Group)
        .join(Group, Membership.group_id == Group.id)
        .where(Membership.user_id == current_user.id)
    )
    
    records = result.all()
    response_data = []
    
    for mem, grp in records:
        response_data.append(
            UserGroupMembershipResponse(
                membership_id=mem.id,
                is_admin=mem.is_admin,
                membership_status=mem.status,
                joined_at=mem.created_at,
                group_id=grp.id,
                group_name=grp.name,
                contribution_amount=grp.contribution_amount,
                cycle_frequency=grp.cycle_frequency,
                group_status=grp.status,
                pool_balance=grp.pool_balance,
            )
        )
        
    return BaseResponse(
        success=True,
        message="User groups fetched successfully",
        data=response_data
    )
