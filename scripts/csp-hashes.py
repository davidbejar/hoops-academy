#!/usr/bin/env python3
"""CSP hashes of the inline <script> (and redirect.html <style>) blocks of the built web app (apps/web/build/web by default).

The web CSP (infra/compose/nginx.conf, deploy/containers/web-nginx.conf) allows exactly these inline scripts by
hash. After a change to apps/web/web/index.html or redirect.html, run this and update both configs:
    scripts/csp-hashes.py [build-dir]            print 'sha256-...' per inline script
    scripts/csp-hashes.py --check [build-dir]    exit 1 if a hash is missing from either nginx config
"""
import base64, hashlib, pathlib, re, sys

args = [a for a in sys.argv[1:] if a != "--check"]
check = "--check" in sys.argv
root = pathlib.Path(__file__).resolve().parent.parent
build = pathlib.Path(args[0]) if args else root / "apps/web/build/web"
configs = [root / "infra/compose/nginx/web-headers.conf", root / "infra/compose/nginx/redirect-headers.conf",
           root / "deploy/containers/web-nginx.conf"]

hashes = []
for page in ("index.html", "redirect.html"):
    f = build / page
    if not f.exists():
        continue
    html = f.read_text(encoding="utf-8")
    blocks = [("script", b) for b in re.findall(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>", html, re.S)]
    blocks += [("style", b) for b in re.findall(r"<style[^>]*>(.*?)</style>", html, re.S)]
    for kind, body in blocks:
        if kind == "style" and page == "index.html":
            continue  # the SPA CSP allows 'unsafe-inline' styles (Flutter engine), no hash needed
        h = "sha256-" + base64.b64encode(hashlib.sha256(body.encode("utf-8")).digest()).decode()
        hashes.append((f"{page} {kind}", h))

if not hashes:
    print(f"csp-hashes: no built pages under {build} (flutter build web first)", file=sys.stderr)
    sys.exit(0 if not check else 2)
rc = 0
for page, h in hashes:
    # compose: index hashes live in web-headers.conf, redirect hashes in redirect-headers.conf
    relevant = [configs[0] if page.startswith("index") else configs[1], configs[2]]
    missing = [str(c.relative_to(root)) for c in relevant if f"'{h}'" not in c.read_text()]
    print(f"{page}\t'{h}'" + (f"\tMISSING in {', '.join(missing)}" if missing else ""))
    rc |= bool(missing)
sys.exit(rc if check else 0)
