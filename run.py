#!/usr/bin/env python3
"""
Запуск Grabcam без OSINT Panel.
Запуск из корня grabcam: python run_standalone.py
Или: python tools/grabcam/run_standalone.py (из корня проекта)
Автор: ERRORoX
"""
import os
import sys

_GRABCAM_DIR = os.path.dirname(os.path.abspath(__file__))
_STANDALONE_DIR = os.path.join(_GRABCAM_DIR, "standalone")
sys.path.insert(0, _STANDALONE_DIR)
os.chdir(_STANDALONE_DIR)

# Запуск приложения
from app import app

if __name__ == "__main__":
    print("Grabcam (автономный режим)")
    print("Откройте в браузере: http://127.0.0.1:5050")
    print("Выход: Ctrl+C")
    app.run(host="0.0.0.0", port=5050, debug=False)
