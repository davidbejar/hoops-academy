# WP71 — Chart: wire the services to the event broker, prove the outbox and replicas on kind

Model: Opus. Wave 6 (2026-11-06, fourth round): starts after WP68 and WP69 are merged; runs alone (the only agent;
kind is yours). You own `deploy/helm/**` (umbrella values, `values-kind.yaml`, the `hoops-service` subchart, the chart
tests and snapshots), `deploy/kind/*`, `Tiltfile`, `.trivyignore.yaml`, `docs/runbooks/{events,kind,release}.md`
(sections named below). Nobody else touches them. Do not edit `services/**`, `libs/**`, `apps/**`: if a service needs
a change, say so in your handover. Depends on: WP66 (broker, Secrets `hoops-redpanda-<service>` as basic-auth,
ESO entries), WP67 (core publisher config keys, its handover), WP68 and WP69 (consumer config keys, their handovers),
ADR-0036, ADR-0008 amendment, ADR-0037. Skills: podman-dev-env, owasp-security, verification-before-completion,
systematic-debugging. Worktree: `~/code/hoops-wt/wp71-chart-events`, branch `wp71-chart-events`.

Decision 48 of 2026-11-06 (continued, orchestrator addition): the chart passes the broker settings to the three
services behind `events.enabled`, so the publisher and the replica consumers run on kind; the roster source stays
`rest` by default (ADR-0037 says when it flips). No new ADR.

## Scope
1. **Values and templates** (chart 0.6.0 → 0.7.0): with `events.enabled`, each service Deployment gets
   `KAFKA_BOOTSTRAP_SERVERS=redpanda.<release namespace>.svc.cluster.local:9092`,
   `KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT`, `KAFKA_SASL_USERNAME=<service name>` and `KAFKA_SASL_PASSWORD` from
   Secret `hoops-redpanda-<service>` key `password` (a `secretEnv` entry). With `events.enabled=false`, the core
   publisher is off (`CORE_OUTBOX_POLL_INTERVAL=off`) and the game and athlete consumers are off (their
   `*_ROSTER_CONSUMER_ENABLED=false` keys: take the exact names from the WP68 and WP69 handovers) so no pod logs
   broker warnings. `game.rosterSource` / `athlete.rosterSource` values (default `rest`) map to
   `GAME_ROSTER_SOURCE` / `ATHLETE_ROSTER_SOURCE`; `values-kind.yaml` keeps `rest`. Derive everything from
   `.Values.events` in the umbrella (the subchart receives plain env), so an overlay cannot half-configure it.
2. **Chart tests** (`deploy/helm/tests/run.sh`): assertions first (events on: the four keys and the Secret reference
   on all three Deployments; events off: no `KAFKA_*`, publisher and consumers off; the Secret names equal the ones
   `secrets.sh` and `externalsecrets.yaml` create), then the templates; snapshots re-recorded; kubeconform and the
   policy checks still pass; `shellcheck -S warning` clean.
3. **kind proof**: `up.sh --deploy` with `values-kind.yaml`; `smoke.sh core game athlete` green, extended with an
   "events" block: core readiness `outbox-publisher` UP (not DEGRADED), `hoops_outbox_pending` reaches 0 after the
   seeded roster, the game and athlete replica tables (or their applied/lag metrics) show the seeded aggregates
   with 0 parked. Then flip one service to `replica` on kind (`--set athlete.rosterSource=replica`, a helm upgrade)
   and run the smoke again as evidence for ADR-0037's cutover note (do not change the default). Delete the cluster
   at the end.
4. **Housekeeping**: `.trivyignore.yaml` KSV-0109 statement names the `redpanda-bootstrap` script ConfigMap as well
   as the blocklist (WP66 open point). `tilt alpha tiltfile-result` still evaluates.
5. **Docs**: `docs/runbooks/events.md` section "Kubernetes (chart)" (env, Secrets, how to flip a service to the
   replica, how to see lag); `kind.md` verification status WP71; `release.md` deploy note (chart 0.7.0, events on =
   broker Secrets must exist before the upgrade).

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED with the new assertions (written first; one mutation of each
      fails as expected); `shellcheck -S warning` and `actionlint` clean; `trivy fs` misconfig clean with the
      updated statement
- [ ] kind: `smoke.sh core game athlete` green twice (default `rest`, then athlete on `replica`), output in the
      handover with the publisher health, pending, applied and parked figures; cluster deleted
- [ ] Handover appended (values added, which pods restart on a Secret rotation, what the ADR-0037 cutover still needs)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the lines
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- You are alone: kind, the compose ports and the host are yours. kind proofs are load-sensitive (runbook symptom D);
  keep the Mac awake with `caffeinate -dims -t 14400 &` and kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:**
  - Chart 0.7.0, `hoops-service` 0.5.0. A subchart sees only its own values and `global`, so the umbrella cannot hand
    `.Values.events` to the services: `global.events.enabled` mirrors `events.enabled`, and `templates/events-checks.yaml`
    (renders nothing) refuses a release where the two differ. With it the subchart derives the client itself (plain env
    in its ConfigMap, the password as a `secretKeyRef`): `KAFKA_BOOTSTRAP_SERVERS=redpanda.<namespace>.svc.cluster.local:9092`,
    `KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT`, `KAFKA_SASL_USERNAME=<service>`, `KAFKA_SASL_PASSWORD` from
    `hoops-redpanda-<service>`/`password`. Without it the subchart applies `<service>.events.offEnv`: core
    `CORE_OUTBOX_POLL_INTERVAL=off`, game `GAME_ROSTER_CONSUMER_ENABLED=false`, athlete `ATHLETE_ROSTER_CONSUMER_ENABLED=false`
    (`env` may override them, e.g. for a managed Kafka). New values: `global.events.enabled`, `<service>.events.offEnv`,
    `game.rosterSource` / `athlete.rosterSource` (default `rest`, mapped to `GAME_ROSTER_SOURCE` / `ATHLETE_ROSTER_SOURCE`
    through the templated `env`); `values-kind.yaml` sets `global.events.enabled: true` and keeps `rest`. The render also fails
    when a service lacks its `events.users` entry with Secret `hoops-redpanda-<service>`, when `rosterSource` is not
    `rest|replica`, when it is `replica` without events, and when `env`/`secretEnv` sets `KAFKA_*` while events are on.
  - `deploy/helm/tests/run.sh`: block "services on the event broker" (22 assertions, committed red first in `1a104ab`):
    the four keys and the Secret reference on all three Deployments; Secret names equal to `secrets.sh`, the ESO render and
    the bootstrap Job; events off: no `KAFKA_*`, publisher and consumers off; roster sources; the athlete flip changes only
    `ATHLETE_ROSTER_SOURCE` and the checksum; the five refusals; the subchart alone and with `global.events.enabled`.
    Snapshots re-recorded (chart labels, the new env, the Secret refs and checksums).
  - `deploy/kind/smoke.sh` block "events": publisher readiness `UP`/`OK`, `broker_available`, a SCRAM login per client
    (Kafka client metrics), then a seeded academy (first admin = the seeded `admin1`, linked without a temporary password;
    season, team, player), `hoops_outbox_pending` 0 with the published total up by at least 5, both groups' lag 0, applied
    up by at least 5, parked 0, game lists the team's matches and athlete answers the player's availability (200). The
    roster source of each service is printed. Two existing `rp ... | grep -q` checks rewritten (SIGPIPE + pipefail made them
    flaky: "Healthy: true" reported as a failure once).
  - `deploy/kind/up.sh` restarts core-service when its log shows `SASL authentication failed` after the install (below);
    Tiltfile: core-service depends on `redpanda-bootstrap`, comment updated; `tilt alpha tiltfile-result` evaluates (14
    resources). `.trivyignore.yaml` KSV-0109 statement names the `redpanda-bootstrap` script ConfigMap too.
  - Docs: `events.md` "Kubernetes (chart, WP71)" (env table, refusals, how to watch, the flip, the fresh-install restart,
    Secret rotation), `kind.md` (what runs where, smoke line, troubleshooting entry, verification status WP71),
    `release.md` (chart 0.7.0; both switches; the broker Secrets before the upgrade; restart core once after a fresh install).
- **Verified:**
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED, 134 ok (112 + 22), kubeconform 230/230. 15 mutations, one per new
    assertion (port, Secret name, off env per service, a `KAFKA_*` leak with events off, roster env, flip, `secrets.sh`
    name, each guard, the mirror helper), each killed by its assertion. `shellcheck -S warning` (run.sh, deploy/kind/*.sh),
    `actionlint` clean; `trivy fs --scanners misconfig --severity HIGH,CRITICAL --ignorefile .trivyignore.yaml` exit 0
    (KSV-0109 still fires on both ConfigMaps without the ignore file). `kubectl apply --dry-run=server` of the kind render clean.
  - kind (compose stopped to keep the 2-CPU VM free): fresh `up.sh --deploy --from-host` 5 min 56 s (an earlier cluster
    6 min 53 s). Found: the bootstrap Job is a post-install hook and runs only after `--wait`, so all three services start
    before their users exist (core 14, game and athlete 10 `SASL authentication failed` each). The consumers recover; core's
    idempotent producer does not: records expire ("Expiring 1 record(s) ... 8000 ms"), `hoops_outbox_pending` 6,
    `DEGRADED`, until a restart (then 6 published in 10 s). Steady state recovers: user deleted + broker restarted -> 2
    pending, `DEGRADED`; Job re-run -> 0 pending 10 s later, no restart. Re-run of `up.sh` with the fixed restart branch
    2 min 56 s (`restart core-service` step).
  - `smoke.sh core game athlete`, `rest`: SMOKE PASSED, 46 checks, 10 s: `outbox-publisher: UP OK`, broker available 1,
    SCRAM logins core 2 / game 3 / athlete 3, academy `smoke-1793978327`, published 6 -> 12, game applied 6 -> 12 and athlete
    6 -> 12 (+6 each: tenant, 2 persons, team, player, team-player), group lag 0, parked 0, max event lag 0.84 / 0.87 s,
    game 200, athlete `available=true` (roster source rest).
  - `helm upgrade ... -f values-kind.yaml --set athlete.rosterSource=replica --wait` (revision 3, 11 s): only the athlete pod
    was replaced, log `Roster source: REPLICA (replica consumer on)`. Smoke: SMOKE PASSED, 46 checks, 14 s: published
    12 -> 18, game 12 -> 18 (lag 0.41 s), athlete 0 -> 6 after its restart (lag 5.15 s), parked 0, athlete answered from the
    replica. core scaled to 0: athlete still 200 for that player, 404 for an unknown one, core 503. Third smoke after core
    came back: PASSED (46). Cluster deleted afterwards.
- **Decisions/ADRs:** no new ADR (decision 48 as briefed). The mirror `global.events.enabled` plus a refusing guard instead
  of a single key: Helm gives a subchart no access to its parent's values; renaming the switch to `global.*` would have
  broken the documented `events.enabled`. The bootstrap address, user and Secret name follow the service's name by
  convention (no per-service knobs), checked against `events.users`. The start-up race is mitigated in `up.sh`/Tilt, not in
  the chart (an init container waiting for the user would deadlock with `--wait`, since the Job runs after it).
- **Open points / follow-ups:**
  - core-service (not my files): the idempotent producer must recover when its first producer-id request failed
    authentication (e.g. recreate the emitter, or a liveness signal after a long `DEGRADED` with backlog and no send since
    start). Until then every fresh Helm install needs `kubectl rollout restart deploy/core-service` after the Job.
  - Secret rotation of `hoops-redpanda-<service>`: only that service's pod needs a restart (env var; Helm does not roll it,
    the checksum covers the ConfigMap only), after the Job (`helm upgrade`) set the new password; the superuser restarts
    `redpanda-0` (events.md).
  - ADR-0037 cutover still needs: core's backfill of pre-WP67 aggregates, a shadow period with parked 0 and lag in seconds,
    `just e2e` green with `replica` for both services, the producer fix above; then flip the defaults. The game flip was not
    run on kind; `applied_event` pruning is still open.
  - Not run: a deploy with `events.enabled=false` (no broker warnings: render assertions only), `tilt ci`, `--eso` with events.
  - Docs pass: ADR-0036 and ADR-0037 mention `events.enabled` alone (now with `global.events.enabled`; ADR-0037's "the chart
    wires the services' Kafka client" is done); `docs/architecture.md`; HANDOVER/FOLLOW-UPS (producer fix). compose was
    stopped for the proof (`just down`) and started again afterwards.
