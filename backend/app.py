from datetime import date, datetime, timedelta, timezone
from flask import Flask, jsonify, request

import cache
from config import (
    CONTINENTS,
    COUNTRIES_TTL,
    COUNTRY_CONTINENT,
    DEBUG,
    DETAILS_FINISHED_TTL,
    DETAILS_LIVE_TTL,
    ESPN_LEAGUES,
    FIXTURES_TTL,
    LEAGUES_TTL,
    PORT,
    SPORTS,
)
from db import init_db, session_scope
from mappers.country import country_from_football
from mappers.details import details_from_espn, details_from_football
from mappers.fixture import fixture_from_espn, fixture_from_football
from mappers.league import league_from_football, league_from_seed
from models import Device, Subscription
from services.api_service import (
    ProviderError,
    api_football_get,
    espn_date,
    espn_scoreboard,
    espn_summary,
)
from services.notifications import subscribe_token, unsubscribe_token

app = Flask(__name__)


@app.get("/sports")
def sports():
    return jsonify(SPORTS)


@app.get("/continents")
def continents():
    return jsonify(CONTINENTS)


@app.get("/countries")
def countries():
    cached = cache.get("countries", COUNTRIES_TTL)
    if cached is not None:
        return jsonify(cached)
    try:
        data = api_football_get("/countries")
    except ProviderError as e:
        return {"error": str(e)}, 502
    items = [country_from_football(c) for c in data.get("response", [])]
    items.append({"id": "World", "name": "World", "code": "World", "flag": "", "continent": "World"})
    cache.put("countries", items)
    return jsonify(items)


@app.get("/leagues")
def leagues():
    sport = request.args.get("sport")
    cache_key = f"leagues:{sport or 'all'}"
    cached = cache.get(cache_key, LEAGUES_TTL)
    if cached is not None:
        return jsonify(cached)

    items: list[dict] = [league_from_seed(s) for s in ESPN_LEAGUES]
    try:
        data = api_football_get("/leagues")
        items.extend(league_from_football(l) for l in data.get("response", []))
    except ProviderError as e:
        app.logger.warning("football leagues fetch failed: %s", e)

    if sport:
        items = [l for l in items if l["sportId"] == sport]
    cache.put(cache_key, items)
    return jsonify(items)



@app.get("/fixtures")
def fixtures():
    sport = request.args.get("sport", "football")
    dates = _parse_dates(request.args.get("dates"))

    cache_key = f"fixtures:{sport}:{','.join(d.isoformat() for d in dates)}"
    cached = cache.get(cache_key, FIXTURES_TTL)
    if cached is not None:
        return jsonify(cached)

    items: list[dict] = []

    if sport == "football":
        for d in dates:
            try:
                data = api_football_get("/fixtures", params={"date": d.isoformat()})
                items.extend(
                    fixture_from_football(f, _resolve_country)
                    for f in data.get("response", [])
                )
            except ProviderError as e:
                app.logger.warning("football fixtures %s failed: %s", d, e)
    else:
        leagues_for_sport = [l for l in ESPN_LEAGUES if l["sport_id"] == sport]
        for league in leagues_for_sport:
            for d in dates:
                try:
                    data = espn_scoreboard(sport, league["id"], espn_date(d))
                    items.extend(
                        fixture_from_espn(e, sport, league)
                        for e in data.get("events", [])
                    )
                except ProviderError as e:
                    app.logger.warning("espn %s/%s %s failed: %s", sport, league["id"], d, e)

    cache.put(cache_key, items)
    return jsonify(items)


@app.get("/fixtures/<sport>/<fixture_id>/details")
def fixture_details(sport: str, fixture_id: str):
    status = (request.args.get("status") or "").lower()
    ttl = DETAILS_FINISHED_TTL if status == "finished" else DETAILS_LIVE_TTL

    if sport == "football":
        home_id = int(request.args.get("homeTeamId") or 0)
        away_id = int(request.args.get("awayTeamId") or 0)
        cache_key = f"details:football:{fixture_id}"
        cached = cache.get(cache_key, ttl)
        if cached is not None:
            return jsonify(cached)
        try:
            stats_resp = api_football_get("/fixtures/statistics", params={"fixture": fixture_id})
            events_resp = api_football_get("/fixtures/events", params={"fixture": fixture_id})
        except ProviderError as e:
            return {"error": str(e)}, 502
        payload = details_from_football(stats_resp, events_resp, home_id, away_id)
        payload["fixtureId"] = int(fixture_id)
        cache.put(cache_key, payload)
        return jsonify(payload)

    league_slug = request.args.get("league")
    if not league_slug:
        return {"error": "league query param required for ESPN sports"}, 400
    cache_key = f"details:{sport}:{league_slug}:{fixture_id}"
    cached = cache.get(cache_key, ttl)
    if cached is not None:
        return jsonify(cached)
    try:
        summary = espn_summary(sport, league_slug, fixture_id)
    except ProviderError as e:
        return {"error": str(e)}, 502
    payload = details_from_espn(summary)
    payload["fixtureId"] = int(fixture_id)
    cache.put(cache_key, payload)
    return jsonify(payload)


@app.post("/cache/invalidate")
def cache_invalidate():
    prefix = request.args.get("prefix", "")
    cache.invalidate(prefix)
    return {"invalidated": prefix or "all"}


@app.post("/devices")
def register_device():
    body = request.get_json(silent=True) or {}
    device_id = body.get("deviceId")
    fcm_token = body.get("fcmToken")
    platform = body.get("platform", "android")
    if not isinstance(device_id, str) or not device_id:
        return {"error": "deviceId (str) required"}, 400
    if not isinstance(fcm_token, str) or not fcm_token:
        return {"error": "fcmToken (str) required"}, 400

    now = datetime.now(timezone.utc)
    with session_scope() as s:
        device = s.get(Device, device_id)
        if device is None:
            device = Device(
                device_id=device_id,
                fcm_token=fcm_token,
                platform=platform,
                created_at=now,
                last_seen_at=now,
            )
            s.add(device)
        else:
            device.fcm_token = fcm_token
            device.platform = platform
            device.last_seen_at = now
    return {"deviceId": device_id, "registered": True}


def _device_fcm_token(device_id: str) -> str | None:
    with session_scope() as s:
        device = s.get(Device, device_id)
        return device.fcm_token if device else None


@app.put("/devices/<device_id>/watchlist/<int:match_id>")
def watchlist_subscribe(device_id: str, match_id: int):
    fcm_token = _device_fcm_token(device_id)
    if fcm_token is None:
        return {"error": "device not registered"}, 404

    try:
        subscribe_token(fcm_token, match_id)
    except RuntimeError as e:
        return {"error": str(e)}, 503
    except Exception as e:
        app.logger.exception("FCM subscribe failed")
        return {"error": str(e)}, 502

    with session_scope() as s:
        existing = s.get(Subscription, (device_id, match_id))
        if existing is None:
            s.add(Subscription(device_id=device_id, match_id=match_id))

    return {"deviceId": device_id, "matchId": match_id}


@app.delete("/devices/<device_id>/watchlist")
def watchlist_unsubscribe(device_id: str):
    match_id_raw = request.args.get("matchId")
    try:
        match_id = int(match_id_raw) if match_id_raw is not None else None
    except ValueError:
        match_id = None
    if match_id is None:
        return {"error": "matchId query param required"}, 400

    fcm_token = _device_fcm_token(device_id)
    if fcm_token is None:
        return {"error": "device not registered"}, 404

    try:
        unsubscribe_token(fcm_token, match_id)
    except RuntimeError as e:
        return {"error": str(e)}, 503
    except Exception as e:
        app.logger.exception("FCM unsubscribe failed")
        return {"error": str(e)}, 502

    with session_scope() as s:
        existing = s.get(Subscription, (device_id, match_id))
        if existing is not None:
            s.delete(existing)

    return {"deviceId": device_id, "matchId": match_id}


def _parse_dates(arg: str | None) -> list[date]:
    if arg:
        parts = [p.strip() for p in arg.split(",") if p.strip()]
        out = []
        for p in parts:
            try:
                out.append(date.fromisoformat(p))
            except ValueError:
                pass
        if out:
            return out
    today = date.today()
    return [today - timedelta(days=1), today, today + timedelta(days=1)]


def _resolve_country(raw: str) -> tuple[str, str]:
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
        except ProviderError:
            return ""
        cached = [country_from_football(c) for c in data.get("response", [])]
        cached.append({"id": "World", "name": "World", "code": "World", "flag": "", "continent": "World"})
        cache.put("countries", cached)
    for c in cached:
        if c.get("name") == name:
            return c.get("code") or ""
    return ""

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=PORT, debug=DEBUG)
