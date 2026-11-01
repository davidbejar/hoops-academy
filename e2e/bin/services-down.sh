#!/usr/bin/env bash
# Stops the services started by services-up.sh.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/e2e/target/services"
for s in core game athlete; do
  if [ -f "$OUT/$s.pid" ]; then kill "$(cat "$OUT/$s.pid")" 2>/dev/null && echo "stopped $s" || true; rm -f "$OUT/$s.pid"; fi
done
