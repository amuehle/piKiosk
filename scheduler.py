from Xlib import display
from Xlib.ext import dpms
from datetime import datetime
import threading
import time
from config import settings
import holidays

class DisplayScheduler:
    def __init__(self, schedule_provider, holiday_provider, check_interval=60):
        """
        :param schedule_provider: callable returning the current schedule dict
        :param holiday_provider: callable returning (country, subdivision)
        :param check_interval: seconds between checks
        """
        self.schedule_provider = schedule_provider
        self.holiday_provider = holiday_provider
        self.check_interval = check_interval
        self._thread = None
        self._stop = threading.Event()
        self.d = display.Display()
        self.current_state = None  # "on" or "off"

    def start(self):
        if self._thread and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._stop.set()
        if self._thread:
            self._thread.join()

    def _set_display_power(self, on: bool):
        mode = dpms.DPMSModeOn if on else dpms.DPMSModeOff
        dpms.force_level(self.d, mode)
        self.d.sync()
        self.current_state = "on" if on else "off"

    def _is_holiday_today(self):
        country, subdiv = self.holiday_provider()
        if not country:
            return False
        try:
            today = datetime.now().date()
            country_holidays = holidays.country_holidays(country, subdiv=subdiv)
            return today in country_holidays
        except Exception:
            return False

    def _run_loop(self):
        while not self._stop.is_set():
            now = datetime.now()
            day = now.strftime("%a").lower()[:3]  # mon, tue, ...
            current = now.strftime("%H:%M")

            # get configs
            schedule = self.schedule_provider() or {}
            day_sched = schedule.get(day)
            is_holiday = self._is_holiday_today()

            if is_holiday:
                # Force display off on holidays
                if self.current_state != "off":
                    self._set_display_power(False)
            elif day_sched:
                start = day_sched.get("start", "")
                end = day_sched.get("end", "")

                if start and end:
                    if self._is_between(current, start, end):
                        if self.current_state != "on":
                            self._set_display_power(True)
                    else:
                        if self.current_state != "off":
                            self._set_display_power(False)

            time.sleep(self.check_interval)

    def _is_between(self, now_str, start, end):
        #Check if now_str (HH:MM) is within [start, end]. Handles overnight.
        now = int(now_str.replace(":", ""))
        s = int(start.replace(":", ""))
        e = int(end.replace(":", ""))

        if s <= e:  # same day
            return s <= now <= e
        else:  # overnight (e.g. 22:00–06:00)
            return now >= s or now <= e

    def get_state(self):
        return self.current_state

    def get_today_schedule(self):
        #Return today's start/end dict, e.g. {'start': '08:00', 'end': '18:00'} or None.
        schedule = self.schedule_provider() or {}
        day = datetime.now().strftime("%a").lower()[:3]
        return schedule.get(day)

    def get_next_change(self):
        #Return the next time today the display will switch state, or None if no schedule.
        sched = self.get_today_schedule()
        if not sched or not sched.get("start") or not sched.get("end"):
            return None

        now = int(datetime.now().strftime("%H%M"))
        s = int(sched["start"].replace(":", ""))
        e = int(sched["end"].replace(":", ""))

        if s <= e:  # same day
            if now < s:
                return sched["start"]
            elif now < e:
                return sched["end"]
        else:  # overnight (e.g. 22:00–06:00)
            if now < e:
                return sched["end"]
            elif now < s:
                return sched["start"]

        return None

scheduler = DisplayScheduler(
    lambda: settings.get("DISPLAY_SCHEDULE", {}),
    lambda: (settings.get("HOLIDAY_COUNTRY", ""),
    settings.get("HOLIDAY_SUBDIV", ""))
)
scheduler.start()
