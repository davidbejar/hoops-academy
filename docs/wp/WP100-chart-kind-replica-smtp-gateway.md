# WP100 — Chart and kind: replica by default, core SMTP, Envoy Gateway v1.10.0, pending proofs

Model: Opus · effort high. Wave 3 (2026-11-10, sixth round): starts after WP98 and WP96 are merged; runs alongside
WP101 (web only). You are the only kind user of the round. You own `deploy/helm/**`, `deploy/kind/**`,
`docs/runbooks/kind.md`, the chart parts of `docs/runbooks/events.md`, `rotate-secrets.md` and `observability.md`,
and the ADR amendments named below. Depends on: WP98's handover (roster source default), WP91's handover (the
events-off property of core), WP96's handover (rate-limit entries for the export paths), WP90 (SMTP keys), WP89
(pin shapes), ADR-0031 (Gateway API matrix), ADR-0033 (rate limits), ADR-0012 (Reloader), ADR-0037. Skills:
podman-dev-env, owasp-security, systematic-debugging, verification-before-completion. Worktree:
`~/code/hoops-wt/wp100-chart-kind`, branch `wp100-chart-kind`.

## Scope
1. **Roster source** (decision 66): `game.rosterSource` and `athlete.rosterSource` default to `replica` where
   events are on; a release with events off keeps `rest` (the render already refuses `replica` without events);
   `deploy/helm/tests/run.sh` asserts the new defaults; `values-kind.yaml` comment updated.
2. **Events off stays quiet**: set core's events-off environment variable from WP91 through the chart's
   `core.events.offEnv`; proof on kind with `events.enabled=false`: no producer WARN lines in core for five minutes.
3. **Fresh install without the core restart**: remove the restart after `SASL authentication failed` from
   `deploy/kind/up.sh` and the sentence in the runbook; proof: a fresh `up.sh` where core's producer recovers by
   itself and an event reaches both replicas.
4. **Core SMTP**: `SMTP_HOST: mailhog`, `SMTP_PORT: "1025"`, `SMTP_START_TLS: OPTIONAL`, `MAIL_FROM`,
   `HOOPS_PUBLIC_URL` from `global.publicUrl`; for a real server `SMTP_USERNAME` and a `secretEnv` `SMTP_PASSWORD`
   (Secret `hoops-smtp`, key `password`, optional). Proof: reject an academy request on kind and see the mail in
   Mailpit.
5. **Rate limits** for WP96's export paths (per IP and per user as ADR-0033 does for comparable reads).
6. **Envoy Gateway v1.9.3 → v1.10.0**: check the Gateway API compatibility matrix (ADR-0031 amendment with the
   result), keep the pin shapes `scripts/bump_pins.py` expects, run `ratelimit-check.sh`. Test whether v1.10.0
   still builds the `sourceCIDR` descriptor without the rule index: if it is fixed, drop the `path: /` selector
   (ADR-0033 amendment); if not, keep it and say so. If the bump breaks something you cannot fix inside this WP,
   stay on v1.9.3 and report.
7. **Proofs still open**: the Keycloak `ResponseHeaderModifier` headers (SD-08) seen with `curl` on kind; a
   rotation of `RATELIMIT_REDIS_PASSWORD` rolled by Reloader and limits still applied.
8. **Chart 0.10.0** (and the subcharts that changed), covering the unversioned changes since 0.9.0 (WP84, WP85);
   chart tests and kubeconform green.
9. **Drift check on kind**: the kind variant of `scripts/events-drift.sh` from WP98's handover run after the
   backfill, exit 0.

## Acceptance
- [ ] Chart tests (`deploy/helm/tests/run.sh`) and kubeconform green (totals)
- [ ] On kind: `deploy/kind/up.sh --eso --deploy --from-host` from a fresh cluster, `smoke.sh` passes with "roster
      source replica", and each proof of 2, 3, 4, 6, 7 and 9 with the command and the observed output in the
      handover
- [ ] `python3 scripts/bump_pins.py --check` still parses every pin (exit 0 or 1, never 2)
- [ ] Handover appended: chart and subchart versions, ADR amendments, what the docs pass must say in HANDOVER

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.
- Stop the compose stack before starting kind (`just down` is allowed for you only, and only after the
  orchestrator confirms no other agent needs compose) and start it again when you finish (`just up`, then tell the
  orchestrator to run `just seed-users`). Use the load guard (`HOOPS_LOAD_WAIT`). Delete the kind cluster at the end.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
