import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from app.modules.chat.models import ChatMessage
from app.modules.user.models import User
from app.modules.membership.models import Membership
from app.common.enums import MembershipStatus
from app.core.websocket import manager

logger = logging.getLogger(__name__)

async def notify_group_members_of_new_message(db: AsyncSession, group_id: str, sender: User, message_preview: str, group_name: str = "your group"):
    """
    Sends a push notification to all active group members (except the sender) about a new message.
    """
    from app.modules.notification.service import create_and_dispatch_notification
    
    # Get all active members
    result = await db.execute(
        select(Membership.user_id)
        .where(Membership.group_id == group_id)
        .where(Membership.status == MembershipStatus.ACTIVE)
        .where(Membership.user_id != sender.id)
    )
    member_ids = result.scalars().all()
    
    for member_id in member_ids:
        await create_and_dispatch_notification(
            db=db,
            user_id=member_id,
            title=f"New Message in {group_name}",
            message=f"{sender.first_name}: {message_preview}",
            type="group_chat_message",
            action_id=group_id
        )
    await db.commit()

async def post_system_message(db: AsyncSession, group_id: str, message_text: str):
    """
    Creates a system message in the DB and broadcasts it to connected WebSocket clients.
    """
    message = ChatMessage(
        group_id=group_id,
        sender_id=None,
        message=message_text,
        is_system=True
    )
    db.add(message)
    await db.commit()
    await db.refresh(message)
    
    # Broadcast to the group
    await manager.broadcast(group_id, {
        "id": str(message.id),
        "group_id": group_id,
        "sender_id": None,
        "message": message_text,
        "is_system": True,
        "created_at": message.created_at.isoformat()
    })
    return message

async def verify_membership(db: AsyncSession, group_id: str, user_id: str):
    """
    Verifies that the user is an active member of the group.
    Raises HTTPException if not.
    """
    result = await db.execute(
        select(Membership)
        .where(Membership.group_id == group_id)
        .where(Membership.user_id == user_id)
        .where(Membership.status == MembershipStatus.ACTIVE)
    )
    membership = result.scalar_one_or_none()
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be an active member of the group to access chat."
        )
    return membership

async def get_chat_history_service(db: AsyncSession, group_id: str, user: User, limit: int = 50, offset: int = 0):
    await verify_membership(db, group_id, user.id)
    
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.group_id == group_id)
        .order_by(ChatMessage.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    # Return chronologically by reversing the latest 'limit' messages
    messages = list(result.scalars().all())
    messages.reverse()
    return messages
