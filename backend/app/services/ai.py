from google import genai
from google.genai import types
from app.core.config import settings

def get_client():
    if not settings.GEMINI_API_KEY:
        return None
    return genai.Client(api_key=settings.GEMINI_API_KEY)

async def generate_reminder_copy(member_name: str, group_name: str, amount: float, cycle_number: int) -> str:
    """
    Generate an AI-crafted localized reminder copy using Gemini.
    """
    client = get_client()
    if not client:
        return f"Hello {member_name}, please remember to pay your Ajo contribution of ₦{amount:,.2f} for cycle {cycle_number} in {group_name}."
        
    prompt = f"""
You are an expert community manager for a Nigerian Ajo (rotating savings) group named '{group_name}'.
A member named '{member_name}' needs a friendly, respectful, but firm reminder to pay their upcoming contribution of ₦{amount:,.2f} for cycle {cycle_number}.
Write a short, engaging text message (SMS size) in a relatable Nigerian tone (can use mild Pidgin English or warm local phrasing).
Keep it under 160 characters if possible. Do not include placeholders, just the raw message.
"""
    try:
        # We run the synchronous generate_content in a thread pool using asyncio to avoid blocking
        import asyncio
        loop = asyncio.get_event_loop()
        
        def _call_gemini():
            return client.models.generate_content(
                model='gemini-3.5-flash',
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                )
            )
            
        response = await loop.run_in_executor(None, _call_gemini)
        return response.text.strip()
    except Exception as e:
        import logging
        logging.error(f"Gemini API Error: {e}", exc_info=True)
        # Fallback
        return f"Hello {member_name}, kindly remit your ₦{amount:,.2f} Ajo contribution for cycle {cycle_number} in {group_name}."
