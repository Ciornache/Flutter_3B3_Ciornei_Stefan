from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from db import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class LiveFixtureState(Base):
    __tablename__ = "live_fixture_state"

    fixture_id: Mapped[int] = mapped_column("match_id", Integer, primary_key=True)
    provider: Mapped[str] = mapped_column(String, primary_key=True)
    event_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_event_key: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    last_polled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    closed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
