from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.common.schemas import BaseResponse
from app.core.database import get_db
from .schemas import WebhookPayload
from .service import process_monnify_webhook, verify_monnify_signature

import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/webhooks", tags=["Webhooks"])

@router.post("/monnify", response_model=BaseResponse[str])
async def handle_monnify_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    body_bytes = await request.body()
    
    # In production, you would verify the signature:
    # if not await verify_monnify_signature(request, body_bytes):
    #     logger.warning("Invalid Monnify signature received")
    #     raise HTTPException(status_code=401, detail="Invalid signature")
    
    import json
    try:
        payload = json.loads(body_bytes)
        if isinstance(payload, str):
            payload = json.loads(payload)
    except Exception as e:
        logger.error(f"Failed to parse Monnify webhook JSON: {str(e)}")
        raise HTTPException(status_code=400, detail="Invalid JSON")
        
    try:
        await process_monnify_webhook(payload, db)
    except Exception as e:
        logger.error(f"Uncaught error in process_monnify_webhook: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal processing error")
    
    return BaseResponse(
        success=True,
        message="Webhook processed successfully",
        data="OK"
    )
