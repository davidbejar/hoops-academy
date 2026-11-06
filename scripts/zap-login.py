#!/usr/bin/env python3
"""Signs a user in through Keycloak (authorization code + PKCE, public client `web`, as the app and the e2e suite do;
direct grants are disabled) and writes the token response for the ZAP API scans (scripts/zap-api-scan.sh, ADR-0045).

    python3 -I scripts/zap-login.py --base http://localhost:8080 --out target/zap/tokens.json \
        [--user superadmin@hoops-academy.com] [--redirect <base>/redirect.html]

The password comes from HOOPS_ZAP_PASSWORD, else DEV_USER_PASSWORD (environment, then the repo's .env); it is never
printed. The output file (mode 0600 unless --mode says otherwise) holds the access and refresh token: delete it after
the scan (the scan script does), never upload it.
"""
import argparse
import base64
import hashlib
import html
import json
import os
import pathlib
import re
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
FORM = re.compile(r'<form[^>]*id="kc-form-login"[^>]*>|<form[^>]*action="[^"]*"[^>]*id="kc-form-login"[^>]*>', re.S)
ACTION = re.compile(r'action="([^"]*)"')


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


OPENER = urllib.request.build_opener(NoRedirect)


def password():
    for name in ("HOOPS_ZAP_PASSWORD", "DEV_USER_PASSWORD"):
        if os.environ.get(name):
            return os.environ[name]
    env = ROOT / ".env"
    if env.is_file():
        for line in env.read_text().splitlines():
            if line.startswith("DEV_USER_PASSWORD="):
                return line.split("=", 1)[1].strip().strip("'\"")
    sys.exit("zap-login: set HOOPS_ZAP_PASSWORD or DEV_USER_PASSWORD (environment or .env)")


def send(url, jar, data=None):
    """One request without following redirects; returns (status, headers, body) and keeps the cookies in `jar`."""
    req = urllib.request.Request(url, data=urllib.parse.urlencode(data).encode() if data else None)
    if jar:
        req.add_header("Cookie", "; ".join(f"{k}={v}" for k, v in jar.items()))
    try:
        resp = OPENER.open(req, timeout=30)
    except urllib.error.HTTPError as err:  # 3xx (not followed) and errors
        resp = err
    with resp:
        for cookie in resp.headers.get_all("Set-Cookie") or []:
            name, _, value = cookie.split(";", 1)[0].partition("=")
            jar[name.strip()] = value.strip()
        return resp.status, resp.headers, resp.read().decode("utf-8", "replace")


def b64url(raw):
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def sign_in(base, user, secret, redirect):
    issuer = f"{base}/auth/realms/academy/protocol/openid-connect"
    verifier = b64url(secrets.token_bytes(48))
    state = secrets.token_hex(8)
    jar = {}
    query = urllib.parse.urlencode({
        "client_id": "web", "response_type": "code", "redirect_uri": redirect, "scope": "openid profile email",
        "state": state, "code_challenge": b64url(hashlib.sha256(verifier.encode()).digest()),
        "code_challenge_method": "S256"})
    status, _, page = send(f"{issuer}/auth?{query}", jar)
    form = FORM.search(page)
    if status != 200 or not form:
        sys.exit(f"zap-login: no Keycloak login form (status {status}); is {redirect} a redirect URI of client web?")
    action = html.unescape(ACTION.search(form.group(0)).group(1))
    status, headers, _ = send(action, jar, {"username": user, "password": secret})
    location = headers.get("Location", "")
    if status != 302 or not location.startswith(redirect):
        sys.exit(f"zap-login: {user} was not signed in (status {status}): wrong password, required action or "
                 "disabled user")
    params = dict(urllib.parse.parse_qsl(urllib.parse.urlsplit(location).query))
    if params.get("state") != state or "code" not in params:
        sys.exit("zap-login: state mismatch or no code")
    status, _, body = send(f"{issuer}/token", {}, {
        "grant_type": "authorization_code", "client_id": "web", "code": params["code"], "redirect_uri": redirect,
        "code_verifier": verifier})
    if status != 200:
        sys.exit(f"zap-login: code exchange failed (status {status})")
    tokens = json.loads(body)
    tokens["token_endpoint"] = f"{issuer}/token"
    return tokens


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", default="http://localhost:8080", help="public origin (nginx / gateway)")
    parser.add_argument("--user", default="superadmin@hoops-academy.com")
    parser.add_argument("--redirect", help="redirect URI registered on client web (default <base>/redirect.html)")
    parser.add_argument("--out", required=True)
    parser.add_argument("--mode", type=lambda m: int(m, 8), default=0o600, help="file mode, octal")
    args = parser.parse_args()
    base = args.base.rstrip("/")
    tokens = sign_in(base, args.user, password(), args.redirect or f"{base}/redirect.html")
    out = pathlib.Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(out, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, args.mode)
    with os.fdopen(fd, "w") as f:
        json.dump(tokens, f)
    os.chmod(out, args.mode)
    print(f"zap-login: {args.user} signed in; token response written to {out} (expires in {tokens.get('expires_in')} s)")


if __name__ == "__main__":
    main()
