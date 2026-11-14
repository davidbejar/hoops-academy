# shellcheck shell=bash
# Shared by deploy/cloud/*.sh (WP104, ADR-0050): the OpenTofu outputs of infra/tofu (its state is encrypted, so
# TF_VAR_state_passphrase must be set) and where the cloud kubeconfig and the gateway certificate live on this machine.
# Nothing here is secret; the kubeconfig itself is (mode 600, outside the repository).

# shellcheck disable=SC2034 # used by the scripts that source this file
CLOUD_KUBECONFIG="${HOOPS_CLOUD_KUBECONFIG:-$HOME/.kube/hoops-cloud.yaml}"
CLOUD_CONTEXT=hoops-cloud
# Public part of the gateway's self-signed certificate (curl's CA bundle for the smoke scripts).
# shellcheck disable=SC2034
CLOUD_CERT="${XDG_CONFIG_HOME:-$HOME/.config}/hoops-cloud/gateway.crt"

need() { # tools...
  local t
  for t in "$@"; do command -v "$t" >/dev/null || { echo "$(basename "$0"): $t not found" >&2; exit 1; }; done
}

tofu_output() { # name
  [ -n "${TF_VAR_state_passphrase:-}" ] \
    || { echo "$(basename "$0"): set TF_VAR_state_passphrase (the state is encrypted; docs/runbooks/cloud.md)" >&2; exit 1; }
  tofu -chdir=infra/tofu output -raw "$1"
}

cloud_kubectl() { kubectl --kubeconfig "$CLOUD_KUBECONFIG" --context "$CLOUD_CONTEXT" "$@"; }
cloud_helm() { helm --kubeconfig "$CLOUD_KUBECONFIG" --kube-context "$CLOUD_CONTEXT" "$@"; }
