#!/usr/bin/env bash
# Copies the single-source-of-truth files into the Helm charts (they used to be symlinks, which `helm package`
# rejects). Sources stay authoritative: edit infra/..., then run this script (deploy/kind/up.sh and CI do).
#   scripts/sync-chart-files.sh          copy sources into the charts
#   scripts/sync-chart-files.sh --check  exit 1 if a chart copy differs from its source (chart tests, CI)
set -euo pipefail
cd "$(dirname "$0")/.."
CHECK=0; [ "${1:-}" = "--check" ] && CHECK=1
# source -> chart copy
PAIRS=(
  "infra/keycloak/realm-academy.json:deploy/helm/hoops/charts/keycloak/files/realm-academy.json"
  "infra/db/init/01_roles_schemas.sql:deploy/helm/hoops/charts/databases/files/01_roles_schemas.sql"
)
rc=0
for pair in "${PAIRS[@]}"; do
  src=${pair%%:*}; dst=${pair#*:}
  if [ "$CHECK" = 1 ]; then
    if [ -L "$dst" ]; then echo "sync-chart-files: $dst is a symlink (breaks helm package)" >&2; rc=1
    elif ! cmp -s "$src" "$dst"; then echo "sync-chart-files: $dst differs from $src (run scripts/sync-chart-files.sh)" >&2; rc=1
    fi
  else
    mkdir -p "$(dirname "$dst")"
    rm -f "$dst"            # replaces a legacy symlink instead of writing through it
    cp "$src" "$dst"
  fi
done
exit "$rc"
