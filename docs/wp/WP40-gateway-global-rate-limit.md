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

## Handover
- **Built:** chart 0.3.0 (umbrella; `keycloak` and `hoops-service` subcharts 0.3.0). The token endpoint, login form and
  `events:batch` BackendTrafficPolicies use `rateLimit.global.rules` (same per-IP numbers, `sourceCIDR Distinct` v4 + v6,
  `%3A` regex), no `local` rules; `rateLimit.type` is not written because Envoy Gateway v1.9.3's CRD marks it
  deprecated ("Use Global and/or Local fields directly"). `ratelimit-redis` (Redis 8.10.3-alpine, tag-pinned with
  optional digest; in memory only, 24 MB LRU, `CONFIG` renamed away, uid 999, read-only root FS, drop ALL, no SA token,
  16–64 Mi) behind `rateLimit.redis.enabled` (on in `values-kind.yaml`), or `rateLimit.redis.url` for an external Redis.
  Its NetworkPolicy admits only `envoy-gateway-system` pods labelled `app.kubernetes.io/name: envoy-ratelimit` and denies
  all egress. New chart NOTES list the Envoy Gateway values. `deploy/kind/up.sh` pins
  `config.envoyGateway.rateLimit` (backend Redis `ratelimit-redis.<ns>.svc.cluster.local:6379`, `failClosed=false`,
  `timeout=100ms`, envoy-ratelimit 10m/32–128 Mi) and restarts the controller when its config changes.
  `ratelimit-check.sh` waits for a fresh one-minute window and asserts the first 429 at rpm+1 exactly, plus that every
  Envoy replica served part of the burst; its new `redis-down` mode stops Redis, expects no 429, restarts Redis and
  re-checks. The Tiltfile groups Redis as resource `ratelimit-redis` (infra). ADR-0033 written; ADR-0031 marks
  decision 4 replaced.
- **Docs:** ADR README row; `release.md` section 4 carries the Envoy Gateway values for other clusters (there is no
  `docs/runbooks/deploy.md`: the deploy runbook is that section); `kind.md` (wiring, capacity, checks, troubleshooting,
  verification); `troubleshooting.md` (429 too early / never); `architecture.md` edge paragraph; threat model (rows +
  new Redis tampering row), ASVS checklist, security review F-04 wording, roadmap.
- **Verified:** `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED (79 checks, kubeconform 147/147, 5 snapshots re-recorded
  after reviewing the diff; 0 `local:` in any render, and the new assertions fail on the old render); `helm package`
  OK; `shellcheck -S warning` (deploy/kind/*.sh, run.sh) and `actionlint` clean; `tilt alpha tiltfile-result` evaluates.
  On kind (Envoy Gateway v1.9.3, ratelimit image `5ae0682e`, `up.sh --deploy --from-host`):
  `kubectl apply --dry-run=server` clean; Gateway Programmed; both BackendTrafficPolicies `Accepted=True`;
  `smoke.sh core game athlete` SMOKE PASSED. `ratelimit-check.sh` PASSED with **1 replica** (events:batch 250 sent,
  120 passed, first 429 at #121; token 130 sent, 60 passed, first 429 at #61) and with **2 replicas** (identical
  numbers; both replicas in the access logs; the client IP Envoy sees is the SNAT'd node IP for both).
  **Redis down** (`ratelimit-check.sh redis-down`, 2 replicas): 130 requests in 15 s, all passed, 0 × 429 (fail open;
  each one waits up to the 100 ms timeout); envoy-ratelimit stayed up and reconnected by itself; after Redis was back
  the first 429 was #121 again. NetworkPolicy probe: a `hoops` pod and an unlabelled `envoy-gateway-system` pod time
  out, a pod with the envoy-ratelimit label gets `+PONG`. Re-running `up.sh` on the live cluster left the controller
  untouched (config unchanged). Cluster deleted with `deploy/kind/down.sh`. `just test` not run: no Java, pom,
  contract, web or compose file changed.
- **Decisions/ADRs:** ADR-0033 (global limits, Redis without password behind the NetworkPolicy, `failClosed=false`,
  timeout 100 ms instead of 20 ms, fixed windows allow up to 2 × rpm across a minute boundary, no gateway body-size
  limit accepted).
- **Open points / follow-ups:** the restart-on-config-change branch of `up.sh` was not exercised (only the unchanged
  path). A Redis ACL (`-@scripting -@dangerous`) would be defense-in-depth beyond the NetworkPolicy; not done because it
  needs a kind re-test. The NetworkPolicy needs an enforcing CNI, as do the chart's other policies. Per-IP limits can be
  dodged by rotating addresses (an IPv6 /64), as before. `tilt ci` not run (WP42); `mailhog` and the service
  NetworkPolicies are still "uncategorized" in Tilt (pre-existing). The orchestrator could add a HANDOVER line.
