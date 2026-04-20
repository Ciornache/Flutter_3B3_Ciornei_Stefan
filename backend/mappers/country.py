from config import COUNTRY_CONTINENT


def country_from_football(d: dict) -> dict:
    code = (d.get("code") or "").strip()
    return {
        "id": code or d.get("name", ""),
        "name": d.get("name", ""),
        "code": code,
        "flag": d.get("flag", "") or "",
        "continent": COUNTRY_CONTINENT.get(code, ""),
    }
