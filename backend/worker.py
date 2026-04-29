import logging
import signal
import threading

from db import init_db
from services.notifications import init_firebase
from services.worker import EspnWorker, FootballWorker, Worker


def start_background_loops(workers: list[Worker]) -> list[threading.Thread]:
    threads: list[threading.Thread] = []
    for w in workers:
        t = threading.Thread(
            target=w.run,
            name=f"{w.name}-events",
            daemon=True,
        )
        t.start()
        threads.append(t)
    return threads


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    )
    init_db()
    init_firebase()

    workers: list[Worker] = [FootballWorker(), EspnWorker()]
    threads = start_background_loops(workers)
    logging.info("worker started with %d loop(s)", len(threads))

    stop = threading.Event()

    def _handle_signal(signum, _frame):
        logging.info("signal %s received, stopping", signum)
        stop.set()

    try:
        signal.signal(signal.SIGINT, _handle_signal)
        signal.signal(signal.SIGTERM, _handle_signal)
    except (AttributeError, ValueError):
        pass

    stop.wait()


if __name__ == "__main__":
    main()
