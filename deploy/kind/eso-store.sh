#!/usr/bin/env bash
# Prints, as YAML on stdout, the stand-in for a cloud secret manager that the External Secrets Operator reads on kind
# (WP65, `deploy/kind/up.sh --eso`, ADR-0012 amendment):
#   - Secret `hoops` in namespace hoops-secret-store: one key per .env value the chart's ExternalSecrets name
#     (externalSecrets.remoteKey and the `data` properties in deploy/helm/hoops/values.yaml). DEV_USER_PASSWORD stays
#     out: no workload reads it (seed-users.sh and smoke.sh take it from .env);
#   - ServiceAccount eso-store-reader, allowed to read the Secrets of that namespace and nothing else;
#   - ClusterSecretStore `hoops` (Kubernetes provider: the reader's token, the cluster CA from kube-root-ca.crt), usable
#     from the namespaces hoops and envoy-gateway-system only.
# The values come from .env and reach jq through its environment, never a command line; nothing is written to disk.
#   deploy/kind/eso-store.sh | kubectl apply -f -
set -euo pipefail
cd "$(dirname "$0")/../.."
NS="${HOOPS_NAMESPACE:-hoops}"
STORE_NS="${ESO_STORE_NAMESPACE:-hoops-secret-store}"
EG_NS=envoy-gateway-system
# shellcheck source=deploy/kind/env-keys.sh
. deploy/kind/env-keys.sh
load_env eso-store.sh   # exports every .env value (set -a)

keys=()
for k in "${SECRET_KEYS[@]}"; do [ "$k" = DEV_USER_PASSWORD ] || keys+=("$k"); done
jq -n --arg ns "$STORE_NS" '{apiVersion: "v1", kind: "Secret", type: "Opaque",
  metadata: {name: "hoops", namespace: $ns, labels: {"app.kubernetes.io/part-of": "hoops-academy"}},
  data: ($ARGS.positional | map({(.): ($ENV[.] | @base64)}) | add)}' --args "${keys[@]}"
cat <<YAML
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eso-store-reader
  namespace: $STORE_NS
  labels: {app.kubernetes.io/part-of: hoops-academy}
automountServiceAccountToken: false
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: eso-store-reader
  namespace: $STORE_NS
  labels: {app.kubernetes.io/part-of: hoops-academy}
rules:
  # get: what ESO reads; list/watch are not needed. The store validation asks for authorization.k8s.io access reviews,
  # which every authenticated identity may create.
  - apiGroups: [""]
    resources: [secrets]
    verbs: [get]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: eso-store-reader
  namespace: $STORE_NS
  labels: {app.kubernetes.io/part-of: hoops-academy}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: eso-store-reader}
subjects:
  - {kind: ServiceAccount, name: eso-store-reader, namespace: $STORE_NS}
---
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: hoops
  labels: {app.kubernetes.io/part-of: hoops-academy}
spec:
  conditions:
    - namespaces: [$NS, $EG_NS]
  provider:
    kubernetes:
      remoteNamespace: $STORE_NS
      server:
        caProvider: {type: ConfigMap, name: kube-root-ca.crt, key: ca.crt, namespace: $STORE_NS}
      auth:
        serviceAccount: {name: eso-store-reader, namespace: $STORE_NS}
YAML
