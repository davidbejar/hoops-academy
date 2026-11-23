"""The W3C WebDriver client and the small helpers the browser checks share (stdlib only, no Node, no selenium).

Used by `browser_login_check.py`, `offline_cold_start.py` and `excel_on_demand_check.py`. Chrome flags (the pinned
Chrome for Testing of CI is selected with CHROME) are set here, once.
"""
import base64
import functools
import http.server
import json
import os
import threading
import time
import urllib.error
import urllib.request

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


class WebDriver:
    def __init__(self, port, headed):
        self.base = f"http://127.0.0.1:{port}"
        args = ["--window-size=390,844", "--no-first-run", "--lang=es"]
        if not headed:
            args += ["--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
        chrome_options = {"args": args}
        if os.environ.get("CHROME"):  # binary to drive (CI: the pinned Chrome for Testing); default: chromedriver's lookup
            chrome_options["binary"] = os.environ["CHROME"]
        caps = {"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": chrome_options}}}
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

    def get(self, url):
        self.cmd("POST", "/url", {"url": url})

    def url(self):
        return self.cmd("GET", "/url")

    def js(self, script, *args):
        return self.cmd("POST", "/execute/sync", {"script": script, "args": list(args)})

    def js_async(self, script, *args):
        return self.cmd("POST", "/execute/async", {"script": script, "args": list(args)})

    def save_screenshot(self, path):
        with open(path, "wb") as out:
            out.write(base64.b64decode(self.cmd("GET", "/screenshot")))

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


def driver_up(port):
    """True once chromedriver on [port] reports it is ready for a session."""
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/status", timeout=1) as r:
            return json.load(r)["value"]["ready"]
    except Exception:  # noqa: BLE001
        return False


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
