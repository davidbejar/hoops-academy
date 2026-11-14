#!/usr/bin/env bash
# Fetches the k3s kubeconfig of the cloud VM (WP104, ADR-0050) over SSH into ~/.kube/hoops-cloud.yaml (mode 600, context
# hoops-cloud, server https://<EIP>:6443, which the security group opens to admin_cidrs only). Waits up to 10 minutes for
# cloud-init to finish k3s. The host key is trusted on first use (accept-new).
# NOT YET RUN: no cloud account this round (decision 77).
#   deploy/cloud/kubeconfig.sh          (= just cloud-kubeconfig; needs TF_VAR_state_passphrase and an applied infra/tofu)
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck source=deploy/cloud/lib.sh
. deploy/cloud/lib.sh
need tofu ssh kubectl

ip=$(tofu_output public_ip)
umask 077
mkdir -p "$(dirname "$CLOUD_KUBECONFIG")"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# shellcheck disable=SC2016 # expanded on the VM
ssh -o StrictHostKeyChecking=accept-new "root@$ip" \
  'i=0; until [ -s /etc/rancher/k3s/k3s.yaml ]; do i=$((i + 1)); [ "$i" -lt 120 ] || { echo "k3s not ready after 10 min: cloud-init status --long; journalctl -u k3s" >&2; exit 1; }; sleep 5; done; cat /etc/rancher/k3s/k3s.yaml' \
  > "$tmp"
# k3s names cluster, user and context "default" and points at 127.0.0.1: point at the EIP, name everything hoops-cloud.
sed -e "s#https://127.0.0.1:6443#https://$ip:6443#" -e "s/: default\$/: $CLOUD_CONTEXT/" "$tmp" > "$CLOUD_KUBECONFIG"
chmod 600 "$CLOUD_KUBECONFIG"
echo "wrote $CLOUD_KUBECONFIG (context $CLOUD_CONTEXT)"
cloud_kubectl get nodes -o wide
