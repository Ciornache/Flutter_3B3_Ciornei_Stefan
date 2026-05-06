"""Internal helpers used by the Flask endpoints in app.py."""

from __future__ import annotations

import logging
import threading
from datetime import date

import cache
from config import (
    COUNTRIES_TTL,
    COUNTRY_CONTINENT,
    ESPN_LEAGUES,
    FIXTURES_TTL,
)
from db import session_scope
from mappers._utils import espn_date
from mappers.country import country_from_football
from mappers.fixture import fixture_from_espn, fixture_from_football
from models import Device
from services.api_service import api_football_get, espn_scoreboard
from services.worker import EspnWorker, FootballWorker, Worker

log = logging.getLogger(__name__)


def start_workers() -> list[threading.Thread]:
    workers: list[Worker] = [FootballWorker(), EspnWorker()]
    threads: list[threading.Thread] = []
    for w in workers:
        t = threading.Thread(target=w.run, name=f"{w.name}-events", daemon=True)
        t.start()
        threads.append(t)
    return threads


def device_fcm_token(device_id: str) -> str | None:
    with session_scope() as s:
        device = s.get(Device, device_id)
        return device.fcm_token if device else None


def fetch_fixtures_for_date(sport: str, d: date) -> list[dict]:
    cache_key = f"fixtures_raw:{sport}:{d.isoformat()}"
    cached = cache.get(cache_key, FIXTURES_TTL)
    if isinstance(cached, list):
        return cached

    items: list[dict] = []
    ok = True
    if sport == "football":
        try:
            data = api_football_get("/fixtures", params={"date": d.isoformat()})
            items.extend(
                fixture_from_football(f, _resolve_country)
                for f in data.get("response", [])
            )
        except Exception as e:
            log.warning("football fixtures %s failed: %s", d, e)
            ok = False
        if ok:
            cache.put(cache_key, items)
        return items

    leagues_for_sport = [l for l in ESPN_LEAGUES if l["sport_id"] == sport]
    for league in leagues_for_sport:
        try:
            data = espn_scoreboard(sport, league["id"], espn_date(d))
            items.extend(
                fixture_from_espn(e, sport, league)
                for e in data.get("events", [])
            )
        except Exception as e:
            log.warning("espn %s/%s %s failed: %s", sport, league["id"], d, e)
            ok = False
    if ok:
        cache.put(cache_key, items)
    return items


def _resolve_country(raw: str) -> tuple[str, str]:
    if raw == "World":
        return "World", "World"
    if len(raw) == 2 and raw.isalpha():
        code = raw.upper()
    else:
        code = _lookup_code_by_name(raw)
    return code, COUNTRY_CONTINENT.get(code, "")


def _lookup_code_by_name(name: str) -> str:
    if not name:
        return ""
    cached = cache.get("countries", COUNTRIES_TTL)
    if cached is None:
        try:
            data = api_football_get("/countries")
        except Exception:
            return ""
        cached = [country_from_football(c) for c in data.get("response", [])]
        cached.append({"id": "World", "name": "World", "code": "World", "flag": "", "continent": "World"})
        cache.put("countries", cached)
    for c in cached:
        if c.get("name") == name:
            return c.get("code") or ""
    return ""
