#!/usr/bin/env bash
# ZAP API scan (active, OpenAPI-driven) of one service through the public origin, signed in as the platform super
# admin (WP83, ADR-0045). Needs the compose stack with seeded users and the services running (`just e2e` leaves the
# stack up; CI: e2e.yml after the journeys).
#
#   scripts/zap-api-scan.sh <core|game|athlete> [base URL, default http://localhost:8080]
#
# Env: ZAP_IMAGE (pinned default below), ZAP_ENGINE (podman | docker, default podman), ZAP_WORK_DIR (default
# target/zap; the reports land in <dir>/api-<service>/), ZAP_MAX_SCAN_MINUTES (active-scan cap, default 15),
# HOOPS_ZAP_USER (default superadmin@hoops-academy.com), HOOPS_ZAP_PASSWORD (default DEV_USER_PASSWORD, env or .env).
#
# The scan uses ZAP's API policy (zap-api-scan.py without -c, so no rule is switched off); acceptances live in
# .zap/api-<service>.conf and are applied afterwards by scripts/zap-gate.py, which fails on a High/Medium alert that
# is not accepted. The token file is removed by the hook as soon as ZAP has read it, and again here.
set -euo pipefail

svc="${1:?usage: zap-api-scan.sh <core|game|athlete> [base URL]}"
base="${2:-http://localhost:8080}"
case "$svc" in core|game|athlete) ;; *) echo "zap-api-scan: unknown service $svc" >&2; exit 2 ;; esac
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="${ZAP_IMAGE:-ghcr.io/zaproxy/zaproxy:stable@sha256:030d3df57735dacbb83464854758e674dd9ad01d79d12a129a8e58b1fd384238}"
engine="${ZAP_ENGINE:-podman}"
work="${ZAP_WORK_DIR:-$ROOT/target/zap}/api-$svc"

rm -rf "$work" && mkdir -p "$work"
cp -R "$ROOT/libs/contracts/openapi" "$work/openapi"
cp "$ROOT/.zap/hooks/bearer_refresh.py" "$work/"
trap 'rm -f "$work/tokens.json"' EXIT
# the ZAP container runs as user zap: it must read the token file and write the reports
python3 -I "$ROOT/scripts/zap-login.py" --base "$base" --user "${HOOPS_ZAP_USER:-superadmin@hoops-academy.com}" \
  --out "$work/tokens.json" --mode 644
chmod -R a+rwX "$work"

start=$SECONDS
"$engine" run --rm --network host -v "$work:/zap/wrk:rw" "$image" \
  zap-api-scan.py -t "/zap/wrk/openapi/$svc.yaml" -f openapi -O "$base" \
    --hook=/zap/wrk/bearer_refresh.py -J "zap-api-$svc.json" -r "zap-api-$svc.html" -I \
    -z "-config scanner.maxScanDurationInMins=${ZAP_MAX_SCAN_MINUTES:-15} -config scanner.maxRuleDurationInMins=3" \
  | tee "$work/zap-api-$svc.log"
echo "zap-api-scan $svc: $((SECONDS - start)) s"
python3 -I "$ROOT/scripts/zap-gate.py" "$work/zap-api-$svc.json" "$ROOT/.zap/api-$svc.conf"
