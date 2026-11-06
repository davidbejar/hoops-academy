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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
