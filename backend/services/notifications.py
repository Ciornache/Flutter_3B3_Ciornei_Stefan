import os

import firebase_admin
from firebase_admin import credentials, messaging

from config import FIREBASE_CREDENTIALS_PATH

_initialized = False


def _ensure_initialized() -> bool:
    global _initialized
    if _initialized:
        return True
    if not os.path.exists(FIREBASE_CREDENTIALS_PATH):
        return False
    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)
    _initialized = True
    return True


def topic_for_match(match_id: int) -> str:
    return f"match_{match_id}"


def subscribe_token(token: str, match_id: int) -> messaging.TopicManagementResponse:
    if not _ensure_initialized():
        raise RuntimeError("firebase credentials not configured")
    return messaging.subscribe_to_topic([token], topic_for_match(match_id))


def unsubscribe_token(token: str, match_id: int) -> messaging.TopicManagementResponse:
    if not _ensure_initialized():
        raise RuntimeError("firebase credentials not configured")
    return messaging.unsubscribe_from_topic([token], topic_for_match(match_id))


def notify_match(match_id: int, title: str, body: str, data: dict[str, str] | None = None) -> str:
    if not _ensure_initialized():
        raise RuntimeError("firebase credentials not configured")
    msg = messaging.Message(
        topic=topic_for_match(match_id),
        notification=messaging.Notification(title=title, body=body),
        data={"matchId": str(match_id), **(data or {})},
    )
    return messaging.send(msg)
