#!/usr/bin/env bash
# Stops the services started by services-up.sh: the three jars, then the pdf-service and finance-service containers
# (stopped, not removed; `just down` removes them with the stack).
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/e2e/target/services"
for s in core game athlete; do
  if [ -f "$OUT/$s.pid" ]; then kill "$(cat "$OUT/$s.pid")" 2>/dev/null && echo "stopped $s" || true; rm -f "$OUT/$s.pid"; fi
done
cd "$ROOT" || exit 0
if [ "${E2E_WITHOUT_PDF_FINANCE:-}" != 1 ] && [ -f .env ]; then
  podman compose --env-file .env -f infra/compose/compose.yaml --profile pdf --profile finance \
    stop pdf-service finance-service >/dev/null 2>&1 && echo "stopped pdf-service and finance-service" || true
fi
