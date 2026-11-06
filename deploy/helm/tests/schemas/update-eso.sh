#!/usr/bin/env bash
# Regenerates the kubeconform JSON schema of the External Secrets Operator's ExternalSecret (WP65) from the CRD of the ESO
# version pinned in deploy/kind/up.sh (ESO_VERSION). deploy/helm/tests/run.sh validates the chart against it before
# falling back to the datree catalog (unpinned), and fails when VERSION differs from the pin: bump both together.
# Needs only helm and jq: helm's fromYaml/toJson converts the CRD, jq applies kubeconform's openapi2jsonschema strict
# rule (additionalProperties: false on every object schema with properties, the root excepted).
#   deploy/helm/tests/schemas/update-eso.sh
set -euo pipefail
cd "$(dirname "$0")/../../../.."
OUT=deploy/helm/tests/schemas/external-secrets.io
version=$(sed -n 's/^ESO_VERSION="\(v[0-9.]*\)"$/\1/p' deploy/kind/up.sh)
[ -n "$version" ] || { echo "update-eso.sh: ESO_VERSION not found in deploy/kind/up.sh" >&2; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/crd.yaml" \
  "https://raw.githubusercontent.com/external-secrets/external-secrets/${version}/config/crds/bases/external-secrets.io_externalsecrets.yaml"
mkdir -p "$tmp/conv/templates"
printf 'apiVersion: v2\nname: conv\nversion: 0.0.0\n' > "$tmp/conv/Chart.yaml"
printf '{{ fromYaml .Values.doc | toJson }}\n' > "$tmp/conv/templates/crd.json"
helm template conv "$tmp/conv" --set-file doc="$tmp/crd.yaml" --show-only templates/crd.json | grep '^{' > "$tmp/crd.json"
mkdir -p "$OUT"
jq --arg v v1 '
  def strict: if type == "object" then
      (if has("properties") and (has("additionalProperties") | not) then . + {additionalProperties: false} else . end)
      | with_entries(.value |= strict)
    elif type == "array" then map(strict) else . end;
  .spec.versions[] | select(.name == $v) | .schema.openAPIV3Schema | with_entries(.value |= strict)' \
  "$tmp/crd.json" > "$OUT/externalsecret_v1.json"
[ -s "$OUT/externalsecret_v1.json" ] || { echo "update-eso.sh: no v1 schema in the CRD of $version" >&2; exit 1; }
printf '%s\n' "$version" > "$OUT/VERSION"
echo "wrote $OUT/externalsecret_v1.json for ESO $version"
