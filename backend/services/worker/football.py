from datetime import date, datetime, timezone
from typing import ClassVar

from db import session_scope
from mappers._utils import as_int, as_map
from services.api_service import api_football_get
from services.worker.base import Worker


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class FootballWorker(Worker):
    name: ClassVar[str] = "football"
    poll_seconds: ClassVar[int] = 600
    provider: ClassVar[str] = "football"

    def __init__(self) -> None:
        super().__init__()
        self._fixture_meta: dict[int, dict] = {}

    def tick(self) -> None:
        try:
            data = api_football_get("/fixtures", params={"live": "all"})
        except Exception as e:
            self.log.warning("live fetch failed: %s", e)
            return

        fixtures = data.get("response") if isinstance(data, dict) else []
        fixtures = fixtures or []
        live_ids: set[int] = set()

        for f in fixtures:
            fm = as_map(f)
            fixture_meta = as_map(fm.get("fixture"))
            fixture_id = as_int(fixture_meta.get("id"))
            if not fixture_id:
                continue
            live_ids.add(fixture_id)

            fixture_date_raw = str(fixture_meta.get("date") or "")
            fixture_date = (
                fixture_date_raw[:10] if fixture_date_raw else date.today().isoformat()
            )

            teams = as_map(fm.get("teams"))
            home_team = str(as_map(teams.get("home")).get("name") or "")
            away_team = str(as_map(teams.get("away")).get("name") or "")

            events = [e for e in (fm.get("events") or []) if isinstance(e, dict)]

            with session_scope() as s:
                state, just_created = self._get_or_create_state(s, fixture_id, self.provider)
                prev_count = state.event_count
                new_events = events[prev_count:]
                state.event_count = len(events)
                state.last_polled_at = _utcnow()
                if new_events:
                    state.last_event_key = self._event_key(new_events[-1])

            self._fixture_meta[fixture_id] = {
                "home": home_team, "away": away_team, "date": fixture_date,
            }

            if just_created:
                self._send_lifecycle(
                    fixture_id, "Match started",
                    home_team, away_team, "football", fixture_date,
                )

            for ev in new_events:
                title, body = self._build_notification(ev)
                key = self._event_key(ev)
                self._send_and_record(
                    fixture_id, self.provider, key, title, body,
                    sport="football", fixture_date=fixture_date,
                )

        for fixture_id in self._close_missing(self.provider, live_ids):
            meta = self._fixture_meta.pop(fixture_id, None)
            if meta is None:
                continue
            self._send_lifecycle(
                fixture_id, "Match ended",
                meta["home"], meta["away"], "football", meta["date"],
            )

    def _event_key(self, event: dict) -> str:
        time_map = as_map(event.get("time"))
        player = as_map(event.get("player"))
        team = as_map(event.get("team"))
        assist = as_map(event.get("assist"))
        return "|".join([
            str(time_map.get("elapsed") or ""),
            str(time_map.get("extra") or ""),
            str(event.get("type") or ""),
            str(event.get("detail") or ""),
            str(team.get("id") or ""),
            str(player.get("id") or ""),
            str(assist.get("id") or ""),
        ])

    @staticmethod
    def _clock(time_map: dict) -> str:
        elapsed = time_map.get("elapsed")
        extra = time_map.get("extra")
        if elapsed is None:
            return ""
        if extra is not None:
            return f"{elapsed}+{extra}'"
        return f"{elapsed}'"

    def _build_notification(self, event: dict) -> tuple[str, str]:
        type_ = str(event.get("type") or "").strip()
        detail = str(event.get("detail") or "").strip()
        time_map = as_map(event.get("time"))
        player = as_map(event.get("player"))
        assist = as_map(event.get("assist"))
        clock = self._clock(time_map)
        player_name = str(player.get("name") or "")
        assist_name = str(assist.get("name") or "")

        kind = type_.lower()

        if kind == "subst":
            body = (
                f"{player_name} → {assist_name} ({clock})"
                if assist_name else f"{player_name} ({clock})"
            )
            return "Substitution", body

        if kind == "goal":
            body = f"{player_name} ({clock})"
            if assist_name and detail.lower() != "own goal":
                body += f"\nAssist: {assist_name}"
            return detail or "Goal", body

        if kind == "card":
            return detail or "Card", f"{player_name} ({clock})"

        if kind == "var":
            body = (
                f"{detail} - {player_name} ({clock})"
                if player_name else f"{detail} ({clock})"
            )
            return "VAR", body

        title = type_ or "Event"
        body = f"{detail} - {player_name} ({clock})".strip(" -")
        return title, body
