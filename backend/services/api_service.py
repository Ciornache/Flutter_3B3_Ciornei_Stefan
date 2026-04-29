import requests

from config import (
    API_FOOTBALL_BASE_URL,
    API_FOOTBALL_KEY,
    ESPN_BASE_URL,
    SPORT_TO_ESPN_SLUG,
)


def api_football_get(path: str, params: dict | None = None) -> dict:
    if not path.startswith("/"):
        path = "/" + path
    url = f"{API_FOOTBALL_BASE_URL}{path}"
    resp = requests.get(
        url,
        params=params or {},
        headers={"x-apisports-key": API_FOOTBALL_KEY},
        timeout=15,
    )
    if resp.status_code != 200:
        raise Exception(f"api-football {path} -> {resp.status_code}")
    return resp.json()


def espn_scoreboard(sport_id: str, league_slug: str, date: str | None = None) -> dict:
    slug = SPORT_TO_ESPN_SLUG[sport_id]
    url = f"{ESPN_BASE_URL}/{slug}/{league_slug}/scoreboard"
    params = {"dates": date} if date else None
    resp = requests.get(url, params=params, timeout=15)
    if resp.status_code != 200:
        raise Exception(f"espn {sport_id}/{league_slug} -> {resp.status_code}")
    return resp.json()


def espn_summary(sport_id: str, league_slug: str, event_id: str) -> dict:
    slug = SPORT_TO_ESPN_SLUG[sport_id]
    url = f"{ESPN_BASE_URL}/{slug}/{league_slug}/summary"
    resp = requests.get(url, params={"event": event_id}, timeout=15)
    if resp.status_code != 200:
        raise Exception(f"espn summary {event_id} -> {resp.status_code}")
    return resp.json()
