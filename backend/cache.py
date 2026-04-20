import time
from threading import Lock

_store: dict[str, tuple[float, object]] = {}
_lock = Lock()


def get(key: str, ttl: float):
    with _lock:
        hit = _store.get(key)
        if not hit:
            return None
        ts, value = hit
        if time.time() - ts > ttl:
            _store.pop(key, None)
            return None
        return value


def put(key: str, value: object) -> None:
    with _lock:
        _store[key] = (time.time(), value)


def invalidate(prefix: str = "") -> None:
    with _lock:
        if not prefix:
            _store.clear()
            return
        for k in [k for k in _store if k.startswith(prefix)]:
            _store.pop(k, None)
