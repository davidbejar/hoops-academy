# WP46 — Gateway: Redis ACL for the rate-limit service, burst cap per second

Model: Opus. Wave 1 (2026-11-06, third round): runs alongside WP43 (Java), WP48 (web) and WP50 (workflows); you own
`deploy/`, `Tiltfile` and the kind/deploy runbooks, and you are the only agent using kind. Depends on: WP40
(ADR-0033). Skills: podman-dev-env, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp46-gateway-hardening`, branch `wp46-gateway-hardening`.

Decision 27 of 2026-11-06: (a) the rate-limit service's Redis access is restricted by a Redis ACL, not only by the
NetworkPolicy; (b) the fixed one-minute windows get a second, per-second rule so a minute-boundary burst cannot pass
twice the limit.

## Scope
1. Read ADR-0033, the WP40 handover, `deploy/helm/hoops/templates/*redis*`, `deploy/kind/up.sh` (Envoy Gateway
   values: rate-limit backend) and `deploy/kind/ratelimit-check.sh`.
2. **ACL**: a Redis user for the rate-limit service with only the commands `envoyproxy/ratelimit` issues (check its
   source for the Redis commands it uses: INCRBY/EXPIRE/pipelines, PING, no scripting, no admin) on the key pattern it
   uses; `default` user disabled or reduced to nothing. Credentials: a Kubernetes Secret created by `deploy/kind/
   secrets.sh` on kind and documented for other clusters (ADR-0012 pattern: Secrets first), referenced by the Redis
   ConfigMap/args (ACL file or `--requirepass` + `ACL SETUSER` at start) and by the Envoy Gateway rate-limit backend
   configuration (Envoy Gateway v1.9 reads the Redis URL / auth from its config; find the supported way — URL with
   credentials or a Secret reference — and if the controller cannot take credentials at all, document that and fall
   back to a password-less user limited to the needed commands + the NetworkPolicy). Nothing secret in git
   (`gitleaks` on rendered output is already in the chart tests).
3. **Burst cap**: per limited route a second global rule with `unit: Second` (defaults: token and login form 10/s,
   `events:batch` 20/s; values-configurable next to the per-minute numbers). Both rules per client IP.
4. **Prove on kind**: `up.sh --deploy`; Gateway Programmed, policies Accepted; `ratelimit-check.sh` extended: the
   per-minute numbers as before, plus a tight burst (e.g. 40 requests in one second) that gets 429 from the per-second
   rule; a `redis-cli` from a pod with the limited user proving a disallowed command (e.g. `CONFIG GET`, `EVAL`) is
   refused and the default user cannot authenticate; the `redis-down` mode still fails open. Smoke green. Delete the
   cluster at the end.
5. **Docs**: ADR-0033 "Amendment 2026-11-06" (no new number), runbooks (kind, release §4, troubleshooting), threat
   model row for the rate-limit store, `docs/security/asvs-checklist.md` if it has a row for it. Chart version bump
   (0.3.0 → 0.3.1 or 0.4.0 if values changed shape), snapshots updated after review.

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED; `helm template` of kind values renders no credential
- [ ] kind: ratelimit-check PASSED incl. the per-second burst case; ACL proof recorded; redis-down still fails open;
      smoke green
- [ ] `shellcheck -S warning` clean on touched scripts; docs updated; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds on the same Podman machine; keep the cluster to the kind values and delete it
  when done.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:** chart 0.4.0 (umbrella; `keycloak` and `hoops-service` subcharts 0.4.0, new values `route.rateLimit.rps`,
  `route.rateLimits[].rps`, `rateLimit.redis.acl.*`). `ratelimit-redis` gets an init container that writes
  `/acl/users.acl` into a memory `emptyDir` (read-only for `redis-server --aclfile`): `default` off without password or
  permissions; `ratelimit` on, SHA-256 of the password from Secret `hoops-ratelimit-redis`, keys `~hoops/hoops/*`
  (rate limit domain = Envoy Gateway listener `<ns>/<gateway>/<listener>`), `-@all +ping +incrby +expire`. Those are
  the only commands envoyproxy/ratelimit `5ae0682e` sends (checked in its source: PING at connect, INCRBY + EXPIRE
  pipeline, AUTH; GET and EVAL only for features Envoy Gateway does not use). Envoy Gateway v1.9.3 has no credential
  field: the rate limit pods get `REDIS_AUTH=ratelimit:<pw>` through
  `rateLimitDeployment.container.env` from Secret `envoy-gateway-system/envoy-ratelimit-redis-auth`. Not `redis.urlRef`
  with a credential URL: the service logs the URL unmasked. Per-second rules: 10/s token + login form, 20/s
  `events:batch`, per client IP v4 + v6, next to the per-minute rules. `secrets.sh` renders both Secrets from `.env`
  `RATELIMIT_REDIS_PASSWORD` (new, in `.env.example`); `up.sh` applies Secrets before the Envoy Gateway install;
  Tiltfile groups the new Secrets. `ratelimit-check.sh`: per-minute bursts paced below `rps`, a tight `curl --parallel`
  burst, an `acl` mode, `LC_ALL=C`.
- **Found on kind:** Envoy Gateway v1.9.3 builds the `sourceCIDR` descriptor without the rule index, so the minute and
  second rules collapsed into one descriptor (`/rlconfig`: MINUTE only; every request counted twice, first 429 at
  rpm/2; no per-second limit). Fix: an always-true `path: {type: PathPrefix, value: /}` selector on the per-second
  rules (commit c1a485b, asserted by the chart tests, ADR amendment + troubleshooting symptom C).
- **Verified:** `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED (85 checks, kubeconform 147/147, snapshots re-recorded
  after reviewing the diff; gitleaks clean, no Secret rendered); `helm package` OK; `shellcheck -S warning` clean
  (`deploy/kind/*.sh`, `run.sh`); `tilt alpha tiltfile-result` evaluates. kind (`up.sh --deploy --from-host`, 1 Envoy
  replica): `apply --dry-run=server` clean, Gateway Programmed, both policies Accepted, `smoke.sh core game athlete`
  SMOKE PASSED. `ratelimit-check.sh` PASSED: events:batch 250 paced in 31 s, 120 passed, first 429 #121; token 130 in
  31 s, 60 passed, first 429 #61; tight bursts 60 at once -> 20 passed / 40 x 429, 40 at once -> 10 passed / 30 x 429;
  ACL: anonymous `NOAUTH`, `default` `WRONGPASS`, `ratelimit` PONG / INCRBY / EXPIRE on its keys, `NOPERM` for other
  keys and GET, EVAL, FLUSHALL, KEYS, SET, ACL, INFO, SCRIPT, MULTI, CONFIG unknown. `redis-down` PASSED (130
  requests, 0 x 429, 15 s; #121 again after restart). The password appeared in no log, pod spec, EG config or render.
  Re-running `up.sh` left the controller untouched. Cluster deleted. `just test` not run (no Java/pom/contract/web change).
- **Decisions/ADRs:** ADR-0033 "Amendment 2026-11-06" (no new number).
- **Open points:** pending user action: add `RATELIMIT_REDIS_PASSWORD` to the main `.env` (else `secrets.sh` stops).
  Rotation needs Redis and `envoy-ratelimit` restarted together (no checksum trigger; documented). A wrong login fails
  open silently except for `WRONGPASS`/`NOPERM` in the logs. The descriptor collision is an upstream Envoy Gateway
  issue worth reporting; drop the path selector once fixed. Not re-run: 2 Envoy replicas, `tilt ci`, the
  controller-restart branch of `up.sh`.
