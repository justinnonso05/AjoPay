from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class DelegateRequestPayload(BaseModel):
    to_member_id: str
    pin: str

class SwapRequestPayload(BaseModel):
    target_member_id: str
    target_cycle_number: int
    pin: str

class SwapRespondPayload(BaseModel):
    accept: bool
    pin: str

class AdminApprovePayload(BaseModel):
    approve: bool
    pin: str
    reason: Optional[str] = None

class CycleAssignmentResponse(BaseModel):
    id: str
    group_id: str
    cycle_number: int
    assigned_member_id: str
    actual_recipient_id: str
    delegation_id: Optional[str] = None
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class DelegationRequestResponse(BaseModel):
    id: str
    group_id: str
    cycle_number: int
    from_member_id: str
    to_member_id: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class SwapRequestResponse(BaseModel):
    id: str
    group_id: str
    initiator_member_id: str
    target_member_id: str
    initiator_cycle_number: int
    target_cycle_number: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
