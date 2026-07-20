from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.user.models import User
from app.common.schemas import BaseResponse
from app.modules.group.models import Group
from app.modules.cycle.service import evaluate_payout_for_group

router = APIRouter(prefix="/cycles", tags=["Cycle Management"])

@router.post("/admin/trigger-scheduler", response_model=BaseResponse[str])
async def trigger_scheduler(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Manually trigger the payout scheduler for testing/demo purposes.
    Only available to the platform admin (we assume first user or any user for demo).
    """
    groups_res = await db.execute(select(Group))
    groups = groups_res.scalars().all()
    count = 0
    for group in groups:
        try:
            from app.modules.cycle.auto_debit_service import evaluate_and_process_auto_debits
            await evaluate_and_process_auto_debits(db, group)
            await evaluate_payout_for_group(db, group)
            count += 1
        except Exception as e:
            # We don't rollback the whole loop, just continue
            import logging
            logging.error(f"Error manually evaluating payout for group {group.id}: {e}", exc_info=True)
            
    await db.commit()
    
    return BaseResponse(
        success=True,
        message=f"Manual scheduler triggered. Evaluated {count} groups.",
        data="OK"
    )

from .schemas import DelegateRequestPayload, SwapRequestPayload, SwapRespondPayload, DelegationRequestResponse, SwapRequestResponse
from .requests_service import initiate_delegation, initiate_swap, respond_swap

@router.post("/{group_id}/cycles/{cycle_number}/delegate", response_model=BaseResponse[DelegationRequestResponse])
async def delegate_cycle(
    group_id: str,
    cycle_number: int,
    data: DelegateRequestPayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    req = await initiate_delegation(db, group, cycle_number, current_user, data.to_member_id, data.pin)
    return BaseResponse(success=True, message="Delegation initiated", data=req)

@router.post("/{group_id}/swap", response_model=BaseResponse[SwapRequestResponse])
async def swap_cycle(
    group_id: str,
    data: SwapRequestPayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    req = await initiate_swap(db, group, current_user, data.target_member_id, data.target_cycle_number, data.pin)
    return BaseResponse(success=True, message="Swap initiated", data=req)

@router.post("/{group_id}/swaps/{swap_id}/respond", response_model=BaseResponse[SwapRequestResponse])
async def respond_to_swap(
    group_id: str,
    swap_id: str,
    data: SwapRespondPayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    req = await respond_swap(db, group, current_user, swap_id, data.accept, data.pin)
    return BaseResponse(success=True, message="Swap responded to", data=req)

from .schemas import AdminApprovePayload
from .requests_service import approve_swap, approve_delegation

@router.post("/{group_id}/swaps/{swap_id}/approve", response_model=BaseResponse[SwapRequestResponse])
async def admin_approve_swap(
    group_id: str,
    swap_id: str,
    data: AdminApprovePayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    req = await approve_swap(db, group, current_user, swap_id, data.approve, data.reason)
    return BaseResponse(success=True, message="Swap approval processed", data=req)

@router.post("/{group_id}/delegations/{delegation_id}/approve", response_model=BaseResponse[DelegationRequestResponse])
async def admin_approve_delegation(
    group_id: str,
    delegation_id: str,
    data: AdminApprovePayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    req = await approve_delegation(db, group, current_user, delegation_id, data.approve, data.reason)
    return BaseResponse(success=True, message="Delegation approval processed", data=req)

from typing import List
from app.modules.cycle.models import SwapRequest, DelegationRequest

@router.get("/{group_id}/swaps/pending", response_model=BaseResponse[List[SwapRequestResponse]])
async def get_pending_swaps(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    from sqlalchemy import or_, and_
    if current_user.id == group.admin_user_id:
        # Admin sees both swaps waiting for their approval, and swaps targeting them personally
        swaps_res = await db.execute(
            select(SwapRequest).where(
                SwapRequest.group_id == group_id,
                or_(
                    SwapRequest.status == "pending_admin_approval",
                    and_(SwapRequest.status == "pending_counterpart", SwapRequest.target_member_id == current_user.id)
                )
            )
        )
    else:
        # Regular user only sees swaps targeting them
        swaps_res = await db.execute(
            select(SwapRequest).where(
                SwapRequest.group_id == group_id,
                SwapRequest.status == "pending_counterpart",
                SwapRequest.target_member_id == current_user.id
            )
        )
    swaps = swaps_res.scalars().all()
    return BaseResponse(success=True, message="Pending swaps fetched", data=swaps)

@router.get("/{group_id}/delegations/pending", response_model=BaseResponse[List[DelegationRequestResponse]])
async def get_pending_delegations(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    group_res = await db.execute(select(Group).where(Group.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    if current_user.id != group.admin_user_id:
        raise HTTPException(status_code=403, detail="Only admins can view pending delegations for approval")
        
    dels_res = await db.execute(
        select(DelegationRequest).where(
            DelegationRequest.group_id == group_id,
            DelegationRequest.status == "pending_admin_approval"
        )
    )
    delegations = dels_res.scalars().all()
    return BaseResponse(success=True, message="Pending delegations fetched", data=delegations)

