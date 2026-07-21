import asyncio
from sqlalchemy import event, select
from app.modules.notification.models import Notification
from app.modules.user.models import User
from app.services.push import send_push_notification
from app.core.database import AsyncSessionLocal
import logging

logger = logging.getLogger(__name__)

async def _send_notification_push_async(user_id: str, title: str, message: str, n_type: str, action_id: str):
    logger.info(f"Evaluating push notification for user {user_id} ({n_type})...")
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(User.fcm_token).where(User.id == user_id))
            fcm_token = result.scalar_one_or_none()
            
        if fcm_token:
            logger.info(f"FCM token found for user {user_id}. Dispatching push...")
            data = {"type": n_type}
            if action_id: 
                data["action_id"] = str(action_id)
            await send_push_notification(fcm_token, title, message, data)
        else:
            logger.info(f"User {user_id} has no FCM token registered. Push skipped.")
    except Exception as e:
        logger.error(f"Error resolving FCM token for user {user_id}: {e}")

@event.listens_for(Notification, 'after_insert')
def receive_after_insert(mapper, connection, target: Notification):
    """
    Listens for any new Notification being inserted into the database.
    It synchronously catches the event and spins up a background async task 
    to send the Firebase push notification so the API isn't blocked.
    """
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        # Not running in an async event loop (e.g., synchronous tests or scripts)
        return
    
    # Schedule the background task
    loop.create_task(
        _send_notification_push_async(
            target.user_id, 
            target.title, 
            target.message, 
            target.type, 
            target.action_id
        )
    )

logger.info("Notification push listener registered.")
