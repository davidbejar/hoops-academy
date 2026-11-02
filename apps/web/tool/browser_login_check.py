#!/usr/bin/env python3
"""Real-browser login round trip: app -> Keycloak form -> back to the app (signed in).

Covers the part `integration_test/login_smoke_test.dart` cannot reach (the Keycloak form is another page), with
headless Chrome driven over the W3C WebDriver HTTP protocol (stdlib only, no Node, no selenium):

  1. open the app, enable Flutter's semantics tree and tap the sign-in button,
  2. fill the Keycloak form (user, password from DEV_USER_PASSWORD in the repo .env; never printed),
  3. require the tab to come back to the app, not to stay on redirect.html ("You can now close this tab ..."),
     and the app to hold a signed-in session (sign-in button gone).

Needs: compose stack up + `just seed-users`, the app served on an origin the realm's `web` client allows
(http://localhost:5173 via `flutter run`/start.sh), chromedriver matching Chrome's major version on PATH.

  python3 -I apps/web/tool/browser_login_check.py [--app http://localhost:5173/] [--user coach1@hoops-academy.com] [--headed]
"""
import argparse
import json
import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SIGN_IN_LABELS = ("Iniciar sesión", "Sign in", "Masuk")
STRANDED_TEXT = "close this tab"


def dev_password():
    if os.environ.get("HOOPS_E2E_PASSWORD"):
        return os.environ["HOOPS_E2E_PASSWORD"]
    with open(os.path.join(ROOT, ".env"), encoding="utf-8") as env:
        for line in env:
            if line.startswith("DEV_USER_PASSWORD="):
                return line.split("=", 1)[1].strip()
    sys.exit("set HOOPS_E2E_PASSWORD or DEV_USER_PASSWORD in .env")


class WebDriver:
    def __init__(self, port, headed):
        self.base = f"http://127.0.0.1:{port}"
        args = ["--window-size=390,844", "--no-first-run", "--lang=es"]
        if not headed:
            args += ["--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
        caps = {"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": {"args": args}}}}
        self.session = self._call("POST", "/session", caps)["sessionId"]

    def _call(self, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method,
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.load(resp)["value"]
        except urllib.error.HTTPError as err:
            raise RuntimeError(f"webdriver {method} {path}: {err.read().decode()[:300]}") from None

    def cmd(self, method, path, body=None):
        return self._call(method, f"/session/{self.session}{path}", body)

    def get(self, url):
        self.cmd("POST", "/url", {"url": url})

    def url(self):
        return self.cmd("GET", "/url")

    def js(self, script, *args):
        return self.cmd("POST", "/execute/sync", {"script": script, "args": list(args)})

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


CLICK_SIGN_IN = """
const labels = arguments[0];
const ph = document.querySelector('flt-semantics-placeholder');
if (ph) { ph.click(); return 'enabling-semantics'; }
for (const el of document.querySelectorAll('flt-semantics[role="button"], [role="button"]')) {
  const text = (el.getAttribute('aria-label') || el.textContent || '').trim();
  if (labels.some(l => text.includes(l))) { el.click(); return 'clicked'; }
}
return null;
"""

SIGN_OUT_LABELS = ("Cerrar sesión", "Sign out", "Keluar")

CLICK_BUTTON = """
const labels = arguments[0];
for (const el of document.querySelectorAll('[role="button"]')) {
  const text = (el.getAttribute('aria-label') || el.textContent || '').trim();
  if (labels.some(l => text === l || text.includes(l))) { el.click(); return 'clicked'; }
}
return null;
"""


SCREEN_TEXTS = """
const p = document.querySelector('flt-semantics-placeholder');
if (p) p.click();
return [...document.querySelectorAll('flt-semantics')]
  .filter(e => !e.querySelector('flt-semantics'))
  .map(e => (e.getAttribute('aria-label') || e.textContent || '').trim())
  .filter(Boolean);
"""


def _screen_texts(wd):
    return wd.js(SCREEN_TEXTS) or []


def _signed_in_texts(wd):
    texts = _screen_texts(wd)
    if texts and not any(l in t for t in texts for l in SIGN_IN_LABELS):
        return texts
    return None


def _sign_in_visible(wd):
    wd.js("const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click();")
    return wd.js(SIGN_IN_VISIBLE, list(SIGN_IN_LABELS))


SIGN_IN_VISIBLE = """
const labels = arguments[0];
return [...document.querySelectorAll('[role="button"]')].some(el =>
  labels.some(l => ((el.getAttribute('aria-label') || el.textContent || '')).includes(l)));
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--app", default="http://localhost:5173/")
    ap.add_argument("--user", default="coach1@hoops-academy.com")
    ap.add_argument("--headed", action="store_true")
    ap.add_argument("--boot-timeout", type=int, default=240, help="seconds; a debug (DDC) build boots slowly")
    opts = ap.parse_args()
    app_origin = opts.app.rstrip("/")
    password = dev_password()

    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    driver_proc = subprocess.Popen([os.environ.get("CHROMEDRIVER", "chromedriver"), f"--port={port}"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    wd = None
    try:
        wait_for("chromedriver", lambda: _up(port), 15, 0.3)
        wd = WebDriver(port, opts.headed)

        print(f"1/5 open {opts.app} and tap sign-in (boot timeout {opts.boot_timeout}s)")
        wd.get(opts.app)
        wait_for("sign-in button in the semantics tree",
                 lambda: wd.js(CLICK_SIGN_IN, list(SIGN_IN_LABELS)) == "clicked", opts.boot_timeout, 2)

        print("2/5 Keycloak login form")
        wait_for("Keycloak form", lambda: wd.js("return !!document.getElementById('kc-login')"), 60)
        print(f"    at {wd.url().split('?')[0]}")
        if not wd.js("return [...document.querySelectorAll('link[rel=stylesheet]')]"
                     ".some(l => l.href.includes('/login/hoops/css/hoops.css'))"):
            print("FAIL: Keycloak serves its stock login page, not the branded `hoops` theme (ADR-0022)")
            return 1
        print("    branded login theme `hoops`")
        wd.js("""document.getElementById('username').value = arguments[0];
                 document.getElementById('password').value = arguments[1];
                 document.getElementById('kc-login').click();""", opts.user, password)

        print(f"3/5 back to the app as {opts.user}")
        seen = []

        def back_in_app():
            u = wd.url()
            if not seen or seen[-1] != u.split("?")[0]:
                seen.append(u.split("?")[0])
            return u.startswith(app_origin) and "redirect.html" not in u and "/auth/" not in u

        try:
            wait_for("return to the app", back_in_app, 45)
        except TimeoutError:
            body = wd.js("return document.body ? document.body.innerText : ''") or ""
            stranded = " (stranded: page says '...close this tab...')" if STRANDED_TEXT in body else ""
            print(f"FAIL: tab did not return to the app{stranded}; URLs: {' -> '.join(seen)}")
            return 1
        print(f"    at {wd.url()}")

        print("4/5 signed in: a rendered screen without the sign-in button")
        # The page reloaded: a new Flutter instance, semantics off again. Require real content before judging,
        # otherwise an empty (not yet built) tree would pass as "sign-in button gone".
        try:
            texts = wait_for("signed-in screen", lambda: _signed_in_texts(wd), opts.boot_timeout, 2)
        except TimeoutError:
            print(f"FAIL: back in the app but still on the sign-in screen or nothing rendered: {_screen_texts(wd)}")
            return 1
        print(f"    OK: login round trip stays in the app; screen shows {texts[:6]}")

        print("5/5 sign out returns to the app's sign-in screen (when a sign-out button is on this screen)")
        if wd.js(CLICK_BUTTON, list(SIGN_OUT_LABELS)) != "clicked":
            labels = wd.js("return [...document.querySelectorAll('[role=\"button\"],[role=\"link\"],[role=\"tab\"]')]"
                           ".map(e => (e.getAttribute('aria-label') || e.textContent || '').trim()).filter(Boolean)")
            print(f"    SKIP: no sign-out button on the landing screen of this user (buttons: {labels})")
            return 0
        seen.clear()
        try:
            wait_for("sign-in screen after sign-out", lambda: back_in_app() and _sign_in_visible(wd), 45, 2)
        except TimeoutError:
            body = wd.js("return document.body ? document.body.innerText : ''") or ""
            stranded = " (stranded: page says '...close this tab...')" if STRANDED_TEXT in body else ""
            print(f"FAIL: sign-out did not come back to the app's sign-in screen{stranded}; URLs: {' -> '.join(seen)}")
            return 1
        print(f"    OK: signed out, at {wd.url()}")
        return 0
    finally:
        if wd:
            wd.quit()
        driver_proc.terminate()


def _up(port):
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/status", timeout=1) as r:
            return json.load(r)["value"]["ready"]
    except Exception:  # noqa: BLE001
        return False


if __name__ == "__main__":
    sys.exit(main())
