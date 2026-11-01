#!/usr/bin/env bash
# Deletes the Hoops Academy kind cluster (all data in it, including the CNPG volumes, is lost).
set -euo pipefail
export KIND_EXPERIMENTAL_PROVIDER=podman
CLUSTER="${KIND_CLUSTER:-hoops}"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kind delete cluster --name "$CLUSTER"
else
  echo "kind cluster '$CLUSTER' does not exist"
fi
