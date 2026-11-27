#!/usr/bin/env python3
"""Privacy-preserving local diagnostics for the Grabcam application.

This module records application/server failures only. It does not collect visitor
identifiers, IP addresses, request bodies, credentials, media, location, or
browser fingerprints.
"""
from __future__ import annotations

import sqlite3
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DB_PATH = DATA_DIR / "analytics_diagnostics.sqlite3"
_STARTED_AT = time.time()
_LOCK = threading.Lock()


def _connect() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH), timeout=10)
    conn.row_factory = sqlite3.Row
    return conn


def initialize() -> None:
    with _LOCK, _connect() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS server_errors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                occurred_at TEXT NOT NULL,
                endpoint TEXT NOT NULL,
                status_code INTEGER NOT NULL
            )
        """)
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_server_errors_time "
            "ON server_errors(occurred_at)"
        )
        conn.commit()


def record_server_error(endpoint: str | None, status_code: int) -> None:
    """Store only an endpoint name and HTTP status; never store request data."""
    safe_endpoint = (endpoint or "unknown").split(".", 1)[0][:80]
    occurred_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    with _LOCK, _connect() as conn:
        conn.execute(
            "INSERT INTO server_errors(occurred_at, endpoint, status_code) "
            "VALUES (?, ?, ?)",
            (occurred_at, safe_endpoint, int(status_code)),
        )
        # Keep a bounded 90-day diagnostic history.
        conn.execute(
            "DELETE FROM server_errors WHERE occurred_at < datetime('now', '-90 days')"
        )
        conn.commit()


def summary() -> dict[str, Any]:
    now = time.time()
    with _LOCK, _connect() as conn:
        total = conn.execute("SELECT COUNT(*) FROM server_errors").fetchone()[0]
        last_24h = conn.execute(
            "SELECT COUNT(*) FROM server_errors "
            "WHERE occurred_at >= datetime('now', '-1 day')"
        ).fetchone()[0]
        last_7d = conn.execute(
            "SELECT COUNT(*) FROM server_errors "
            "WHERE occurred_at >= datetime('now', '-7 days')"
        ).fetchone()[0]
        by_status = conn.execute(
            "SELECT status_code, COUNT(*) AS count FROM server_errors "
            "GROUP BY status_code ORDER BY status_code"
        ).fetchall()
        by_endpoint = conn.execute(
            "SELECT endpoint, COUNT(*) AS count FROM server_errors "
            "GROUP BY endpoint ORDER BY count DESC LIMIT 10"
        ).fetchall()
        recent = conn.execute(
            "SELECT occurred_at, endpoint, status_code FROM server_errors "
            "ORDER BY id DESC LIMIT 20"
        ).fetchall()
    return {
        "uptime_seconds": max(0, int(now - _STARTED_AT)),
        "started_at_utc": datetime.fromtimestamp(_STARTED_AT, timezone.utc).strftime("%Y-%m-%d %H:%M:%S"),
        "server_errors_total": int(total),
        "server_errors_24h": int(last_24h),
        "server_errors_7d": int(last_7d),
        "errors_by_status": [
            {"status_code": int(row["status_code"]), "count": int(row["count"])}
            for row in by_status
        ],
        "errors_by_endpoint": [
            {"endpoint": row["endpoint"], "count": int(row["count"])}
            for row in by_endpoint
        ],
        "recent_errors": [dict(row) for row in recent],
        "privacy": {
            "stores_ip_addresses": False,
            "stores_request_bodies": False,
            "stores_credentials_or_media": False,
            "retention_days": 90,
        },
    }


initialize()
