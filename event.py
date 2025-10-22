class Event:
    def __init__(self):
        self._handlers = []

    def attach(self, handler):
        if handler not in self._handlers:
            self._handlers.append(handler)

    def detach(self, handler):
        if handler in self._handlers:
            self._handlers.remove(handler)

    def fire(self, *args, **kwargs):
        for handler in self._handlers:
            handler(*args, **kwargs)

event = Event()