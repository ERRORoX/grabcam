#!/usr/bin/env python3
"""Loopback-only web UI for Grabcam's guarded updater."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from flask import Flask, jsonify, request, send_file

ROOT = Path(__file__).resolve().parents[1]
UPDATER = ROOT / "tools" / "safe_updater.py"
PAGE = ROOT / "tools" / "updater.html"
HOST = "127.0.0.1"
PORT = 5051

app = Flask(__name__)


def local_request() -> bool:
    if request.remote_addr not in {"127.0.0.1", "::1"}:
        return False
    origin = request.headers.get("Origin")
    if origin and origin not in {f"http://{HOST}:{PORT}", f"http://localhost:{PORT}"}:
        return False
    return True


@app.before_request
def restrict_to_loopback():
    if not local_request():
        return jsonify({"error": "Доступ разрешён только с этого компьютера."}), 403


@app.get("/")
def index():
    return send_file(PAGE)


def run_updater(command: str, timeout: int):
    if not UPDATER.is_file():
        return {"error": "Файл tools/safe_updater.py не найден."}, 404
    try:
        proc = subprocess.run(
            [sys.executable, str(UPDATER), command],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"error": "Операция превысила допустимое время ожидания."}, 504

    raw = proc.stdout.strip() or proc.stderr.strip()
    try:
        payload = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        payload = {"output": raw}

    if proc.returncode:
        payload.setdefault("error", proc.stderr.strip() or "Updater завершился с ошибкой.")
        return payload, 500
    return payload, 200


@app.get("/api/status")
def api_status():
    payload, status_code = run_updater("check", 45)
    return jsonify(payload), status_code


@app.post("/api/update")
def api_update():
    payload, status_code = run_updater("update", 600)
    return jsonify(payload), status_code


if __name__ == "__main__":
    print(f"Grabcam Updater: http://{HOST}:{PORT}")
    print("Доступ только с этого компьютера. Для остановки нажмите Ctrl+C.")
    app.run(host=HOST, port=PORT, debug=False, use_reloader=False)
