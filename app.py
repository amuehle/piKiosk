#!/usr/bin/python3

from PySide2.QtWidgets import QApplication
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtWebEngine import QtWebEngine

import dbus.mainloop.glib
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

import threading
import sys
import os


from mainpage import MainPage
from setuppage import SetupPage
from config import settings
import web
import scheduler

os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"


QtWebEngine.initialize()
app = QApplication()
engine = QQmlApplicationEngine()

setuppage = SetupPage()
engine.rootContext().setContextProperty("settingsbackend", setuppage)

if not settings.has_option("FIRSTRUN") or settings.get("FIRSTRUN"):
    engine.load("qml/setup.qml")
    sys.exit(app.exec_())

mainpage = MainPage()

engine.rootContext().setContextProperty("backend", mainpage)

engine.load("qml/main.qml")

threading.Thread(target=lambda: web.wsgi.start()).start()

sys.exit(app.exec_())