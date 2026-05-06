import logging
import time
from abc import ABC, abstractmethod
from datetime import datetime, timezone
from typing import ClassVar

from sqlalchemy import select
from sqlalchemy.orm import Session

from db import session_scope
from models import LiveFixtureState, Notification
from services.notifications import notify_match


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Worker(ABC):
    name: ClassVar[str]
    poll_seconds: ClassVar[int]

    def __init__(self) -> None:
        self.log = logging.getLogger(f"worker.{self.name}")

    @abstractmethod
    def tick(self) -> None:
        """One poll cycle. Subclass implements provider-specific logic."""
        pass

    @abstractmethod
    def _event_key(self, event: dict) -> str:
        pass

    @abstractmethod
    def _build_notification(self, event: dict) -> tuple[str, str]:
        pass

    def run(self) -> None:
        self.log.info("loop starting (interval=%ss)", self.poll_seconds)
        while True:
            start = time.monotonic()
            try:
                self.tick()
            except Exception:
                self.log.exception("tick raised")
            elapsed = time.monotonic() - start
            time.sleep(max(1.0, self.poll_seconds - elapsed))

    def _get_or_create_state(
        self, session: Session, fixture_id: int, provider: str
    ) -> tuple[LiveFixtureState, bool]:
        row = session.get(LiveFixtureState, (fixture_id, provider))
        if row is None:
            row = LiveFixtureState(
                fixture_id=fixture_id,
                provider=provider,
                event_count=0,
                last_polled_at=_utcnow(),
            )
            session.add(row)
            session.flush()
            return row, True
        return row, False

    def _close_missing(self, provider: str, live_ids: set[int]) -> list[int]:
        ended: list[int] = []
        with session_scope() as s:
            stmt = select(LiveFixtureState).where(
                LiveFixtureState.provider == provider,
                LiveFixtureState.closed_at.is_(None),
            )
            for row in s.scalars(stmt).all():
                if row.fixture_id not in live_ids:
                    row.closed_at = _utcnow()
                    ended.append(row.fixture_id)
        return ended

    def _send_lifecycle(
        self, fixture_id: int, title: str,
        home: str, away: str, sport: str, fixture_date: str,
    ) -> None:
        if not sport or not fixture_date:
            return
        body = " vs ".join(p for p in (home, away) if p) or "Match"
        try:
            notify_match(fixture_id, title, body, sport=sport, fixture_date=fixture_date)
        except RuntimeError as e:
            self.log.warning("fcm not configured, skipping lifecycle: %s", e)
        except Exception:
            self.log.exception("fcm lifecycle send failed for fixture %s", fixture_id)

    def _send_and_record(
        self,
        fixture_id: int,
        provider: str,
        event_key: str,
        title: str,
        body: str,
        sport: str,
        fixture_date: str,
    ) -> None:
        fcm_message_id: str | None = None
        try:
            fcm_message_id = notify_match(
                fixture_id, title, body, sport=sport, fixture_date=fixture_date
            )
        except RuntimeError as e:
            self.log.warning("fcm not configured, skipping send: %s", e)
        except Exception:
            self.log.exception("fcm send failed for fixture %s", fixture_id)

        with session_scope() as s:
            s.add(
                Notification(
                    fixture_id=fixture_id,
                    provider=provider,
                    event_key=event_key,
                    title=title,
                    body=body,
                    fcm_message_id=fcm_message_id,
                )
            )
