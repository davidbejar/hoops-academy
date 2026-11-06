#!/usr/bin/env bash
# PWA installability audit (WP54): Lighthouse from a pinned container image against the built app. No Node on the host.
#
#   tool/lighthouse.sh                 # serves build/web (build it first: HOOPS_ALLOW_HTTP_ISSUER=1 tool/build_web.sh)
#   tool/lighthouse.sh --report-dir D  # keep the JSON/HTML reports in D (default: build/lighthouse)
#
# The app and Lighthouse's Chrome share one pod network namespace, so the page is http://localhost:8080: a secure
# context, which service workers and the install prompt require (a host.containers.internal URL would fail them).
# The image is amd64 only: on Apple silicon it runs emulated, where Chromium's zygote aborts (hence --no-zygote).
# Lighthouse 11 is pinned on purpose: v12 dropped the PWA category. Exit 1 when an installability check fails.
set -euo pipefail
cd "$(dirname "$0")/.."

LIGHTHOUSE_IMAGE=docker.io/femtopixel/google-lighthouse:v11.7.1
NGINX_IMAGE=docker.io/library/nginx:1.27-alpine
report_dir=build/lighthouse
[ "${1:-}" = "--report-dir" ] && report_dir="${2:?directory}"
[ -f build/web/index.html ] || { echo "build/web missing: run tool/build_web.sh first" >&2; exit 2; }
mkdir -p "$report_dir"
report_dir="$(cd "$report_dir" && pwd)"
web_dir="$(cd build/web && pwd)"

pod="hoops-lighthouse-$$"
trap 'podman pod rm -f "$pod" >/dev/null 2>&1 || true' EXIT
podman pod create --name "$pod" >/dev/null
podman run -d --pod "$pod" --name "$pod-web" -v "$web_dir:/usr/share/nginx/html:ro" "$NGINX_IMAGE" >/dev/null
for _ in $(seq 1 30); do
  podman exec "$pod-web" wget -q -O /dev/null http://localhost/index.html 2>/dev/null && break
  sleep 1
done

# The image's entrypoint is `lighthouse`; Chrome needs --no-sandbox in a container.
podman run --rm --platform linux/amd64 --pod "$pod" --security-opt seccomp=unconfined -v "$report_dir:/home/chrome/reports:rw,Z" \
  "$LIGHTHOUSE_IMAGE" http://localhost:80/ \
  --only-categories=pwa --preset=desktop --output=json --output=html \
  --output-path=/home/chrome/reports/lighthouse \
  --chrome-flags="--headless=new --no-sandbox --no-zygote --use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader --disable-dev-shm-usage" \
  --max-wait-for-fcp=120000 --max-wait-for-load=240000 --quiet >/dev/null

json="$report_dir/lighthouse.report.json"
[ -f "$json" ] || json="$report_dir/lighthouse.json"
python3 - "$json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
cat = r["categories"]["pwa"]
print(f"Lighthouse {r['lighthouseVersion']}  PWA score: {cat['score']}")
failed = 0
for ref in cat["auditRefs"]:
    a = r["audits"][ref["id"]]
    if a["scoreDisplayMode"] in ("notApplicable", "manual", "informative"):
        mark = a["scoreDisplayMode"]
    else:
        ok = a["score"] == 1
        mark = "pass" if ok else "FAIL"
        failed += 0 if ok else 1
    print(f"  [{mark:>4}] {a['id']}: {a['title']}")
sys.exit(1 if failed else 0)
PY
