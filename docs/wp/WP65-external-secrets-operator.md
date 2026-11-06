# WP65 — Chart: Secrets from the External Secrets Operator (ADR-0012)

Model: Opus. Wave 2 (2026-11-06, fourth round): starts after WP63 is merged (kind); runs alongside WP53, WP55, WP57,
WP59, WP61; you are the only agent using kind this wave. You own `deploy/helm/**`, `deploy/kind/*`, `Tiltfile`,
`docs/runbooks/{kind,deploy-related,rotate-secrets}.md`, `docs/adr/0012-*.md` (amendment). Depends on: ADR-0012
(Secrets created first, out of the chart), WP46 (`hoops-ratelimit-redis`, `envoy-ratelimit-redis-auth`). Skills:
owasp-security, podman-dev-env, verification-before-completion. Worktree: `~/code/hoops-wt/wp65-eso`, branch
`wp65-eso`.

Decision 47 of 2026-11-06: the chart can source every Secret it needs from the External Secrets Operator
(`ExternalSecret` objects behind a values switch), with `secrets.sh` kept for kind and small installs. ADR-0012
gets an amendment (no new number).

## Scope
1. Inventory every Secret the chart and `deploy/kind/secrets.sh` reference (DB credentials for the three roles,
   Keycloak admin and client secrets, SMTP, the rate-limit Redis password, TLS); list them with the consumer in
   the runbook.
2. Chart: `externalSecrets.enabled` (default false), `externalSecrets.storeRef` (ClusterSecretStore name/kind),
   `refreshInterval`, one `ExternalSecret` per Secret with the same resulting Secret names/keys so the workloads do
   not change; `kubeconform` needs the ESO CRD schemas (add them to the chart tests' schema location, pinned ESO
   version); snapshot `umbrella-eso`; policy assertions apply.
3. kind proof: install ESO (pinned version) with the `fake` provider (or a Kubernetes-provider store backed by a
   bootstrap Secret) in `up.sh --eso`; deploy with `externalSecrets.enabled=true`; the stack comes up without
   `secrets.sh`; `smoke.sh` green; delete the cluster at the end.
4. Rotation: `rotate-secrets.md` gains the ESO path (change the source, ESO refreshes, which pods restart).

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED incl. the ESO snapshot and kubeconform with the CRDs
- [ ] kind: stack up through ESO, smoke green (evidence); cluster deleted
- [ ] `shellcheck -S warning` clean; ADR-0012 amendment and runbooks; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds and the compose stack (WP57 owns ports 8080/5432) on the same machine;
  keep the cluster to the kind values and delete it when done.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
