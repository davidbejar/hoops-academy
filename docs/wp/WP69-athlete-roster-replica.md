# WP69 — Athlete: roster replica from core events behind `RosterPort`

Model: Opus. Wave 5 (2026-11-06, fourth round): starts after WP67 is merged; runs alongside WP68 (game, same
design, disjoint files). You own `services/athlete-service` and Flyway `V6` (reserved), the athlete section of
`docs/adr/0037-*.md` (WP68 writes the ADR; append your section at the end; if the file does not exist yet when you
need it, write your section in your handover and the orchestrator merges it) and of `docs/runbooks/events.md`.
Depends on: WP67 (event contracts, publisher), WP19 brief, `RosterPort` (`services/athlete-service/.../
application/RosterPort.java`), the membership cache. Skills: quarkus-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp69-athlete-replica`, branch `wp69-athlete-replica`.

Decision 48 of 2026-11-06 (continued): athlete keeps a local replica of the roster data it reads from core, fed by
the events, selectable with `hoops.roster.source=rest|replica` (default `rest`).

## Scope
Mirror WP68 for athlete:
1. `V6__roster_replica.sql`: the `*_ref` tables `RosterPort` and the authz context need (tenant tables with RLS,
   covered by the generic suites) plus the idempotency table.
2. Consumer per topic: upsert by `aggregateId` with `occurredAt` ordering, duplicate `eventId` ignored, tenant
   binding from the event, schema validation against `libs/contracts/events`, park on violation, metrics.
3. `RosterPort` replica adapter; port contract tests parameterised over both adapters; `hoops.roster.source`.
4. Replay command/documentation; test: replica equals the fixture after replay from empty.
5. Docs: your ADR-0037 section; runbook section.

## Acceptance
- [ ] Red tests first; RLS suites green for the new tables; `./mvnw -B -ntp -pl services/athlete-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals)
- [ ] Port contract tests green on both adapters; replay, duplicate and out-of-order tests green
- [ ] `just mutation athlete-service` at or above baseline; `just e2e` 21/21 on compose with `replica` for athlete
      (evidence; coordinate the compose stack with WP68 through the orchestrator); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
