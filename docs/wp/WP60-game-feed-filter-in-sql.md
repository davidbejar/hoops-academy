# WP60 — Game: match feed visibility filter in SQL

Model: Opus. Wave 1 (2026-11-06, fourth round): runs alongside WP52 (web), WP56 (realm + OIDC properties), WP58
(core), WP63 (kind), WP64 (workflows). You own `services/game-service` Java and Flyway `V3` (reserved for you),
except the OIDC properties and auth classes (WP56). No contract change expected. Depends on: WP33 / ADR-0030
(`EventVisibility`, feed rules), WP37 (mutation baseline). Skills: quarkus-hexagonal-service,
tenant-isolation-testing, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp60-game-feed-sql`, branch `wp60-game-feed-sql`.

Decision 42 of 2026-11-06: for non-staff callers the feed is filtered in the query, not by walking every event of
the match in memory.

## Scope
1. Read ADR-0030 and the current filter (`EventVisibility`, the feed use case and its repository port). Keep the
   domain rule as the single source of truth: the SQL predicate must be derived from or verified against it (a
   property-style test that compares the SQL result with the in-memory rule on random event sets, jqwik is in the
   build).
2. Repository: a query that takes the caller's visible player ids / team scope and returns only visible events,
   paged as today; `V3__feed_visibility_index.sql` only if an index is needed (RLS policy untouched;
   `RlsSchemaMetaTest` green). The `%3A` batch path and `events:batch` are unaffected.
3. Tests first: the existing feed tests for PARENT/PLAYER/COACH stay green unchanged; the new property test; a
   bound on queries per feed page (no N+1).
4. `docs/adr/0030-*.md` amendment line "filter moved to SQL (WP60)"; `docs/architecture.md` is the docs pass's.

## Acceptance
- [ ] Red tests first; `./mvnw -B -ntp -pl services/game-service -am verify -Dquarkus.http.test-port=0` green
      (totals) and `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation game-service` at or above baseline (record the score)
- [ ] Handover appended with the predicate and the measured query count per page

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
