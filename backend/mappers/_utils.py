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


def as_int(v, default=0):
    if isinstance(v, int):
        return v
    if isinstance(v, float):
        return int(v)
    if isinstance(v, str):
        try:
            return int(v)
        except ValueError:
            return default
    return default


def as_opt_int(v):
    if isinstance(v, int):
        return v
    if isinstance(v, float):
        return int(v)
    if isinstance(v, str):
        try:
            return int(v)
        except ValueError:
            return None
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
    if state == "post":
        if "postpone" in name:
            return STATUS_POSTPONED
        if "cancel" in name:
            return STATUS_CANCELLED
        return STATUS_FINISHED
    return STATUS_UNKNOWN
