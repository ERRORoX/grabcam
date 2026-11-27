#!/usr/bin/env python3
"""Guarded local updater for the safe, documentation/dependency portion of Grabcam.

The updater deliberately refuses a pull when the incoming commit range contains
application/runtime files. This prevents a routine update from silently changing
the project's data-collection runtime.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

OWNER = "ERRORoX"
REPOSITORY = "grabcam"
BRANCH = "Grabcam-V3"
REMOTE = "origin"
SAFE_EXACT = {"requirements.txt", "LICENSE", "LICENSE.md"}
SAFE_PREFIXES = ("README", "CHANGELOG", "docs/", "documentation/")
UPSTREAM = f"https://api.github.com/repos/{OWNER}/{REPOSITORY}/commits/{BRANCH}"


class UpdateError(RuntimeError):
    pass


def git(*args: str, check: bool = True) -> str:
    proc = subprocess.run(
        ["git", *args], text=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, cwd=ROOT
    )
    if check and proc.returncode:
        raise UpdateError(proc.stderr.strip() or f"git {' '.join(args)} failed")
    return proc.stdout.strip()


def run_pip() -> None:
    req = ROOT / "requirements.txt"
    if req.is_file():
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "-r", str(req)],
            cwd=ROOT, check=True
        )


def latest_remote_sha() -> str:
    request = urllib.request.Request(
        UPSTREAM,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "Grabcam-Local-Safe-Updater",
        },
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        data = json.load(response)
    return data["sha"]


def is_safe_path(path: str) -> bool:
    path = path.replace("\\", "/")
    return path in SAFE_EXACT or any(path.startswith(prefix) for prefix in SAFE_PREFIXES)


def status() -> dict:
    current = git("rev-parse", "HEAD")
    remote_sha = latest_remote_sha()
    git("fetch", "--prune", "--quiet", REMOTE, BRANCH)
    behind = int(git("rev-list", "--count", f"HEAD..{REMOTE}/{BRANCH}"))
    return {
        "branch": git("branch", "--show-current"),
        "current_commit": current,
        "remote_commit": remote_sha,
        "commits_behind": behind,
        "update_available": behind > 0,
    }


def update() -> dict:
    branch = git("branch", "--show-current")
    if branch != BRANCH:
        raise UpdateError(
            f"Текущая ветка — {branch or '(detached HEAD)'}. "
            f"Переключитесь на {BRANCH}; updater не меняет ветки автоматически."
        )
    if git("status", "--porcelain"):
        dirty = True
    else:
        dirty = False

    # Keep a named recovery point before touching the working tree.
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup_branch = f"backup/before-safe-update-{stamp}"
    git("branch", backup_branch)

    stash_created = False
    if dirty:
        before = git("rev-parse", "-q", "--verify", "refs/stash", check=False)
        git("stash", "push", "--include-untracked", "-m", f"Grabcam safe update {stamp}")
        after = git("rev-parse", "-q", "--verify", "refs/stash", check=False)
        stash_created = bool(after and after != before)

    try:
        git("fetch", "--prune", "--quiet", REMOTE, BRANCH)
        behind = int(git("rev-list", "--count", f"HEAD..{REMOTE}/{BRANCH}"))
        if behind == 0:
            return {
                "updated": False,
                "message": "Установлена последняя версия.",
                "backup_branch": backup_branch,
                "restart_required": False,
            }

        changed = git(
            "diff", "--name-only", "HEAD", f"{REMOTE}/{BRANCH}"
        ).splitlines()
        blocked = [path for path in changed if not is_safe_path(path)]
        if blocked:
            raise UpdateError(
                "Обновление остановлено: в новых коммитах есть файлы приложения, "
                "которые этот безопасный updater не изменяет: " + ", ".join(blocked)
            )

        git("merge", "--ff-only", f"{REMOTE}/{BRANCH}")
        if stash_created:
            git("stash", "pop")
            stash_created = False

        if "requirements.txt" in changed:
            run_pip()

        return {
            "updated": True,
            "updated_files": changed,
            "backup_branch": backup_branch,
            "commit": git("rev-parse", "HEAD"),
            "restart_required": True,
        }
    finally:
        # If the update was blocked or failed, put the user's local edits back.
        if stash_created:
            git("stash", "pop", check=False)


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "check":
            print(json.dumps(status(), ensure_ascii=False, indent=2))
        elif len(sys.argv) > 1 and sys.argv[1] == "update":
            print(json.dumps(update(), ensure_ascii=False, indent=2))
        else:
            print("Использование: python tools/safe_updater.py check|update")
        return 0
    except (UpdateError, urllib.error.URLError, KeyError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"error": str(exc)}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
