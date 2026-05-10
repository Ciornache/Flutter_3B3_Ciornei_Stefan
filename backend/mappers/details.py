from mappers._utils import as_int, as_map


def details_from_football(
    stats_resp: dict,
    events_resp: dict,
    home_team_id: int,
    away_team_id: int,
) -> dict:
    stats_response = stats_resp.get("response") if isinstance(stats_resp, dict) else []
    stats_response = stats_response or []

    home_stats: dict[str, str] = {}
    away_stats: dict[str, str] = {}
    for t in stats_response:
        m = as_map(t)
        team_id = as_int(as_map(m.get("team")).get("id"))
        raw_stats = m.get("statistics") or []
        parsed: dict[str, str] = {}
        for s in raw_stats:
            sm = as_map(s)
            type_ = str(sm.get("type") or "")
            value = sm.get("value")
            value_str = "" if value is None else str(value)
            if not type_:
                continue
            parsed[type_] = value_str
        if team_id == home_team_id:
            home_stats = parsed
        elif team_id == away_team_id:
            away_stats = parsed
        elif not home_stats:
            home_stats = parsed
        elif not away_stats:
            away_stats = parsed

    labels = list({*home_stats.keys(), *away_stats.keys()})
    stats_rows = [
        {"label": label, "home": home_stats.get(label, ""), "away": away_stats.get(label, "")}
        for label in labels
    ]

    events_response = events_resp.get("response") if isinstance(events_resp, dict) else []
    events_response = events_response or []
    plays: list[dict] = []
    for e in events_response:
        m = as_map(e)
        time_map = as_map(m.get("time"))
        elapsed = time_map.get("elapsed")
        elapsed_s = "" if elapsed is None else str(elapsed)
        extra = time_map.get("extra")
        clock = f"{elapsed_s}+{extra}'" if extra is not None else f"{elapsed_s}'"
        type_ = str(m.get("type") or "")
        detail = str(m.get("detail") or "")
        team = str(as_map(m.get("team")).get("name") or "")
        player = str(as_map(m.get("player")).get("name") or "")
        text = f"{type_} - {detail} - {player} ({team})"
        plays.append({"text": text, "period": "", "clock": clock})

    plays.sort(key=_football_clock_key)
    return {"stats": stats_rows, "plays": plays}


def _football_clock_key(p: dict) -> int:
    cleaned = p["clock"].replace("'", "").split("+")
    try:
        base = int(cleaned[0]) if cleaned[0] else 0
    except ValueError:
        base = 0
    add = 0
    if len(cleaned) > 1:
        try:
            add = int(cleaned[1])
        except ValueError:
            add = 0
    return base * 100 + add


def _flatten_espn_stats(raw_stats: list, category: str = "") -> dict[str, str]:
    parsed: dict[str, str] = {}
    for s in raw_stats:
        sm = as_map(s)
        nested = sm.get("stats")
        if isinstance(nested, list):
            cat = str(sm.get("displayName") or sm.get("name") or "")
            parsed.update(_flatten_espn_stats(nested, cat))
            continue
        label = str(sm.get("label") or sm.get("displayName") or sm.get("name") or "")
        if not label:
            continue
        if category:
            label = f"{category} · {label}"
        value = sm.get("displayValue")
        if value is None:
            value = sm.get("value")
        parsed[label] = "" if value is None else str(value)
    return parsed


def details_from_espn(summary: dict) -> dict:
    boxscore = as_map(summary.get("boxscore"))
    teams = boxscore.get("teams") or []
    home_stats: dict[str, str] = {}
    away_stats: dict[str, str] = {}
    for t in teams:
        m = as_map(t)
        side = str(m.get("homeAway") or "")
        parsed = _flatten_espn_stats(m.get("statistics") or [])
        if side == "home":
            home_stats = parsed
        elif side == "away":
            away_stats = parsed

    labels = list({*home_stats.keys(), *away_stats.keys()})
    stats_rows = [
        {"label": label, "home": home_stats.get(label, ""), "away": away_stats.get(label, "")}
        for label in labels
    ]

    plays_raw = summary.get("plays") or []
    plays: list[dict] = []
    for p in plays_raw:
        pm = as_map(p)
        period_m = as_map(pm.get("period"))
        clock_m = as_map(pm.get("clock"))
        period = str(period_m.get("displayValue") or period_m.get("number") or "")
        clock = str(clock_m.get("displayValue") or "")
        plays.append({"text": str(pm.get("text") or ""), "period": period, "clock": clock})

    return {"stats": stats_rows, "plays": plays}
