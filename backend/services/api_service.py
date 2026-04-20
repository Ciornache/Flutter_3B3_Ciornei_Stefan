import requests
from config import (
    API_FOOTBALL_BASE_URL,
    API_FOOTBALL_KEY,
    API_FOOTBALL_KEY_SECONDARY,
    ESPN_BASE_URL,
    SPORT_TO_ESPN_SLUG,
)


class ProviderError(Exception):
    pass


def _quota_exhausted(resp: requests.Response) -> bool:
    if resp.status_code == 429:
        return True
    if resp.status_code != 200:
        return False
    try:
        data = resp.json()
    except ValueError:
        return False
    errs = data.get("errors") if isinstance(data, dict) else None
    if isinstance(errs, dict):
        return errs.get("rateLimit") is not None or errs.get("requests") is not None
    return False


def api_football_get(path: str, params: dict | None = None) -> dict:
    if not path.startswith("/"):
        path = "/" + path
    url = f"{API_FOOTBALL_BASE_URL}{path}"

    def _call(key: str) -> requests.Response:
        return requests.get(url, params=params or {}, headers={"x-apisports-key": key}, timeout=15)

    resp = _call(API_FOOTBALL_KEY)
    if _quota_exhausted(resp) and API_FOOTBALL_KEY_SECONDARY:
        resp = _call(API_FOOTBALL_KEY_SECONDARY)
    if resp.status_code != 200:
        raise ProviderError(f"api-football {path} → {resp.status_code}")
    return resp.json()


def espn_scoreboard(sport_id: str, league_slug: str, date: str | None = None) -> dict:
    slug = SPORT_TO_ESPN_SLUG[sport_id]
    url = f"{ESPN_BASE_URL}/{slug}/{league_slug}/scoreboard"
    params = {"dates": date} if date else None
    resp = requests.get(url, params=params, timeout=15)
    if resp.status_code != 200:
        raise ProviderError(f"espn {sport_id}/{league_slug} → {resp.status_code}")
    return resp.json()


def espn_summary(sport_id: str, league_slug: str, event_id: str) -> dict:
    slug = SPORT_TO_ESPN_SLUG[sport_id]
    url = f"{ESPN_BASE_URL}/{slug}/{league_slug}/summary"
    resp = requests.get(url, params={"event": event_id}, timeout=15)
    if resp.status_code != 200:
        raise ProviderError(f"espn summary {event_id} → {resp.status_code}")
    return resp.json()


def espn_date(d) -> str:
    return d.strftime("%Y%m%d")
