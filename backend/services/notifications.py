import firebase_admin
from firebase_admin import credentials, messaging

from config import FIREBASE_CREDENTIALS_PATH


def init_firebase() -> None:
    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)


def topic_for_match(fixture_id: int) -> str:
    return f"match_{fixture_id}"


def subscribe_token(token: str, fixture_id: int) -> messaging.TopicManagementResponse:
    return messaging.subscribe_to_topic([token], topic_for_match(fixture_id))


def unsubscribe_token(token: str, fixture_id: int) -> messaging.TopicManagementResponse:
    return messaging.unsubscribe_from_topic([token], topic_for_match(fixture_id))


def notify_match(
    fixture_id: int,
    title: str,
    body: str,
    sport: str,
    fixture_date: str,
    extra: dict[str, str] | None = None,
) -> str:
    msg = messaging.Message(
        topic=topic_for_match(fixture_id),
        data={
            "matchId": str(fixture_id),
            "sport": sport,
            "date": fixture_date,
            "title": title,
            "body": body,
            **(extra or {}),
        },
        android=messaging.AndroidConfig(priority="high"),
    )
    return messaging.send(msg)
