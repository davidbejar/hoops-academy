# Runbook — Hoops Academy on one k3s VM in Alibaba Cloud (Jakarta)

WP104, ADR-0050, decisions 76-78. **Status: code only. Nothing in this runbook has been run against Alibaba Cloud**: there
is no account and no access key yet (decision 77). Every step below that touches the cloud is marked **NOT YET RUN**; the
next round runs them and replaces the marks with what it saw. Proven so far: `just tofu-check` (fmt, validate, 25 mocked
`tofu test` runs, trivy, shellcheck, pins) and the chart render with `values-cloud.yaml` (`deploy/helm/tests/run.sh`).

## What it builds
```
OpenTofu (infra/tofu)                              Helm + kubectl (deploy/cloud/install.sh)
  VPC 172.20.0.0/16, vSwitch 172.20.1.0/24           namespaces, Secrets from .env (deploy/kind/secrets.sh)
  security group: 22 + 6443 from admin_cidrs,        Stakater Reloader, Envoy Gateway v1.10.0 (+ rate limit backend),
                  80 + 443 from everyone             CloudNativePG 1.30.1, self-signed hoops-gateway-tls
  key pair (your public key)                         chart `hoops` with values-cloud.yaml, images ghcr.io/...:<sha>
  ECS ecs.g7.large (2 vCPU, 8 GiB), Ubuntu 24.04,
     ESSD 60 GiB encrypted, IMDSv2 only, no own IP   k3s inside the VM (cloud-init, first boot):
  EIP (pay by traffic, 10 Mbit/s) -> the address       v1.36.6+k3s1, install script + binary checked by SHA-256,
     <a-b-c-d>.sslip.io (no DNS record)                Traefik off, ServiceLB on (Envoy gets the node's 80/443),
                                                       local-path volumes, Secrets encrypted at rest
```
The deployment answers at `https://<a-b-c-d>.sslip.io` (self-signed certificate) for the web app, `/auth` (Keycloak) and
`/api/*`, as on kind. SSH (`root`, key only) and the Kubernetes API (`https://<EIP>:6443`) answer only to `admin_cidrs`.

## Before the first apply: the owner's to-dos
1. **Account.** An Alibaba Cloud account on the international site (alibabacloud.com, not the mainland aliyun.com site), with
   a payment method; the Jakarta region (`ap-southeast-5`) must be usable for ECS and EIP. Costs were not checked (no
   prices here): ECS, the disk, the EIP and its traffic bill per hour or GB while the deployment exists. Consider a budget
   alert in the billing console.
2. **Access key with the least rights that work.** Never the account's own (root) key. In RAM: a user `hoops-tofu` with
   programmatic access only (no console login), and this custom policy attached (ECS and VPC/EIP in Jakarta only, plus
   the read-only lookups the plan does):
   ```json
   {
     "Version": "1",
     "Statement": [
       {"Effect": "Allow", "Action": ["ecs:*", "vpc:*"],
        "Resource": ["acs:ecs:ap-southeast-5:*:*", "acs:vpc:ap-southeast-5:*:*"]},
       {"Effect": "Allow", "Action": ["ecs:Describe*", "vpc:Describe*"], "Resource": "*"}
     ]
   }
   ```
   It is broader than the module needs (any ECS/VPC action in the region) and not yet tried: after the first apply and
   destroy, read the calls in ActionTrail and narrow it to those actions (follow-up). If disk encryption asks for KMS
   rights, see Troubleshooting.
3. **Where the key goes.** At the end of the git-ignored `.env` (placeholders in `.env.example`):
   `ALIBABA_CLOUD_ACCESS_KEY_ID`, `ALIBABA_CLOUD_ACCESS_KEY_SECRET`. Alternative that keeps the key out of `.env` (and out
   of every `just` recipe's environment, since the justfile loads `.env`): `aliyun configure --profile hoops` (aliyun CLI)
   and only `ALIBABA_CLOUD_PROFILE=hoops`; then delete the two key lines from `.env`.
4. **State passphrase.** `TF_VAR_state_passphrase` in `.env`: at least 16 characters, from a password manager, and kept
   there too. The state (`infra/tofu/terraform.tfstate`, git-ignored, encrypted) is unreadable without it; back up both.
5. **Variables.** `cp infra/tofu/terraform.tfvars.example infra/tofu/terraform.tfvars` (git-ignored): your public IP as
   `admin_cidrs = ["<ip>/32"]` (`curl -s https://checkip.amazonaws.com`) and your `ssh_public_key` (one line of
   `~/.ssh/id_ed25519.pub`).
6. **Images.** The images of one `main` commit on ghcr.io (`images.yml` pushes `ghcr.io/davidbejar/hoops-academy/<image>:<sha>`
   when the repository variable `IMAGE_REGISTRY` is set; the packages are public, release.md section 3). Note the full
   40-character sha of a commit whose `images` run pushed all four images.
7. **`.env` values.** Strong, fresh values for every secret in `.env` (database roles, Keycloak admin, OIDC clients, Redpanda,
   Redis, `DEV_USER_PASSWORD`): this deployment is on the internet. `install.sh` refuses a `.env` that still contains
   `change-me`.
8. Tools: `brew install opentofu` (`scripts/bootstrap.sh` does it), kubectl, helm, jq, openssl, ssh.

## Steps
Load `.env` into the shell for the `tofu` commands (the `just` recipes load it themselves):
`set -a; . ./.env; set +a`.

### 1. Check the code (proven, WP104)
```bash
just tofu-check        # fmt, init, validate, tofu test (mocked provider), trivy config, shellcheck, pins; no credential
deploy/helm/tests/run.sh   # chart lint and snapshots, umbrella-cloud included
```

### 2. Plan — NOT YET RUN
```bash
tofu -chdir=infra/tofu init
tofu -chdir=infra/tofu plan -out=hoops.tfplan     # the plan file is encrypted and git-ignored
```
Expect 11 resources with one admin CIDR (VPC, vSwitch, security group, 1 SSH rule, 1 API rule, 2 web rules, key pair, EIP,
instance, EIP association). The plan stops before creating anything when no Jakarta zone sells `instance_type` or the type
has less than 8 GiB: then set `instance_type` in `terraform.tfvars` to another 2 vCPU / 8 GiB type the region sells
(`ecs.g6.large`, `ecs.u1-c1m4.large`, ...; the console's instance type list per region shows them).

### 3. Apply — NOT YET RUN
```bash
tofu -chdir=infra/tofu apply hoops.tfplan
tofu -chdir=infra/tofu output        # public_ip, hostname (<a-b-c-d>.sslip.io), public_url, ssh_command, ...
```
cloud-init then updates the OS packages and installs k3s (a few minutes). `ssh root@<ip> cloud-init status --long` shows
it; `ssh root@<ip> k3s kubectl get nodes` once it is done.

### 4. Kubeconfig — NOT YET RUN
```bash
just cloud-kubeconfig     # ~/.kube/hoops-cloud.yaml (mode 600, context hoops-cloud), server https://<EIP>:6443
KUBECONFIG=~/.kube/hoops-cloud.yaml kubectl get nodes
```
The host key is trusted on first use; compare its fingerprint with `ssh-keyscan` output from the instance's console if
you want to be sure.

### 5. Install — NOT YET RUN
```bash
just cloud-install <sha>  # Secrets from .env, Reloader, Envoy Gateway, CNPG, TLS Secret, helm upgrade --install --wait
```
`ENV_FILE=.env.cloud just cloud-install <sha>` takes the Secrets from another (git-ignored) file; the seed and smoke scripts
below still read `.env`, so keep the two equal for now (follow-up). Re-run with a newer sha to upgrade. The gateway's
certificate (public part) lands in `~/.config/hoops-cloud/gateway.crt` for curl.

### 6. Seed and smoke — NOT YET RUN
```bash
just cloud-seed-users                 # the dev users of .env (<name>@hoops-academy.com) in the cloud Keycloak
just cloud-smoke core game athlete    # deploy/kind/smoke.sh against https://<host>: pods, gateway, issuer, deny routes,
                                      # health, tokens and audiences, superadmin login (PKCE), events
deploy/cloud/with-cloud.sh deploy/kind/ratelimit-check.sh acl    # any other deploy/kind script the same way
```
Then in a browser: `https://<host>`, accept the certificate warning once, log in as the superadmin. Delete the dev users
before anyone else gets an account (they share one known password pattern).

### 7. Destroy — NOT YET RUN
```bash
tofu -chdir=infra/tofu destroy        # instance, disk, EIP, key pair, security group, vSwitch, VPC
rm -f ~/.kube/hoops-cloud.yaml; rm -rf ~/.config/hoops-cloud; ssh-keygen -R <ip>
```
Everything in the cluster (databases included) goes with the instance; there are no backups yet. The local state stays
(empty after the destroy); keep it with its passphrase or delete it.

## Changes and rebuilds
- `image_id` and `user_data` changes are ignored on purpose (a newer Ubuntu image would replace the system disk in place).
  Rebuild deliberately: `tofu -chdir=infra/tofu apply -replace=alicloud_instance.k3s` (the EIP, hence the hostname,
  stays), then steps 4-6.
- New home address: update `admin_cidrs`, `tofu apply` (only the rules change).
- Bump k3s: the version and both SHA-256 sums in `infra/tofu/main.tf` (`locals.k3s`) and the test; then a rebuild.
- Bump Envoy Gateway, CNPG or Reloader: in `deploy/kind/up.sh` and `deploy/cloud/install.sh` together (`just tofu-check`
  fails when they differ).

## Troubleshooting (expected, not yet seen)
- Plan error "No zone of ap-southeast-5 sells ...": pick another `instance_type` (step 2).
- Apply fails on the encrypted system disk (KMS not activated for the account or the RAM user lacks KMS rights): activate
  KMS / allow it, or set `system_disk_encrypted = false` in `terraform.tfvars` for the test deployment and note it.
- k3s never appears (`/etc/rancher/k3s/k3s.yaml` missing): `ssh root@<ip> 'cloud-init status --long; tail -50 /var/log/cloud-init-output.log'`.
  If the user data was not read at all, the image's cloud-init may not support metadata-hardened mode (IMDSv2, ADR-0050):
  check `cloud-init --version` (23.2.2 or later needed).
- `curl` / smoke: `SSL certificate problem`: `~/.config/hoops-cloud/gateway.crt` is missing or from an older Secret: re-run
  `just cloud-install <sha>` (it rewrites the file).
- Every login answers "HTTPS required": the browser used `http://`; use `https://<host>` (the realm requires TLS for public
  clients; there is no HTTP-to-HTTPS redirect yet).
- Rate limits count the wrong client (all requests share one counter): ServiceLB did not keep the client address; check
  Envoy's access log and the Service's `externalTrafficPolicy` (ADR-0033 needs the real client IP).

## Open risks (ADR-0050)
Single node (no HA, one disk, no backups); self-signed TLS (warning; no service worker, so no offline mode) until the
TLS slice; SSH and the Kubernetes API exposed to `admin_cidrs`; dev users and Mailpit on a public host; costs unknown;
minors' health data needs the GDPR work before any real academy uses a public deployment.
