from config import (
    FOOTBALL_STATUS_MAP,
    STATUS_CANCELLED,
    STATUS_FINISHED,
    STATUS_LIVE,
    STATUS_POSTPONED,
    STATUS_UNKNOWN,
    STATUS_UPCOMING,
)


def as_map(v):
    return v if isinstance(v, dict) else {}


def as_int(v):
    try:
        return int(v)
    except Exception:
        return 0


def as_opt_int(v):
    try:
        return int(v)
    except Exception:
        return None


def venue_str(name: str, city: str) -> str:
    return ", ".join(s for s in [name, city] if s)


def football_status(code: str) -> str:
    return FOOTBALL_STATUS_MAP.get(code, STATUS_UNKNOWN)


def espn_status(status_type: dict) -> str:
    state = (status_type.get("state") or "").lower()
    name = (status_type.get("name") or "").lower()
    if state == "pre":
        return STATUS_UPCOMING
    if state == "in":
        return STATUS_LIVE
    if state != "post":
        return STATUS_UNKNOWN
    if "postpone" in name:
        return STATUS_POSTPONED
    if "cancel" in name:
        return STATUS_CANCELLED
    return STATUS_FINISHED


def espn_date(d) -> str:
    return d.strftime("%Y%m%d")
