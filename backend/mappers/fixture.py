from config import STATUS_UPCOMING
from mappers._utils import (
    as_int,
    as_map,
    as_opt_int,
    espn_status,
    football_status,
    venue_str,
)


def fixture_from_football(j: dict, country_resolver) -> dict:
    base = as_map(j.get("fixture") or j.get("game") or j)
    league = as_map(j.get("league"))
    teams = as_map(j.get("teams"))
    goals = as_map(j.get("goals") or j.get("scores"))
    status_map = as_map(base.get("status"))

    raw_country = league.get("country")
    raw = ""
    if isinstance(raw_country, dict):
        raw = raw_country.get("code") or raw_country.get("name") or ""
    elif isinstance(raw_country, str):
        raw = raw_country

    code, continent = country_resolver(raw)

    home = as_map(teams.get("home"))
    away = as_map(teams.get("away"))
    venue = as_map(base.get("venue"))
    status = football_status(status_map.get("short", ""))

    def _score(v):
        if isinstance(v, dict):
            return as_opt_int(v.get("total") or v.get("score"))
        return as_opt_int(v)

    return {
        "id": as_int(base.get("id")),
        "sport": "football",
        "date": base.get("date"),
        "leagueId": str(league.get("id", "")),
        "leagueName": league.get("name", ""),
        "leagueLogo": league.get("logo", "") or "",
        "countryCode": code,
        "continent": continent,
        "statusText": status_map.get("long", "") or "",
        "status": status,
        "venue": venue_str(venue.get("name") or "", venue.get("city") or ""),
        "homeTeamId": as_int(home.get("id")),
        "homeTeamName": home.get("name", ""),
        "homeTeamLogo": home.get("logo", "") or "",
        "awayTeamId": as_int(away.get("id")),
        "awayTeamName": away.get("name", ""),
        "awayTeamLogo": away.get("logo", "") or "",
        "homeScore": None if status == STATUS_UPCOMING else _score(goals.get("home")),
        "awayScore": None if status == STATUS_UPCOMING else _score(goals.get("away")),
    }


def fixture_from_espn(event: dict, sport_id: str, league: dict) -> dict:
    competitions = event.get("competitions") or []
    comp = as_map(competitions[0] if competitions else {})
    competitors = comp.get("competitors") or []

    def side(which: str) -> dict:
        for c in competitors:
            m = as_map(c)
            if m.get("homeAway") == which:
                return m
        return {}

    home_c = side("home")
    away_c = side("away")
    home_team = as_map(home_c.get("team"))
    away_team = as_map(away_c.get("team"))
    status_type = as_map(as_map(comp.get("status")).get("type"))
    status = espn_status(status_type)
    venue_map = as_map(comp.get("venue"))
    venue_addr = as_map(venue_map.get("address"))
    venue = venue_str(venue_map.get("fullName") or "", venue_addr.get("city") or "")

    return {
        "id": as_int(event.get("id")),
        "sport": sport_id,
        "date": event.get("date"),
        "leagueId": league["id"],
        "leagueName": league["name"],
        "leagueLogo": league["logo"],
        "countryCode": "",
        "continent": "",
        "statusText": status_type.get("description") or status_type.get("detail") or "",
        "status": status,
        "venue": venue,
        "homeTeamId": as_int(home_team.get("id")),
        "homeTeamName": home_team.get("displayName") or home_team.get("name") or "",
        "homeTeamLogo": home_team.get("logo") or "",
        "awayTeamId": as_int(away_team.get("id")),
        "awayTeamName": away_team.get("displayName") or away_team.get("name") or "",
        "awayTeamLogo": away_team.get("logo") or "",
        "homeScore": None if status == STATUS_UPCOMING else as_opt_int(home_c.get("score")),
        "awayScore": None if status == STATUS_UPCOMING else as_opt_int(away_c.get("score")),
    }
