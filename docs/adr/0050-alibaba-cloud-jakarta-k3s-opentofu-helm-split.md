# ADR-0050: First cloud slice: one k3s VM on Alibaba Cloud (Jakarta), OpenTofu for the outer layer, Helm for the inside

- Status: Accepted (code only: nothing applied yet)
- Date: 2026-11-14
- Related: decisions 76-78 of 2026-11-14, WP104, ADR-0012 (Secrets), ADR-0031 (Envoy Gateway), ADR-0033 (rate limits),
  ADR-0034 / `images.yml` (images on ghcr.io), ADR-0036 (Redpanda), ADR-0046 (observability), runbook `docs/runbooks/cloud.md`

## Context
Until now only the inside of a cluster was declared (the Helm chart, kind through `deploy/kind/up.sh`); no machine,
network or address existed anywhere. The owner chose (decision 76) Alibaba Cloud, region Indonesia (Jakarta), on the
international site: never a mainland China region (ICP filing; ghcr.io and quay.io pulls are slow or blocked there).
Decision 77: code only this round, no account, no access key, nothing applied; proof by `tofu fmt`, `tofu validate`,
`tofu test` against mocked providers and a chart render. Decision 78: no domain; a free wildcard DNS name derived from
the server's address, no DNS record managed. The stack needs about 8 GiB (three JVM services, Keycloak, two PostgreSQL
clusters, Redpanda, Envoy, the collector).

## Decision
**Split.** OpenTofu (`infra/tofu`) owns the outer layer only: VPC, vSwitch, security group and its rules, the SSH key pair,
one ECS instance, one EIP and its association. k3s comes from cloud-init on the first boot. Everything inside the cluster
(operators, Secrets, the chart) is installed by `deploy/cloud/install.sh` with kubectl and Helm, as on kind. So no
application secret ever enters the OpenTofu state, and the chart stays the one way to install the application.

**Provider and versions.** OpenTofu `~> 1.13.9` (`.opentofu-version` = 1.13.9, which CI installs); provider
`aliyun/alicloud` = 2.2.0 (2026-11-06), lock file committed with hashes for darwin/linux amd64/arm64. Region
`ap-southeast-5` (zones a, b, c); a validation refuses every `cn-*` region but `cn-hongkong`.

**Machine.** Default `ecs.g7.large` (2 vCPU, 8 GiB). The plan fails, before anything is created, when the type has less
than 8 GiB (`alicloud_instance_types` postcondition) or no zone of the region sells it for a vSwitch instance
(`alicloud_zones` postcondition); the vSwitch goes into the first zone that does. Image: the newest Alibaba Cloud system
image `ubuntu_24_04_x64_20G_alibase_<yyyymmdd>.vhd` (x86_64). System disk ESSD 60 GiB, encrypted; no data disk (the
volumes are k3s `local-path` on the system disk; a separate disk and backups belong to the CloudNativePG backup slice).
Pay-as-you-go, deletion protection off (a test deployment is destroyed with `tofu destroy`). `image_id` and `user_data`
changes are ignored: a newer image would otherwise replace the system disk in place, wiping k3s and every volume;
`tofu apply -replace=alicloud_instance.k3s` rebuilds on purpose.

**Access.** Security group: 22 (SSH) and 6443 (Kubernetes API) only from `admin_cidrs` (required, no default, never
`0.0.0.0/0`, nothing wider than /16); 80 and 443 from everyone; nothing else (the NodePort range stays closed). Login
only with the key pair (no instance password; cloud-init turns password and keyboard-interactive SSH off, root by key
only, as Alibaba's images log in). Instance metadata in security-enhanced mode only (`http_tokens = required`, IMDSv2):
no SSRF path from a pod to the metadata service. No ephemeral public IP: the **EIP** is the only address, created
independently of the instance so the address, the wildcard name, the API certificate and the Keycloak issuer survive a
rebuild. Pay by traffic, 10 Mbit/s cap by default.

**Name.** `<a-b-c-d>.sslip.io` (or nip.io: nip.io's page calls the two domains interchangeable, and sslip.io's web page
redirects there). Every name under it resolves too (`wildcard_hostname`). OpenTofu manages no DNS record.

**k3s.** v1.36.6+k3s1, the Kubernetes minor kind runs (kindest/node v1.36), inside Envoy Gateway v1.10's 1.34-1.37 range.
cloud-init downloads the install script of the release's git tag and the amd64 binary and checks both against SHA-256
sums pinned in `main.tf` (nothing unverified is piped into a shell); it retries the downloads for up to 10 minutes while
the EIP is being bound. Config: `tls-san` = the EIP and the wildcard name, `node-external-ip` = the EIP, Secrets encrypted
at rest (`secrets-encryption`), kubeconfig mode 600. **Traefik off, ServiceLB on**: Envoy Gateway is the only edge, as on
kind and in ADR-0031 (two controllers would contend for 80/443 and Traefik knows none of our routes or rate limits);
ServiceLB binds Envoy's `LoadBalancer` Service to the node's ports 80 and 443 without a cloud load balancer (no SLB, no
Alibaba cloud controller). The storage class is k3s's `local-path`.

**State and secrets (rule 6).** Local state, no backend; encrypted with OpenTofu's state encryption (pbkdf2 key provider,
AES-GCM, `enforced` for state and plan) from a passphrase in `TF_VAR_state_passphrase` (at least 16 characters).
`.gitignore`: `.terraform/`, `*.tfstate*`, `*.tfplan`, `*.tfvars`, crash logs; `terraform.tfvars.example` holds
placeholders only. The access key comes from the environment (`ALIBABA_CLOUD_ACCESS_KEY_ID` / `_SECRET`, or a profile),
never from a file of the module. The state holds no application secret (only the public key and resource ids).

**Chart.** `values-cloud.yaml`: images from `ghcr.io/davidbejar/hoops-academy/*` at one commit's tag; HTTPS listener with
a self-signed `hoops-gateway-tls` that `install.sh` creates for the hostname, and `global.publicUrl` on `https://`:
the realm's `sslRequired: external` refuses plain HTTP from public addresses and the browser's Web Crypto and service
worker need a secure context, so plain HTTP would not log anyone in. No HSTS (it would lock browsers out of a self-signed
host). Secrets from `.env` through `deploy/kind/secrets.sh`, Reloader, Redpanda in developer mode, Mailpit, the in-chart
Redis and the collector with Jaeger as on kind. The address-dependent values are `.invalid` placeholders that
`install.sh` sets from the OpenTofu outputs. Same objects as the kind render (asserted).

**Proof without credentials.** `just tofu-check` (and CI job `tofu-check`): fmt, init with the lock file read-only,
validate, `tofu test` (25 runs, every one a `plan` against `mock_provider "alicloud"`), `trivy config`, shellcheck of the
cloud scripts, the cloud install pins equal to `deploy/kind/up.sh`, nothing stateful tracked by git. Trivy 0.76 has **no
Alibaba Cloud checks** (it runs only generic AWS/Azure/GCP rules, which pass vacuously), so the module's security rules
are asserted by the tests; Checkov's two Alibaba security group rules (CKV_ALI_2/3: no 22/3389 from 0.0.0.0/0) pass and run
in `check.sh` when Checkov is installed. The chart render is asserted in `deploy/helm/tests/run.sh` (snapshot
`umbrella-cloud`).

## Consequences
- One node: no high availability, every volume on one disk, no backups yet. Fine for a test deployment, not for real
  academies (minors' health data brings GDPR obligations kind does not have).
- No trusted TLS: the browser warns once, and Chrome registers no service worker on a certificate error, so the PWA's
  offline mode does not work there until the TLS slice (cert-manager with Let's Encrypt for the sslip.io name).
- SSH and the Kubernetes API are internet-facing for `admin_cidrs`; a changing home address means updating `admin_cidrs`
  and re-applying.
- Costs are unknown (not checked, no prices quoted): ECS, the ESSD disk, the EIP and its traffic are billed by the hour or
  the gigabyte while the deployment exists.
- Not verified from public documentation, to check on the first apply: that `ecs.g7.large` is sold in a Jakarta zone (the
  ECS console's per-region list needs a login; the plan fails clearly if not: pick e.g. `ecs.g6.large` or
  `ecs.u1-c1m4.large`), that the Ubuntu image's cloud-init reads user data in IMDSv2-only mode (Alibaba documents
  cloud-init 23.2.2 or later for it; Ubuntu 24.04 ships a newer one), that disk encryption with the default service key
  needs no extra KMS activation, and that ServiceLB keeps the client address (per-IP rate limits, ADR-0033).

## Sources (looked up 2026-11-14)
- Region id and zones: Alibaba Cloud ECS "Regions and zones", https://www.alibabacloud.com/help/en/ecs/regions-and-zones
  (Indonesia (Jakarta) `ap-southeast-5`, zones `ap-southeast-5a/b/c`).
- Provider: registry.opentofu.org `aliyun/alicloud` versions (2.2.0 latest); resource arguments from the provider's own
  schema (`tofu providers schema -json`) and its docs at tag v2.2.0 (`website/docs/r/instance.html.markdown`,
  `security_group_rule`, `eip_address`, `ecs_key_pair`, `vpc`, `vswitch`, `d/zones`, `d/images`, `d/instance_types`,
  `index.html.markdown` for the credential variables and `features.ecs_instance`), https://github.com/aliyun/terraform-provider-alicloud.
- Instance families: "General-purpose instance families" (g7 / g8i / g6 `.large` = 2 vCPU 8 GiB; "instance types may vary
  by region"), https://www.alibabacloud.com/help/en/ecs/user-guide/general-purpose-instance-families.
- Images: Alibaba Cloud "Ubuntu image" release notes (`ubuntu_24_04_x64_20G_alibase_20261016.vhd`),
  https://www.alibabacloud.com/help/en/ecs/ubuntu-image.
- Metadata hardening mode: "Instance metadata", https://www.alibabacloud.com/help/en/ecs/user-guide/view-instance-metadata/.
- OpenTofu state encryption: https://opentofu.org/docs/language/state/encryption/; `tofu test` and mocks:
  https://opentofu.org/docs/cli/commands/test/ (OpenTofu has no shared mock files: the mocks live in the test file).
- k3s: GitHub releases of k3s-io/k3s (v1.36.6+k3s1, 2026-11-03; `sha256sum-amd64.txt`), install script at the tag.
- Wildcard DNS: https://nip.io/ (sslip.io and nip.io interchangeable; dashed and dotted forms, subdomains).
- setup-opentofu v2.0.2 (commit a1320f8) for CI.
