import time

class Timer:
    def __init__(self):
        self._start_time = None
        self._elapsed = 0
        self._running = False

    def start(self):
        if not self._running:
            self._start_time = int(time.monotonic())
            self._running = True

    def pause(self):
        if self._running:
            self._elapsed += int(time.monotonic()) - self._start_time
            self._running = False

    def resume(self):
        if not self._running:
            self._start_time = int(time.monotonic())
            self._running = True

    def reset(self):
        self._start_time = None
        self._elapsed = 0
        self._running = False

    def elapsed(self):
        if self._running:
            return self._elapsed + (int(time.monotonic()) - self._start_time)
        else:
            return self._elapsed

    def elapsed_pp_string(self):
        if self._running:
            elapsed = self._elapsed + (int(time.monotonic()) - self._start_time)
        else:
            elapsed = self._elapsed

        total_seconds = elapsed# // 1000

        days = total_seconds // (24 * 3600)
        total_seconds %= (24 * 3600)

        hours = total_seconds // 3600
        total_seconds %= 3600

        minutes = total_seconds // 60
        seconds = total_seconds % 60

        return f"{days} days, {hours} hours, {minutes} minutes, {seconds} seconds"
