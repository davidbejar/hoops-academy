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
