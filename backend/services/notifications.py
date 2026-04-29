import firebase_admin
from firebase_admin import credentials, messaging

from config import FIREBASE_CREDENTIALS_PATH


def init_firebase() -> None:
    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)


def topic_for_match(match_id: int) -> str:
    return f"match_{match_id}"


def subscribe_token(token: str, match_id: int) -> messaging.TopicManagementResponse:
    return messaging.subscribe_to_topic([token], topic_for_match(match_id))


def unsubscribe_token(token: str, match_id: int) -> messaging.TopicManagementResponse:
    return messaging.unsubscribe_from_topic([token], topic_for_match(match_id))


def notify_token(
    token: str,
    title: str,
    body: str,
    sport: str = "football",
    fixture_date: str = "",
    match_id: int = 0,
) -> str:
    msg = messaging.Message(
        token=token,
        data={
            "matchId": str(match_id),
            "sport": sport,
            "date": fixture_date,
            "title": title,
            "body": body,
        },
        android=messaging.AndroidConfig(priority="high"),
    )
    return messaging.send(msg)


def notify_match(
    match_id: int,
    title: str,
    body: str,
    sport: str,
    fixture_date: str,
    extra: dict[str, str] | None = None,
) -> str:
    msg = messaging.Message(
        topic=topic_for_match(match_id),
        data={
            "matchId": str(match_id),
            "sport": sport,
            "date": fixture_date,
            "title": title,
            "body": body,
            **(extra or {}),
        },
        android=messaging.AndroidConfig(priority="high"),
    )
    return messaging.send(msg)
