import json
from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from app.modules.user.models import User
from app.modules.group.models import Group
from app.modules.membership.models import Membership
from app.modules.transaction.models import GroupLedgerEntry
from app.common.enums import GroupLedgerEntryType

async def calculate_user_risk_score(user_id: str, db: AsyncSession):
    """
    Calculates the risk score for a user based on their payment history across all groups.
    Updates the User's risk_score and risk_factors columns.
    """
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalar_one_or_none()
    if not user:
        return None
        
    # Get all memberships
    mem_res = await db.execute(
        select(Membership, Group)
        .join(Group, Membership.group_id == Group.id)
        .where(Membership.user_id == user_id)
    )
    memberships = mem_res.all()
    
    if not memberships:
        # Default neutral
        user.risk_score = 50
        user.risk_factors = json.dumps({"reason": "No active memberships yet"})
        db.add(user)
        await db.commit()
        return user
        
    total_expected_cycles = 0
    total_paid_cycles = 0
    on_time_cycles = 0
    consecutive_on_time_streak = 0
    max_streak = 0
    
    for mem, group in memberships:
        # If group hasn't started, skip
        if not group.started_at:
            continue
            
        # Expected cycles for this user in this group is up to the current group cycle
        expected = group.current_cycle_number
        total_expected_cycles += expected
        
        # Get user's contribution entries for this group
        entries_res = await db.execute(
            select(GroupLedgerEntry)
            .where(
                and_(
                    GroupLedgerEntry.group_id == group.id,
                    GroupLedgerEntry.member_id == user_id,
                    GroupLedgerEntry.type.in_([GroupLedgerEntryType.CONTRIBUTION_WALLET.value, GroupLedgerEntryType.CONTRIBUTION_DIRECT.value])
                )
            )
            .order_by(GroupLedgerEntry.cycle_number.asc())
        )
        entries = entries_res.scalars().all()
        
        for entry in entries:
            total_paid_cycles += 1
            
            # Estimate deadline for this cycle
            # We don't have historical deadlines, so we approximate
            # Cycle 1 deadline = started_at + frequency duration
            days_per_cycle = 7 if group.cycle_frequency == "weekly" else 30
            deadline = group.started_at + timedelta(days=days_per_cycle * entry.cycle_number)
            
            if entry.created_at.replace(tzinfo=timezone.utc) <= deadline.replace(tzinfo=timezone.utc):
                on_time_cycles += 1
                consecutive_on_time_streak += 1
                if consecutive_on_time_streak > max_streak:
                    max_streak = consecutive_on_time_streak
            else:
                consecutive_on_time_streak = 0
                
    if total_expected_cycles == 0:
        # Started groups but no cycles passed?
        user.risk_score = 50
        user.risk_factors = json.dumps({"reason": "Groups just started"})
        db.add(user)
        await db.commit()
        return user
        
    # Calculate components
    # Punctuality (35%): Ratio of on-time payments to expected payments
    punctuality = (on_time_cycles / total_expected_cycles) * 100
    
    # Consistency streak (25%): Max streak relative to expected cycles
    streak = (max_streak / total_expected_cycles) * 100 if total_expected_cycles > 0 else 0
    
    # Completion rate (25%): Total paid vs expected
    completion = (total_paid_cycles / total_expected_cycles) * 100
    
    # Tenure (10%): Starts neutral (50), scales to 100 after 10 cycles
    tenure = min(100, 50 + (total_expected_cycles * 5))
    
    # Relative standing (5%): Baseline 50
    relative = 50
    
    score = (0.35 * punctuality) + (0.25 * streak) + (0.25 * completion) + (0.10 * tenure) + (0.05 * relative)
    
    user.risk_score = int(min(100, max(0, score)))
    
    badge = "High"
    if user.risk_score >= 70:
        badge = "Low"
    elif user.risk_score >= 40:
        badge = "Medium"
        
    factors = {
        "punctuality": round(punctuality, 2),
        "streak": round(streak, 2),
        "completion": round(completion, 2),
        "tenure": round(tenure, 2),
        "badge": badge,
        "total_paid": total_paid_cycles,
        "total_expected": total_expected_cycles
    }
    user.risk_factors = json.dumps(factors)
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    return user
