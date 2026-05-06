from datetime import date, datetime, timezone
from typing import ClassVar

from config import ESPN_LEAGUES
from db import session_scope
from mappers._utils import as_int, as_map, espn_date
from services.api_service import espn_scoreboard, espn_summary
from services.worker.base import Worker


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class EspnWorker(Worker):
    name: ClassVar[str] = "espn"
    poll_seconds: ClassVar[int] = 45

    def __init__(self) -> None:
        super().__init__()
        self._fixture_meta: dict[tuple[int, str], dict] = {}

    @staticmethod
    def _provider(sport_id: str, league_slug: str) -> str:
        return f"espn:{sport_id}:{league_slug}"

    def tick(self) -> None:
        for league in ESPN_LEAGUES:
            try:
                self._tick_league(league["sport_id"], league)
            except Exception:
                self.log.exception("league tick failed for %s/%s", league["sport_id"], league["id"])

    def _tick_league(self, sport_id: str, league: dict) -> None:
        league_slug = league["id"]
        provider = self._provider(sport_id, league_slug)
        today = espn_date(date.today())

        try:
            board = espn_scoreboard(sport_id, league_slug, today)
        except Exception as e:
            self.log.warning("scoreboard %s/%s failed: %s", sport_id, league_slug, e)
            return

        live_ids: set[int] = set()
        for event in board.get("events") or []:
            em = as_map(event)
            comps = em.get("competitions") or []
            comp = as_map(comps[0] if comps else {})
            status_type = as_map(as_map(comp.get("status")).get("type"))
            state = (status_type.get("state") or "").lower()
            if state != "in":
                continue

            event_id = as_int(em.get("id"))
            if not event_id:
                continue
            live_ids.add(event_id)

            event_date_raw = str(em.get("date") or "")
            fixture_date = event_date_raw[:10] if event_date_raw else date.today().isoformat()

            home_team, away_team = self._extract_teams(comp)

            try:
                summary = espn_summary(sport_id, league_slug, str(event_id))
            except Exception as e:
                self.log.warning("summary %s/%s/%s failed: %s", sport_id, league_slug, event_id, e)
                continue

            plays = summary.get("plays") or []
            plays = [p for p in plays if isinstance(p, dict)]

            with session_scope() as s:
                st, just_created = self._get_or_create_state(s, event_id, provider)
                prev_count = st.event_count
                new_plays = plays[prev_count:]
                st.event_count = len(plays)
                st.last_polled_at = _utcnow()
                if new_plays:
                    st.last_event_key = self._event_key(new_plays[-1])

            self._fixture_meta[(event_id, provider)] = {
                "home": home_team, "away": away_team,
                "sport": sport_id, "date": fixture_date,
            }

            if just_created:
                self._send_lifecycle(
                    event_id, "Match started",
                    home_team, away_team, sport_id, fixture_date,
                )

            for play in new_plays:
                title, body = self._build_notification(play)
                key = self._event_key(play)
                self._send_and_record(
                    event_id, provider, key, title, body,
                    sport=sport_id, fixture_date=fixture_date,
                )

        for fixture_id in self._close_missing(provider, live_ids):
            meta = self._fixture_meta.pop((fixture_id, provider), None)
            if meta is None:
                continue
            self._send_lifecycle(
                fixture_id, "Match ended",
                meta["home"], meta["away"], meta["sport"], meta["date"],
            )

    @staticmethod
    def _extract_teams(comp: dict) -> tuple[str, str]:
        home = away = ""
        for c in comp.get("competitors") or []:
            cm = as_map(c)
            team = as_map(cm.get("team"))
            name = team.get("displayName") or team.get("name") or ""
            if cm.get("homeAway") == "home":
                home = name
            elif cm.get("homeAway") == "away":
                away = name
        return home, away

    def _event_key(self, play: dict) -> str:
        pid = play.get("id")
        if pid is not None:
            return str(pid)
        period = as_map(play.get("period"))
        clock = as_map(play.get("clock"))
        return "|".join([
            str(period.get("number") or ""),
            str(clock.get("displayValue") or ""),
            str(play.get("text") or ""),
        ])

    def _build_notification(self, play: dict) -> tuple[str, str]:
        type_map = as_map(play.get("type"))
        title = str(type_map.get("text") or "Play")
        text = str(play.get("text") or "")
        clock = as_map(play.get("clock"))
        period = as_map(play.get("period"))
        period_str = str(period.get("displayValue") or period.get("number") or "")
        clock_str = str(clock.get("displayValue") or "")
        suffix = " ".join(p for p in [period_str, clock_str] if p)
        body = f"{text} ({suffix})" if suffix else text
        return title, body
