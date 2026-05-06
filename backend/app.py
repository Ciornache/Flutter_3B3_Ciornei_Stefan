import logging
from datetime import date, datetime, timezone

from flask import Flask, jsonify, request

import cache
from config import (
    CONTINENTS,
    COUNTRIES_TTL,
    DEBUG,
    DETAILS_FINISHED_TTL,
    DETAILS_LIVE_TTL,
    ESPN_LEAGUES,
    FIXTURES_PAGE_SIZE,
    LEAGUES_TTL,
    PORT,
    SPORTS,
)
from db import init_db, session_scope
from mappers.country import country_from_football
from mappers.details import details_from_espn, details_from_football
from mappers.league import league_from_football, league_from_seed
from models import Device, Subscription
from route_helpers import (
    device_fcm_token,
    fetch_fixtures_for_date,
    start_workers,
)
from services.api_service import api_football_get, espn_summary
from services.notifications import (
    init_firebase,
    notify_match,
    subscribe_token,
    unsubscribe_token,
)


app = Flask(__name__)

init_db()
init_firebase()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
_worker_threads = start_workers()
logging.info("workers started: %d", len(_worker_threads))


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
    except Exception as e:
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
    except Exception as e:
        app.logger.warning("football leagues fetch failed: %s", e)

    if sport:
        items = [l for l in items if l["sportId"] == sport]
    cache.put(cache_key, items)
    return jsonify(items)


@app.get("/fixtures")
def fixtures():
    sport = request.args.get("sport") or None
    date_arg = request.args.get("date")
    country = request.args.get("country") or None
    continent = request.args.get("continent") or None
    league = request.args.get("league") or None
    favourites = (request.args.get("favourites") or "").lower() == "true"
    device_id = request.args.get("deviceId") or None
    page = int(request.args.get("page", "0"))

    try:
        d = date.fromisoformat(date_arg) if date_arg else date.today()
    except ValueError:
        d = date.today()

    favourite_ids: set[int] | None = None
    if favourites and device_id:
        with session_scope() as s:
            rows = s.query(Subscription.fixture_id).filter(
                Subscription.device_id == device_id
            ).all()
            favourite_ids = {r[0] for r in rows}

    sports_to_fetch = [sport] if sport else [s["id"] for s in SPORTS]
    items: list[dict] = []
    for sp in sports_to_fetch:
        items.extend(fetch_fixtures_for_date(sp, d))

    items = [
        f for f in items
        if (country is None or f.get("countryCode") == country)
        and (league is None or f.get("leagueId") == league)
        and (continent is None or f.get("continent") == continent)
        and (favourite_ids is None or f.get("id") in favourite_ids)
    ]
    items.sort(key=lambda f: f.get("date") or "")

    total = len(items)
    total_pages = (total + FIXTURES_PAGE_SIZE - 1) // FIXTURES_PAGE_SIZE
    total_pages = max(total_pages, 1)
    page = min(max(page, 0), total_pages - 1)
    start_idx = page * FIXTURES_PAGE_SIZE
    fixtures = items[start_idx : start_idx + FIXTURES_PAGE_SIZE]

    return jsonify({
        "total": total,
        "totalPages": total_pages,
        "page": page,
        "pageSize": FIXTURES_PAGE_SIZE,
        "fixtures": fixtures,
    })


@app.get("/fixtures/<sport>/<int:fixture_id>")
def fixture_by_id(sport: str, fixture_id: int):
    date_arg = request.args.get("date")
    if not date_arg:
        return {"error": "date query param required"}, 400
    try:
        d = date.fromisoformat(date_arg)
    except ValueError:
        return {"error": "date must be YYYY-MM-DD"}, 400

    items = fetch_fixtures_for_date(sport, d)
    for item in items:
        if item.get("id") == fixture_id:
            return jsonify(item)
    return {"error": "fixture not found"}, 404


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
        except Exception as e:
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
    except Exception as e:
        return {"error": str(e)}, 502
    payload = details_from_espn(summary)
    payload["fixtureId"] = int(fixture_id)
    cache.put(cache_key, payload)
    return jsonify(payload)


@app.post("/debug/notify")
def debug_notify():
    body = request.get_json(silent=True) or {}
    fixture_id = int(body.get("matchId", 0))
    sport = body.get("sport", "football")
    fixture_date = body.get("date", date.today().isoformat())
    title = body.get("title", "Test notification")
    text = body.get("body", "Hello from backend")
    if not fixture_id:
        return {"error": "matchId required"}, 400
    try:
        msg_id = notify_match(fixture_id, title, text, sport=sport, fixture_date=fixture_date)
    except Exception as e:
        return {"error": str(e)}, 502
    return {"sent": True, "fcm_message_id": msg_id}


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


@app.get("/devices/<device_id>/watchlist")
def watchlist_list(device_id: str):
    with session_scope() as s:
        rows = s.query(Subscription.fixture_id).filter(
            Subscription.device_id == device_id
        ).all()
        return jsonify([r[0] for r in rows])


@app.put("/devices/<device_id>/watchlist/<int:fixture_id>")
def watchlist_subscribe(device_id: str, fixture_id: int):
    fcm_token = device_fcm_token(device_id)
    if fcm_token is None:
        return {"error": "device not registered"}, 404

    try:
        subscribe_token(fcm_token, fixture_id)
    except RuntimeError as e:
        return {"error": str(e)}, 503
    except Exception as e:
        app.logger.exception("FCM subscribe failed")
        return {"error": str(e)}, 502

    with session_scope() as s:
        existing = s.get(Subscription, (device_id, fixture_id))
        if existing is None:
            s.add(Subscription(device_id=device_id, fixture_id=fixture_id))

    return {"deviceId": device_id, "matchId": fixture_id}


@app.delete("/devices/<device_id>/watchlist")
def watchlist_unsubscribe(device_id: str):
    fixture_id_raw = request.args.get("matchId")
    if fixture_id_raw is None:
        return {"error": "matchId query param required"}, 400

    fixture_id = int(fixture_id_raw)

    fcm_token = device_fcm_token(device_id)
    if fcm_token is None:
        return {"error": "device not registered"}, 404

    try:
        unsubscribe_token(fcm_token, fixture_id)
    except Exception as e:
        app.logger.exception("FCM unsubscribe failed")
        return {"error": str(e)}, 502

    with session_scope() as s:
        existing = s.get(Subscription, (device_id, fixture_id))
        if existing is not None:
            s.delete(existing)

    return {"deviceId": device_id, "matchId": fixture_id}


if __name__ == "__main__":
    from waitress import serve
    serve(app, host="0.0.0.0", port=PORT)
