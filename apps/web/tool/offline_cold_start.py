#!/usr/bin/env python3
"""Airplane-mode cold start of the installed PWA (WP54), headless Chrome over the W3C WebDriver protocol (stdlib only).

Serves the mock-mode release build (tool/offline_cold_start.sh builds it) from a local static server, then:

  1. loads the app online and waits until our service worker (sw.js) controls the page and its shell cache is filled,
  2. goes offline for real: stops the static server AND turns on Chrome's offline emulation (navigator.onLine=false),
  3. reloads (cold start without network): the shell must render from the cache (landing -> sign-in),
  4. signs in (mock identity, no network needed), picks the academy and opens the live match: the screen must render
     with the offline banner (the match DB opens through sqlite3.wasm and the drift worker, both served from the cache).
     The mock API answers in-process, so the cached-read fallback itself is covered by the unit tests
     (live_match_controller_test, match_store_scope_test), not by this script.

Usage: python3 -I tool/offline_cold_start.py --dir build/offline-check [--port 5174] [--headed]
Needs chromedriver matching Chrome's major version on PATH (or CHROMEDRIVER; CHROME = Chrome binary).
"""
import argparse
import functools
import http.server
import json
import os
import socket
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

LIVE_MATCH = "0190b6a0-0000-7000-8000-00000000c001"  # MockGameApi.liveMatchId
SIGN_IN = ("Iniciar sesión", "Sign in", "Masuk")
OFFLINE_BANNER = ("sin conexión", "offline", "luring")

SCREEN_TEXTS = """
const p = document.querySelector('flt-semantics-placeholder');
if (p) p.click();
return [...document.querySelectorAll('flt-semantics')]
  .filter(e => !e.querySelector('flt-semantics'))
  .map(e => (e.getAttribute('aria-label') || e.textContent || '').trim())
  .filter(Boolean);
"""
CLICK_LABEL = """
const labels = arguments[0];
const p = document.querySelector('flt-semantics-placeholder');
if (p) { p.click(); return null; }
for (const el of document.querySelectorAll('[role="button"]')) {
  const t = (el.getAttribute('aria-label') || el.textContent || '').trim();
  if (labels.some(l => t.includes(l))) { el.click(); return t; }
}
return null;
"""
SW_READY = """
const done = arguments[arguments.length - 1];
if (!navigator.serviceWorker) return done('no-sw');
navigator.serviceWorker.ready.then(async reg => {
  const names = await caches.keys();
  const shell = names.find(n => n.startsWith('hoops-shell-'));
  const n = shell ? (await (await caches.open(shell)).keys()).length : 0;
  done({controlled: !!navigator.serviceWorker.controller, cached: n, script: reg.active && reg.active.scriptURL});
});
"""


class WebDriver:
    def __init__(self, port, headed):
        self.base = f"http://127.0.0.1:{port}"
        args = ["--window-size=390,844", "--no-first-run", "--lang=es"]
        if not headed:
            args += ["--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
        opts = {"args": args}
        if os.environ.get("CHROME"):
            opts["binary"] = os.environ["CHROME"]
        caps = {"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": opts}}}
        self.session = self._call("POST", "/session", caps)["sessionId"]

    def _call(self, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method,
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.load(resp)["value"]
        except urllib.error.HTTPError as err:
            raise RuntimeError(f"webdriver {method} {path}: {err.read().decode()[:300]}") from None

    def cmd(self, method, path, body=None):
        return self._call(method, f"/session/{self.session}{path}", body)

    def js(self, script, *args):
        return self.cmd("POST", "/execute/sync", {"script": script, "args": list(args)})

    def js_async(self, script, *args):
        return self.cmd("POST", "/execute/async", {"script": script, "args": list(args)})

    def quit(self):
        try:
            self._call("DELETE", f"/session/{self.session}")
        except Exception:  # noqa: BLE001 - best effort
            pass


def wait_for(what, predicate, timeout, interval=1.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    raise TimeoutError(what)


def texts(wd):
    return wd.js(SCREEN_TEXTS) or []


def has(wd, labels):
    return any(l.lower() in t.lower() for t in texts(wd) for l in labels)


def click(wd, labels):
    return wd.js(CLICK_LABEL, list(labels))


def serve(directory, port):
    class Quiet(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *args):
            pass

    handler = functools.partial(Quiet, directory=directory)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default="build/offline-check")
    ap.add_argument("--port", type=int, default=5174)
    ap.add_argument("--headed", action="store_true")
    ap.add_argument("--boot-timeout", type=int, default=120)
    opts = ap.parse_args()
    app = f"http://localhost:{opts.port}/"

    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    driver_proc = subprocess.Popen([os.environ.get("CHROMEDRIVER", "chromedriver"), f"--port={port}"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    server = serve(os.path.abspath(opts.dir), opts.port)
    wd = None
    try:
        wait_for("chromedriver", lambda: _up(port), 15, 0.3)
        wd = WebDriver(port, opts.headed)

        print("1/4 online: load the app, wait for the service worker to control the page and fill its cache")
        wd.cmd("POST", "/url", {"url": app})
        wait_for("landing renders", lambda: has(wd, SIGN_IN), opts.boot_timeout)
        state = wait_for("sw ready", lambda: _sw(wd), 60)
        wd.cmd("POST", "/url", {"url": app})  # the first load is not controlled; the second is
        state = wait_for("page controlled by sw.js", lambda: _sw(wd) if _sw(wd).get("controlled") else None, 60)
        assert state["cached"] > 100, f"shell cache too small: {state}"
        print(f"    ok: {state['script']} controls the page, {state['cached']} files cached")

        print("2/4 airplane mode: static server stopped + Chrome offline emulation")
        server.shutdown()
        server.server_close()
        wd.cmd("POST", "/chromium/network_conditions", {"network_conditions": {
            "offline": True, "latency": 0, "download_throughput": -1, "upload_throughput": -1}})
        try:
            urllib.request.urlopen(app, timeout=3)
            raise AssertionError("server still answering: not offline")
        except (urllib.error.URLError, ConnectionError, OSError):
            pass

        print("3/4 cold start without network: reload")
        wd.cmd("POST", "/url", {"url": app})
        wait_for("shell renders offline", lambda: has(wd, SIGN_IN), opts.boot_timeout)
        print("    ok: the landing renders from the cache")

        print("4/4 sign in (mock identity), pick the academy, open the live match")
        wait_for("sign-in tap", lambda: click(wd, SIGN_IN), 30, 0.5)  # landing -> login
        time.sleep(1)
        wait_for("login screen -> sign-in", lambda: has(wd, ("Elige tu academia",)) or click(wd, SIGN_IN), 30, 0.5)
        wait_for("academy picker", lambda: has(wd, ("Elige tu academia",)), 30, 0.5)
        wait_for("pick the academy", lambda: click(wd, ("Academia Demo",)), 30, 0.5)
        wait_for("signed in", lambda: not has(wd, ("Elige tu academia",)) and texts(wd), 30, 0.5)
        wd.js(f"location.hash = '#/matches/{LIVE_MATCH}';")
        wait_for("live match renders", lambda: has(wd, ("Tigres", "Cancha", "Court", "Lapangan")), 60)
        print("    ok: the live match screen renders offline")
        if not has(wd, OFFLINE_BANNER):
            raise AssertionError(f"no offline banner on screen: {texts(wd)[:40]}")
        print("OK: offline cold start")
    except BaseException:
        if wd is not None:
            try:
                print("screen texts:", texts(wd)[:60], file=sys.stderr)
            except Exception:  # noqa: BLE001
                pass
        raise
    finally:
        if wd is not None:
            wd.quit()
        driver_proc.terminate()


def _sw(wd):
    return wd.js_async(SW_READY)


def _up(port):
    try:
        urllib.request.urlopen(f"http://127.0.0.1:{port}/status", timeout=1)
        return True
    except OSError:
        return False


if __name__ == "__main__":
    main()
