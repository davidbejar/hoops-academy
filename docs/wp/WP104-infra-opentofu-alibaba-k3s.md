# WP104 — Infra: OpenTofu module for one k3s VM on Alibaba Cloud (Jakarta), cloud values for the chart; code only

Model: Opus · effort high. Wave 1 (2026-11-14, seventh round): runs alongside WP105 (web shell), WP106 (core) and
WP107 (seed script). You own `infra/tofu/**` (new), `deploy/cloud/**` (new), `deploy/helm/hoops/values-cloud.yaml`
(new) and its render snapshot under `deploy/helm/tests`, `docs/runbooks/cloud.md` (new),
`docs/adr/0050-*.md` (new), the OpenTofu lines of `.gitignore`, `scripts/bootstrap.sh` and `.pre-commit-config.yaml`,
your recipes in the `justfile` (after the kind recipes) and one new job in `.github/workflows/ci.yml` (nobody else
touches the workflows on `main` this round). `docs/adr/README.md`: append one line at the end. You change no service
code, no contract, no chart template and nothing under `deploy/kind`. Depends on: decisions 76–78,
`docs/runbooks/kind.md` and `deploy/kind/up.sh` (what the cluster needs before the chart: Envoy Gateway,
CloudNativePG, namespace, secrets), ADR-0012 (secrets), ADR-0031 (Envoy Gateway), ADR-0034 / `images.yml` (images
on ghcr.io). Skills: owasp-security, systematic-debugging, verification-before-completion. Worktree:
`~/code/hoops-wt/wp104-opentofu-alibaba`, branch `wp104-opentofu-alibaba`.

Decisions 76–78 of 2026-11-14 (owner): the first cloud slice targets **Alibaba Cloud, Jakarta region** (international
site); **code only** this round: no account, no API key, no server, nothing applied; the deployment is reached by a
**free wildcard DNS name** derived from the server's public address (sslip.io style), no domain and no DNS record.
ADR-0050 is reserved for you (provider, region, the OpenTofu / Helm split, state, k3s).

## Scope
1. **OpenTofu module** (`infra/tofu/`): the outer layer only: network (VPC, vSwitch), security group, SSH key pair,
   one ECS instance sized for the whole stack (three JVM services, Keycloak, PostgreSQL, Redpanda, Envoy: about
   8 GB RAM), a public address, a data disk if the stack needs one. k3s is installed on first boot by cloud-init, at a
   pinned version. Outputs: the address, the wildcard hostname, how to fetch the kubeconfig. Variables for region,
   instance type, the CIDR allowed to reach SSH and the Kubernetes API (no `0.0.0.0/0` default for either), the SSH
   public key. Pin the OpenTofu version and the provider; commit the lock file. Look the provider's resources,
   arguments and the Jakarta region id up in the current provider documentation rather than writing them from
   memory; the same for instance types and images. Do not quote prices.
2. **State and secrets** (rule 6): local state by default, never in git (`.gitignore`: state, `*.tfvars`, `.terraform/`);
   OpenTofu state encryption with a passphrase from the environment; a `terraform.tfvars.example` with placeholders
   only. The Helm release is **not** managed by OpenTofu, and no application secret enters the state.
3. **Proof without credentials**: `tofu fmt -check`, `tofu validate` and `tofu test` with mocked providers (the
   security group rules, the instance size and the hostname output are asserted); a config scan (`trivy config`, it is
   installed) with every accepted finding justified. Recipe `just tofu-check` runs all of it; one CI job runs the same.
   Write the tests first.
4. **Cloud values** (`deploy/helm/hoops/values-cloud.yaml`): images from ghcr.io, `global.publicUrl` and the gateway
   hostname from the wildcard name, the storage class k3s offers, what must be off or different outside kind. A render
   snapshot like the existing ones (`deploy/helm/tests`). Decide whether k3s's bundled Traefik and ServiceLB stay or go
   in favour of Envoy Gateway as on kind, and record why.
5. **Install script and runbook** (`deploy/cloud/`, `docs/runbooks/cloud.md`): apply, fetch the kubeconfig, install the
   operators and the chart, smoke (the `deploy/kind` smoke scripts against the cloud base URL), destroy. Mark every
   step that was not executed as **not yet run**; next round runs them. List what the owner must do first (account,
   an access key with the least rights that work, where it goes in `.env`, `.env.example` placeholders).
6. **Docs**: ADR-0050; the ADR index line; `scripts/bootstrap.sh` installs `opentofu`.

## Acceptance
- [ ] `just tofu-check` green (fmt, validate, tests, scan), fresh output in the handover; the CI job added
- [ ] Tests committed before the module code they cover
- [ ] The chart renders with `values-cloud.yaml`; the snapshot test is green; `helm lint` clean
- [ ] No state, no `*.tfvars`, no key and no real address in git (`gitleaks` clean)
- [ ] `actionlint` clean on the workflow; `shellcheck` clean on new scripts
- [ ] Handover appended: what is proven and what is only written; the owner's steps for the real apply; open risks
      (single node, no TLS, SSH and API exposure, costs unknown)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- **Never run `tofu apply`, never create a cloud account or resource, never ask for or use a cloud credential.**
- No kind cluster this round (nobody uses kind); the chart is proven by rendering only.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with a
  `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
2026-11-14, Opus. **Code only: nothing was applied, no cloud account or credential was used or asked for, no cluster started.**

- **Built.**
  - `infra/tofu`: VPC 172.20.0.0/16 with one vSwitch in the first zone that sells the instance type. One security group:
    22 and 6443 from `admin_cidrs` only (required, never `0.0.0.0/0`, nothing wider than /16), 80 and 443 public, nothing
    else. Key pair. ECS `ecs.g7.large`: Ubuntu 24.04 system image, ESSD 60 GiB encrypted (`system_disk_encrypted`,
    default true), IMDSv2 only, no public IP of its own. The plan fails below 8 GiB or when no zone sells the type. One
    EIP (pay by traffic) bound to the instance.
  - Outputs: `public_ip`, `hostname` `<a-b-c-d>.sslip.io` (or nip.io), `wildcard_hostname`, `public_url`, `ssh_command`,
    `kubeconfig_command`.
  - cloud-init installs k3s v1.36.6+k3s1. It checks the install script and the binary against pinned SHA-256 sums, turns
    Traefik off and keeps ServiceLB. It also sets `tls-san` to the EIP and hostname, encrypts Secrets at rest and allows
    SSH by key only.
  - Versions: OpenTofu `~> 1.13.9` (`.opentofu-version`), provider `aliyun/alicloud` 2.2.0, lock file with four platforms.
  - State: local, encrypted (pbkdf2 + AES-GCM, `enforced`) with the passphrase in `TF_VAR_state_passphrase`.
    `terraform.tfvars.example` holds placeholders only.
  - `deploy/cloud/`:
    - `kubeconfig.sh` writes `~/.kube/hoops-cloud.yaml` (context `hoops-cloud`).
    - `install.sh <sha>` installs the Secrets from `.env`, Reloader, Envoy Gateway, CNPG (the pins `deploy/kind/up.sh`
      uses), a self-signed `hoops-gateway-tls` and the chart.
    - `with-cloud.sh` runs any `deploy/kind` script against the cloud: `smoke.sh`, `seed-users.sh`, `ratelimit-check.sh`.
  - `deploy/helm/hoops/values-cloud.yaml`:
    - Images come from ghcr.io at the commit tag.
    - HTTPS uses the self-signed certificate with no HSTS, and `publicUrl` is on https. Reason: the realm's
      `sslRequired: external` and PKCE / the service worker need a secure context.
    - Envoy's Service is a `LoadBalancer`, so ServiceLB binds it to the node's ports 80 and 443. Storage uses
      `local-path`.
    - The address values are `.invalid` placeholders that `install.sh` fills in.
  - Chart tests: snapshot `umbrella-cloud` and 14 assertions in `deploy/helm/tests/run.sh`.
  - Recipes: `tofu-check`, `cloud-kubeconfig`, `cloud-install`, `cloud-seed-users`, `cloud-smoke`. CI job `tofu-check`.
  - Repo housekeeping: `scripts/bootstrap.sh` installs `opentofu`. `.pre-commit-config.yaml` has a `tofu-fmt` hook.
    `.gitignore` has the OpenTofu lines. `.env.example` has three empty cloud placeholders at the end.
  - Docs: ADR-0050 with its index line, and `docs/runbooks/cloud.md`.
- **Verified** (fresh, 2026-11-14 22:25):
  - `just tofu-check` → TOFU CHECK PASSED: fmt; init with the lock file read-only; validate; `tofu test` 25 passed,
    0 failed (every run a `plan` against `mock_provider`); trivy config 0 findings; checkov 8 passed, 0 failed;
    shellcheck clean; the 6 cloud pins equal kind's; no state or tfvars tracked.
  - The tests went in first, red (commit a18ad712), and are proven to catch faults. Eight deliberate faults each turned
    them red: SSH open to the world, an SSH CIDR of `0.0.0.0/0`, no /16 guard, the 4 GiB limit, a dotted hostname,
    Traefik on, IMDSv1, an own public IP.
  - `deploy/helm/tests/run.sh` → ALL CHART TESTS PASSED: `helm lint --strict` with the cloud values, kubeconform
    350/350, the new snapshot. Three faults planted in the cloud values were caught: HSTS on, `ClusterIP` instead of
    `LoadBalancer`, no storage class.
  - `actionlint` clean; `gitleaks detect` over this branch's commits: no leaks.
  - `trivy config deploy` with `.trivyignore.yaml`: 0 HIGH/CRITICAL.
  - Not run: `just test`, because no service, contract or web code changed.
- **Decisions/ADRs.** ADR-0050: the provider and region, the OpenTofu/Helm split, encrypted local state, k3s with Traefik
  off and ServiceLB on, the EIP as the stable address, HTTPS with a self-signed certificate. Also: no data disk, and
  `image_id` / `user_data` changes are ignored.
- **Proven vs only written.**
  - Proven, with mocked providers and render only: the module's structure, rules and guards, and the chart values.
  - Only written, every step marked NOT YET RUN in the runbook: plan, apply, cloud-init, the kubeconfig fetch,
    `install.sh`, seed and smoke through `with-cloud.sh`, destroy. Also untested: the `docker run` trivy fallback in CI,
    since this Mac has trivy and Podman.
- **Owner before a real apply** (runbook, "Before the first apply"):
  1. Create an Alibaba Cloud international account with a payment method.
  2. Create a RAM user `hoops-tofu` with programmatic access only and the runbook's regional ECS/VPC policy.
  3. Put its key in `.env` (`ALIBABA_CLOUD_ACCESS_KEY_ID`/`_SECRET`) or in an aliyun profile.
  4. Set `TF_VAR_state_passphrase` (at least 16 characters) and back it up.
  5. Create `terraform.tfvars` with your IP as /32 and your public key.
  6. Pick a main commit whose images are on ghcr.io.
  7. Give `.env` strong, fresh values everywhere (`install.sh` refuses `change-me`).
- **Open points / risks.**
  - Single node: no HA, every volume on one disk, no backups. Self-signed TLS: a browser warning and no service worker,
    so no offline mode. There is no HTTP-to-HTTPS redirect.
  - SSH and the Kubernetes API are exposed to `admin_cidrs`, and the SSH host key is trusted on first use.
  - Costs unknown.
  - Unverified until the apply: that `ecs.g7.large` is sold in Jakarta (the per-region list needs a login), that
    cloud-init reads user data in IMDSv2-only mode, that disk encryption works without extra KMS setup, and that
    ServiceLB keeps the client IP (needed for the per-IP rate limits).
  - The RAM policy is deliberately broad (`ecs:*`/`vpc:*` in the region): narrow it from ActionTrail after the first
    apply.
  - The Envoy Gateway chart and the CNPG manifest are pinned by version, not digest (inherited from kind).
  - `seed-users.sh` and `smoke.sh` read `.env` only, not `ENV_FILE`.
  - Dev users and Mailpit run on a public host.
  - GDPR work is needed before real academies use the deployment.
  - Trivy has no Alibaba Cloud checks: the security assertions live in the tests. Checkov is optional in `check.sh` and
    not in CI.
  - Outside the brief's file list:
    - One path line added to the KSV-0014 entry of `.trivyignore.yaml` for the new snapshot (Keycloak, same reason and
      expiry), so the `trivy-fs` CI job stays green.
    - The `run.sh` additions (the render line and the cloud section).
  - Chart version not bumped: no template or default changed, and `values-cloud.yaml` is a new overlay.
  - Commits ran the pre-commit hooks instead of `--no-verify`: the `--no-verify` commit was refused by the auto-mode
    permission check. `gitleaks protect --staged` ran before each commit.
  - Security review (owasp-security, IaC/CI checklist): nothing exploitable found. The CI job uses `pull_request`,
    SHA-pinned actions and read-only permissions, with no secrets.
