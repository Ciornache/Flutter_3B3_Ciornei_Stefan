from mappers._utils import as_map


def league_from_football(d: dict) -> dict:
    league = as_map(d.get("league"))
    country = as_map(d.get("country"))
    return {
        "id": str(league.get("id", "")),
        "name": league.get("name", ""),
        "logo": league.get("logo", "") or "",
        "type": league.get("type", "League"),
        "sportId": "football",
        "countryId": country.get("code") or country.get("name") or None,
    }


def league_from_seed(seed: dict) -> dict:
    return {
        "id": seed["id"],
        "name": seed["name"],
        "logo": seed["logo"],
        "type": "League",
        "sportId": seed["sport_id"],
        "countryId": None,
    }
