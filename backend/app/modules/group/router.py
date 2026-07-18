from fastapi import APIRouter, Depends, HTTPException, status
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.common.schemas import BaseResponse
from app.modules.user.models import User
from app.core.security import get_current_user
from .schemas import GroupResponse, GroupCreate, GroupUpdate, GroupStartRequest, JoinGroupRequest, PayFromWalletRequest, GroupMemberProfileResponse
from .service import create_group_service, join_group_service, update_group_service, start_group_service, pay_group_from_wallet_service, generate_direct_payment_service, get_group_members_service

router = APIRouter(prefix="/groups", tags=["Groups"])

@router.post("/join", response_model=BaseResponse[GroupResponse])
async def join_group(
    data: JoinGroupRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Join a group using a shareable invite code.
    """
    group = await join_group_service(current_user, data.invite_code, db)
    return BaseResponse(
        success=True,
        message="Successfully joined the group",
        data=group
    )

@router.post("/", response_model=BaseResponse[GroupResponse])
async def create_group(
    group: GroupCreate, 
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_group = await create_group_service(current_user, group, db)
    return BaseResponse(
        success=True,
        message="Group created successfully",
        data=new_group
    )

@router.get("/{group_id}", response_model=BaseResponse[GroupResponse])
async def get_group(group_id: str, db: AsyncSession = Depends(get_db)):
    from sqlalchemy import select
    from .models import Group
    
    result = await db.execute(select(Group).where(Group.id == group_id))
    group = result.scalar_one_or_none()
    
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )
        
    return BaseResponse(
        success=True,
        message="Group fetched successfully",
        data=group
    )

@router.patch("/{group_id}", response_model=BaseResponse[GroupResponse])
async def update_group(
    group_id: str,
    data: GroupUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group = await update_group_service(current_user, group_id, data, db)
    return BaseResponse(
        success=True,
        message="Group updated successfully",
        data=group
    )

@router.post("/{group_id}/start", response_model=BaseResponse[GroupResponse])
async def start_group(
    group_id: str,
    data: GroupStartRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group = await start_group_service(current_user, group_id, data, db)
    return BaseResponse(
        success=True,
        message="Group rotation started successfully",
        data=group
    )

from .schemas import GroupInviteCreate, GroupInviteResponse, MembershipResponse
from .service import (
    approve_join_request_service,
    send_targeted_invite_service,
    respond_to_invite_service,
    rotate_invite_code_service
)
from app.modules.membership.models import Membership, GroupInvite
from sqlalchemy import select

@router.get("/{group_id}/members/pending", response_model=BaseResponse[list[GroupMemberProfileResponse]])
async def get_pending_members(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from .service import _verify_admin
    await _verify_admin(current_user.id, group_id, db)
    
    result = await db.execute(
        select(Membership, User).join(User, Membership.user_id == User.id).where(
            Membership.group_id == group_id,
            Membership.status == "pending_approval"
        )
    )
    
    response_data = []
    for mem, usr in result.all():
        response_data.append(
            GroupMemberProfileResponse(
                id=mem.id,
                group_id=mem.group_id,
                user_id=mem.user_id,
                is_admin=mem.is_admin,
                status=mem.status,
                joined_at=mem.created_at,
                first_name=usr.first_name,
                last_name=usr.last_name,
                username=usr.username,
                risk_score=usr.risk_score,
                risk_factors=usr.risk_factors
            )
        )
        
    return BaseResponse(success=True, message="Pending members fetched", data=response_data)

@router.post("/{group_id}/members/{user_id}/approve", response_model=BaseResponse[Any])
async def approve_member(
    group_id: str,
    user_id: str,
    approve: bool = True,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    await approve_join_request_service(current_user, group_id, user_id, approve, db)
    msg = "User approved" if approve else "User rejected"
    return BaseResponse(success=True, message=msg, data=None)

@router.post("/{group_id}/invites", response_model=BaseResponse[GroupInviteResponse])
async def send_invite(
    group_id: str,
    data: GroupInviteCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    invite = await send_targeted_invite_service(current_user, group_id, data.email_or_username, db)
    return BaseResponse(success=True, message="Invite sent", data=invite)

@router.get("/me/invites", response_model=BaseResponse[list[GroupInviteResponse]])
async def get_my_invites(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(GroupInvite).where(
            GroupInvite.invited_user_id == current_user.id,
            GroupInvite.status == "pending"
        )
    )
    invites = result.scalars().all()
    return BaseResponse(success=True, message="Invites fetched", data=invites)

@router.post("/invites/{invite_id}/respond", response_model=BaseResponse[GroupInviteResponse])
async def respond_invite(
    invite_id: str,
    accept: bool = True,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    invite = await respond_to_invite_service(current_user, invite_id, accept, db)
    msg = "Invite accepted" if accept else "Invite rejected"
    return BaseResponse(success=True, message=msg, data=invite)

@router.post("/{group_id}/rotate-code", response_model=BaseResponse[GroupResponse])
async def rotate_code(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group = await rotate_invite_code_service(current_user, group_id, db)
    return BaseResponse(success=True, message="Invite code rotated", data=group)

@router.post("/{group_id}/pay-from-wallet", response_model=BaseResponse[GroupResponse])
async def pay_from_wallet(
    group_id: str,
    data: PayFromWalletRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group = await pay_group_from_wallet_service(current_user, group_id, data.pin, db)
    return BaseResponse(
        success=True,
        message="Contribution paid successfully",
        data=group
    )

@router.post("/{group_id}/generate-direct-payment", response_model=BaseResponse[dict])
async def generate_direct_payment(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    data = await generate_direct_payment_service(current_user, group_id, db)
    return BaseResponse(
        success=True,
        message="Direct payment checkout generated",
        data=data
    )

@router.get("/{group_id}/members", response_model=BaseResponse[list[GroupMemberProfileResponse]])
async def get_group_members(
    group_id: str,
    db: AsyncSession = Depends(get_db)
):
    members = await get_group_members_service(group_id, db)
    return BaseResponse(
        success=True,
        message="Group members retrieved successfully",
        data=members
    )
