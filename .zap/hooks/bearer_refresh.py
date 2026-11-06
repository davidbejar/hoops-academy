"""ZAP packaged-scan hook (zap-api-scan.py --hook): signs every request with the bearer token written by
scripts/zap-login.py and keeps it fresh for scans longer than the realm's 5-minute access token (ADR-0045).

Reads /zap/wrk/tokens.json (access_token, refresh_token, token_endpoint) when ZAP has started, refreshes the token
at once (ZAP's start-up can outlast it), adds a Replacer rule that sets `Authorization: Bearer <access token>` on
every request ZAP sends, then refreshes again (refresh-token grant of the public client `web`, rotation honoured) at
80 % of the token's lifetime and swaps the rule. The token file is
deleted from the work directory as soon as it is read. Token values are never logged.
"""
import json
import logging
import os
import threading
import urllib.parse
import urllib.request

TOKENS = os.environ.get("ZAP_TOKENS_FILE", "/zap/wrk/tokens.json")
RULE = "hoops-bearer"
_stop = threading.Event()


def _set_header(zap, access_token):
    try:
        zap.replacer.remove_rule(RULE)
    except Exception:  # first call: no rule yet
        pass
    zap.replacer.add_rule(description=RULE, enabled="true", matchtype="REQ_HEADER", matchregex="false",
                          matchstring="Authorization", replacement=f"Bearer {access_token}")


def _refresh(zap, tokens):
    """Refresh-token grant; on failure the scan goes on with the old token (the 401s show in the report)."""
    body = urllib.parse.urlencode({"grant_type": "refresh_token", "client_id": "web",
                                   "refresh_token": tokens["refresh_token"]}).encode()
    try:
        with urllib.request.urlopen(tokens["token_endpoint"], data=body, timeout=30) as resp:
            fresh = json.load(resp)
    except Exception as err:
        logging.warning("hoops-bearer: token refresh failed: %s", type(err).__name__)
        return
    tokens.update({k: fresh[k] for k in ("access_token", "refresh_token", "expires_in") if k in fresh})
    _set_header(zap, tokens["access_token"])
    logging.info("hoops-bearer: token refreshed")


def _refresh_loop(zap, tokens):
    while not _stop.wait(max(30, int(tokens.get("expires_in", 300)) * 0.8)):
        _refresh(zap, tokens)


def zap_started(zap, target):
    with open(TOKENS, encoding="utf-8") as f:
        tokens = json.load(f)
    try:
        os.remove(TOKENS)
    except OSError:
        pass
    _set_header(zap, tokens["access_token"])
    _refresh(zap, tokens)  # ZAP takes minutes to start: the token from the sign-in may be nearly spent already
    threading.Thread(target=_refresh_loop, args=(zap, tokens), daemon=True, name="hoops-bearer").start()
    logging.info("hoops-bearer: Authorization header set, refresh every %s s", int(tokens.get("expires_in", 300) * 0.8))
    return zap, target


def zap_pre_shutdown(zap):
    _stop.set()
