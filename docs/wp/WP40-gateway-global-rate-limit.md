# WP40 — Gateway: global rate limiting (Envoy rate limit service + Redis)

Model: Opus. Wave 1 (2026-11-06): runs alongside WP38 and WP39 (services, web); you own `deploy/`, `Tiltfile`,
`deploy/kind/*` and the related runbooks; nobody else touches them. You are the only agent using kind in this wave.
Depends on: WP36 (ADR-0031). Skills: podman-dev-env, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp40-gateway-ratelimit`, branch `wp40-gateway-ratelimit`.

Decision 18 of 2026-11-06: the per-replica local limits of WP36 become global limits shared by every Envoy replica.
The gateway still sets no request body-size limit: the services' 2 MB limit is the control (accepted, record it in the
ADR).

## Scope
1. Read `docs/adr/0031-gateway-api.md`, `deploy/helm/hoops/charts/hoops-service/templates/httproute.yaml` (the
   `BackendTrafficPolicy` with `rateLimit.local`), the keycloak chart's equivalent, `deploy/kind/up.sh` (Envoy Gateway
   v1.9.3 install), `deploy/kind/ratelimit-check.sh`, `deploy/helm/tests/run.sh` and the snapshots.
2. **Envoy Gateway configuration**: enable the global rate limit service in the Envoy Gateway Helm install
   (`config.envoyGateway.rateLimit.backend` of type Redis, pointing at a Redis Service) so Envoy Gateway deploys its
   `envoy-ratelimit` Deployment. Pin the values in `deploy/kind/up.sh` next to the version pins; document the same
   values for other clusters in the deploy runbook (the cluster operator owns the Envoy Gateway install; the chart
   does not).
3. **Redis**: smallest sane deployment for the rate-limit counters, in the umbrella chart behind a values switch
   (`rateLimit.redis.enabled`, on for kind; off by default with `rateLimit.redis.url` for an external Redis). No
   persistence needed, no password needed inside the cluster but the NetworkPolicy must allow only the
   `envoy-gateway-system` rate-limit pods to reach it; read-only root FS, non-root, resource limits like the other
   pods; image pinned by tag (and digest if the other images are). The chart policy assertions in
   `deploy/helm/tests/run.sh` apply to it.
4. **Policies**: `rateLimit.type: Global` with `global.rules` per client IP (`sourceCIDR` type `Distinct`, same
   numbers as today: 60/min token and login form, 120/min `events:batch`, the `%3A` regex); remove the local rules.
   Keep the policy per HTTPRoute as now. Snapshots updated after reviewing the diff; `helm template` renders no
   `local:` rate limit any more.
5. **Prove it on kind**: `just kind-up --deploy --from-host` (or `up.sh --deploy`), Gateway Programmed, policies
   Accepted, `deploy/kind/ratelimit-check.sh` passes; then scale the Envoy proxy to 2 replicas (EnvoyProxy
   `replicas: 2` or `kubectl scale`) and run the check again: the first 429 must still arrive at the same request
   number (a shared counter), which is the whole point. Record both results in the handover. `smoke.sh core game
   athlete` green. Delete the cluster with `deploy/kind/down.sh` at the end.
6. **Docs**: ADR-0033 `docs/adr/0033-gateway-global-rate-limit.md` (why global, the Redis dependency, what happens
   when Redis is down: Envoy's `failureModeDeny` choice, make it explicit and test it: stop Redis, requests still
   pass if `failureModeDeny: false`), row in `docs/adr/README.md`, `docs/runbooks/{deploy,kind,troubleshooting}.md`,
   `docs/architecture.md` edge paragraph, `docs/security/threat-model.md` if it names the local limits. `Tiltfile`
   if the new objects need a resource group (WP42 re-runs `tilt ci` after you; leave it consistent).

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED; snapshots reviewed; no `local:` rate limit rendered
- [ ] kind: ratelimit-check PASSED with 1 and with 2 Envoy replicas (numbers in the handover); smoke green; Redis-down
      behaviour observed and documented
- [ ] `actionlint` and `shellcheck -S warning` clean on anything you touched; ADR-0033 written; runbooks updated
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds on the same Podman machine while your kind cluster is up; keep the cluster
  small (the kind values) and delete it when done.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
