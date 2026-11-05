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
  # Branded login theme (ADR-0022), mounted by the keycloak chart's theme ConfigMap
  "infra/keycloak/themes/hoops/login/theme.properties:deploy/helm/hoops/charts/keycloak/files/theme/theme.properties"
  "infra/keycloak/themes/hoops/login/resources/css/hoops.css:deploy/helm/hoops/charts/keycloak/files/theme/hoops.css"
  "infra/keycloak/themes/hoops/login/resources/img/basketball.svg:deploy/helm/hoops/charts/keycloak/files/theme/basketball.svg"
  # Login messages: an expired temporary password (ADR-0028)
  "infra/keycloak/themes/hoops/login/messages/messages_en.properties:deploy/helm/hoops/charts/keycloak/files/theme/messages_en.properties"
  "infra/keycloak/themes/hoops/login/messages/messages_es.properties:deploy/helm/hoops/charts/keycloak/files/theme/messages_es.properties"
  "infra/keycloak/themes/hoops/login/messages/messages_id.properties:deploy/helm/hoops/charts/keycloak/files/theme/messages_id.properties"
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
