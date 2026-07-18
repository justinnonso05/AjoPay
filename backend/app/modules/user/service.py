from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.user.models import User
from app.services.monnify import monnify_client
from app.modules.otp.service import request_otp, verify_otp
from .schemas import SetPayoutBankRequest


from app.core.config import settings

async def get_user_profile(user: User) -> User:
    """Return the currently authenticated user's profile."""
    return user

async def mock_kyc_and_create_wallet(user: User, bvn: str, db: AsyncSession) -> User:
    """
    Simulates KYC by accepting a mock BVN, then calls Monnify to create 
    the Personal Reserved Account using the preferred bank from env.
    Updates the user's kyc_status and has_wallet flags.
    """
    if user.has_wallet:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Wallet already created"
        )
        
    full_name = f"{user.first_name} {user.last_name}"
    account_reference = f"ajopay-wallet-{user.id}"
    preferred_bank_code = settings.MONNIFY_DEFAULT_PREFERRED_BANK
    preferred_banks = [preferred_bank_code] if preferred_bank_code else None
    
    try:
        monnify_response = await monnify_client.create_reserved_account(
            account_reference=account_reference,
            account_name=f"AjoPay - {user.first_name}",
            customer_email=user.email,
            customer_name=full_name,
            bvn=bvn,
        )
        
        # Monnify returns an accounts list. We find the preferred one if specified,
        # otherwise we take the first one.
        accounts = monnify_response.get("accounts", [])
        if not accounts:
            raise ValueError("Monnify did not return any accounts")
            
        selected_account = accounts[0]
        preferred_bank_code = settings.MONNIFY_DEFAULT_PREFERRED_BANK
        
        if preferred_bank_code:
            for acc in accounts:
                if acc.get("bankCode") == preferred_bank_code:
                    selected_account = acc
                    break
                    
        user.personal_reserved_account_number = selected_account.get("accountNumber")
        user.personal_reserved_account_bank = selected_account.get("bankName")
        user.personal_reserved_account_name = selected_account.get("accountName")
        user.personal_reserved_account_reference = account_reference
        user.kyc_status = True
        user.has_wallet = True
        
        db.add(user)
        
        # Add Notification and Email
        from app.modules.notification.models import Notification
        from app.services.email import send_kyc_completed_email
        import asyncio
        
        notif = Notification(
            user_id=user.id,
            title="KYC Completed",
            message="Your Personal Reserved Account is ready to receive funds.",
            type="kyc_completed"
        )
        db.add(notif)
        
        await db.commit()
        await db.refresh(user)
        
        asyncio.create_task(send_kyc_completed_email(user.email, user.first_name))
        
        return user
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create wallet: {str(e)}"
        )


async def request_bank_change_otp(user: User, db: AsyncSession) -> None:
    """
    Step 1 of payout bank change:
    Send an OTP to the user's registered email.
    OTP is required here (not PIN) because the payout bank determines where real
    money lands — a high-consequence, infrequent action that warrants channel proof.
    """
    await request_otp(user=user, purpose="bank_change", db=db)


async def set_payout_bank(
    user: User,
    data: SetPayoutBankRequest,
    db: AsyncSession,
) -> User:
    """
    Step 2 of payout bank change:
    1. Verify the OTP from email
    2. Validate the bank account via Monnify Name Enquiry
    3. Save validated details

    The user sees the resolved account name before confirming — exactly like
    a bank transfer confirmation screen (Kuda, OPay pattern).
    """
    # 1. Verify OTP
    await verify_otp(user=user, purpose="bank_change", code=data.otp_code, db=db)

    # 2. Validate bank account via Monnify Name Enquiry
    try:
        enquiry = await monnify_client.validate_bank_account(
            account_number=data.bank_account_number,
            bank_code=data.bank_code,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Bank account validation failed: {str(e)}"
        )

    # 3. Save validated payout bank details
    user.payout_bank_account_number = enquiry["accountNumber"]
    user.payout_bank_code = enquiry["bankCode"]
    user.payout_account_name = enquiry["accountName"]

    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_banks_list() -> list:
    """Return Monnify's list of banks for the frontend bank picker."""
    try:
        return await monnify_client.get_banks()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Could not fetch banks list: {str(e)}"
        )

from app.core.security import verify_password
from app.modules.transaction.models import WalletLedgerEntry
from app.common.enums import WalletLedgerEntryType

async def withdraw_from_wallet(user: User, amount: float, pin: str, db: AsyncSession) -> WalletLedgerEntry:
    # 1. Verify PIN
    if not user.pin_hash:
        raise HTTPException(status_code=400, detail="Transaction PIN not set")
    if not verify_password(pin, user.pin_hash):
        raise HTTPException(status_code=400, detail="Invalid Transaction PIN")
        
    # 2. Check balance
    if float(user.wallet_balance) < amount:
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")
        
    # 3. Check payout bank exists
    if not user.payout_bank_account_number or not user.payout_bank_code:
        raise HTTPException(status_code=400, detail="Payout bank account not set. Please set it first.")
        
    # 4. Initiate Monnify Transfer
    import time
    reference = f"ajopay-wd-{user.id}-{int(time.time())}"
    try:
        monnify_response = await monnify_client.initiate_transfer(
            reference=reference,
            amount=amount,
            narration=f"AjoPay Withdrawal for {user.first_name}",
            destination_bank_code=user.payout_bank_code,
            destination_account_number=user.payout_bank_account_number,
            destination_account_name=user.payout_account_name,
            # We use default sandbox source or the user's reserved account if we were using a real wallet source
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to initiate Monnify transfer: {str(e)}")
        
    # 5. Record Ledger Entry
    entry = WalletLedgerEntry(
        user_id=user.id,
        type=WalletLedgerEntryType.WITHDRAWAL,
        amount=-amount,
        monnify_transaction_reference=monnify_response.get("reference"),
        narration="Wallet Withdrawal to Bank"
    )
    db.add(entry)
    
    # 6. Update user balance
    user.wallet_balance = float(user.wallet_balance) - amount
    db.add(user)
    
    await db.commit()
    await db.refresh(entry)
    return entry
