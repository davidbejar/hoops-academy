"""scripts/lib/oidc-login.sh: the one browser-less authorization-code + PKCE sign-in of client `web` the shell scripts
source (INF-02; it was copied into events-backfill.sh, seed-academy.sh, smoke.sh and keycloak_login_check.sh).

A stub Keycloak (auth endpoint with the login form, the form's action, the token endpoint) checks what the helper sends:
S256 challenge that matches the verifier, the state it gets back, credentials URL-encoded in the body.
Run: python3 -I -m unittest discover -s scripts/tests"""
import base64
import hashlib
import http.server
import json
import pathlib
import re
import subprocess
import threading
import unittest
import urllib.parse

ROOT = pathlib.Path(__file__).resolve().parents[2]
HELPER = ROOT / "scripts/lib/oidc-login.sh"
REALM = "/auth/realms/academy"
PASSWORD = "p&ss w+rd%=;'\"x"  # every character that breaks a hand-built form body


class StubKeycloak(http.server.BaseHTTPRequestHandler):
    """Behaviour is switched by the server's `mode`: ok, wrong-password, rate-limited, bad-state, no-form."""

    def log_message(self, *args):
        pass

    def reply(self, status, body=b"", headers=()):
        self.send_response(status)
        for k, v in headers:
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urllib.parse.urlsplit(self.path)
        q = dict(urllib.parse.parse_qsl(url.query))
        srv = self.server
        if url.path != REALM + "/protocol/openid-connect/auth":
            return self.reply(404)
        if srv.mode == "rate-limited":
            return self.reply(429)
        srv.auth = q
        if srv.mode == "no-form":
            return self.reply(200, b"<html>We are sorry, invalid redirect_uri</html>")
        action = f"http://127.0.0.1:{srv.server_port}{REALM}/login-actions/authenticate?session_code=s1&amp;execution=e1"
        form = f'<form id="kc-form-login" onsubmit="x"\n class="f" action="{action}" method="post"></form>'
        self.reply(200, form.encode(), [("Set-Cookie", "AUTH_SESSION_ID=a1; Path=/")])

    def do_POST(self):
        url = urllib.parse.urlsplit(self.path)
        body = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        form = dict(urllib.parse.parse_qsl(body, keep_blank_values=True))
        srv = self.server
        if url.path == REALM + "/login-actions/authenticate":
            srv.login = {"query": dict(urllib.parse.parse_qsl(url.query)), "form": form,
                         "cookie": self.headers.get("Cookie", "")}
            if srv.mode == "wrong-password" or form.get("password") != PASSWORD:
                return self.reply(200, b'<form id="kc-form-login" action="again"></form>')
            state = "forged" if srv.mode == "bad-state" else srv.auth["state"]
            loc = f'{srv.auth["redirect_uri"]}?state={state}&session_state=x&code=c0de'
            return self.reply(302, headers=[("Location", loc)])
        if url.path == REALM + "/protocol/openid-connect/token":
            srv.token = form
            challenge = base64.urlsafe_b64encode(hashlib.sha256(form["code_verifier"].encode()).digest()).rstrip(b"=")
            if form.get("code") != "c0de" or challenge.decode() != srv.auth["code_challenge"]:
                return self.reply(400, b'{"error":"invalid_grant"}')
            tokens = {"access_token": "acc.ess.tok", "expires_in": 300, "refresh_token": "ref.resh.tok"}
            return self.reply(200, json.dumps(tokens).encode(), [("Content-Type", "application/json")])
        self.reply(404)


class OidcLogin(unittest.TestCase):
    def setUp(self):
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), StubKeycloak)
        self.server.mode = "ok"
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.issuer = f"http://127.0.0.1:{self.server.server_port}{REALM}"

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()

    def login(self, *scope):
        script = ('. "$HELPER"; rc=0; oidc_login "$ISSUER" http://app.test/redirect.html "coach 1@x.test" PW "$@" || rc=$?; '
                  'printf "%s|%s|%s" "$rc" "$OIDC_ACCESS_TOKEN" "$OIDC_REFRESH_TOKEN"')
        out = subprocess.run(["bash", "-c", script, "login", *scope], capture_output=True, text=True, timeout=30,
                             env={"PATH": "/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin", "HELPER": str(HELPER),
                                  "ISSUER": self.issuer, "PW": PASSWORD})
        self.assertEqual(out.stderr, "", "the helper prints nothing")
        rc, access, refresh = out.stdout.split("|")
        return int(rc), access, refresh

    def test_signs_in_with_pkce_s256_and_returns_both_tokens(self):
        self.assertEqual(self.login(), (0, "acc.ess.tok", "ref.resh.tok"))
        auth = self.server.auth
        self.assertEqual((auth["client_id"], auth["response_type"], auth["code_challenge_method"]), ("web", "code", "S256"))
        self.assertEqual(auth["redirect_uri"], "http://app.test/redirect.html")
        self.assertEqual(auth["scope"], "openid profile email offline_access")
        self.assertGreaterEqual(len(auth["state"]), 16)
        self.assertEqual(self.server.login["query"], {"session_code": "s1", "execution": "e1"}, "&amp; is decoded")
        self.assertIn("AUTH_SESSION_ID=a1", self.server.login["cookie"])
        self.assertEqual(self.server.token["redirect_uri"], "http://app.test/redirect.html")

    def test_credentials_are_url_encoded(self):
        self.login()
        self.assertEqual(self.server.login["form"], {"username": "coach 1@x.test", "password": PASSWORD})

    def test_a_caller_may_ask_for_fewer_scopes(self):
        self.login("openid profile email")
        self.assertEqual(self.server.auth["scope"], "openid profile email")

    def test_a_refused_password_is_1_without_a_token(self):
        self.server.mode = "wrong-password"
        self.assertEqual(self.login(), (1, "", ""))

    def test_no_login_form_is_1(self):
        self.server.mode = "no-form"
        self.assertEqual(self.login(), (1, "", ""))

    def test_a_redirect_with_another_state_is_1(self):
        self.server.mode = "bad-state"
        self.assertEqual(self.login(), (1, "", ""))

    def test_a_rate_limit_is_2(self):
        self.server.mode = "rate-limited"
        self.assertEqual(self.login(), (2, "", ""))

    def test_the_password_never_reaches_a_command_line(self):
        text = HELPER.read_text()
        self.assertNotRegex(text, r"password=\$")
        self.assertIn("password@-", text)


class OneCopy(unittest.TestCase):
    def test_every_sign_in_function_a_script_calls_is_defined(self):
        # WP139's first cut dropped smoke.sh's user_token while two later steps still called it (kind proof, 2026-11-24)
        for rel in ("deploy/kind/smoke.sh", "infra/compose/events-backfill.sh", "infra/keycloak/seed-academy.sh"):
            text = (ROOT / rel).read_text()
            for name in ("user_token", "login_once", "token"):
                if re.search(rf"\$\((?:[^)]*&& )?{name} ", text):
                    self.assertTrue(re.search(rf"(?m)^\s*{name}\(\) \{{", text), f"{rel} calls {name} without defining it")

    def test_no_script_scrapes_the_login_form_itself(self):
        out = subprocess.run(["git", "grep", "-l", "kc-form-login", "--", "*.sh"], cwd=ROOT, capture_output=True,
                             text=True).stdout.split()
        self.assertEqual(out, ["scripts/lib/oidc-login.sh"])


if __name__ == "__main__":
    unittest.main()
