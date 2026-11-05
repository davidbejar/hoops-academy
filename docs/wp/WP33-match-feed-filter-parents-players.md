# WP33 — Match event feed filtered for parents and players (security finding F-01)

Model: Opus. Wave 2: starts after WP28 and WP29 are merged (web match screens; game contract). Depends on: WP7,
WP13, WP29. Skills: test-driven-development, tenant-isolation-testing, quarkus-hexagonal-service, owasp-security,
flutter-feature, verification-before-completion. Worktree: `~/code/hoops-wt/wp33-feed-filter`, branch
`wp33-feed-filter`.

Decision 5 of 2026-11-05: `GET /api/game/matches/{id}/events` returns every player's events to PARENT and PLAYER
members, while the box score hides other players' lines. The feed must be filtered server-side: team-level events
(score, period, timeouts, team fouls, substitutions? decide and document) for everyone; player events only for the
viewer's own player (`ownPlayerId`) or linked players (`linkedPlayerIds`) from the `AuthzContext`. Staff (ADMIN,
COACH, ASSISTANT_COACH) keep the full feed.

## Scope
- Read `docs/domain/authz-matrix.md` (feed and box-score rows), `docs/security/review-2026-11.md` F-01, the game
  feed use case and its resource, and how the box score already applies the own/linked rule (reuse that rule; one
  place decides visibility).
- Define the filter in the domain/application layer, not in the resource; a `MatchEvent` is visible to a
  non-staff viewer iff it has no player or its player is own/linked. Clarify in the contract description which event
  types are team-level.
- Offline sync (`events:batch`, client sequence numbers): a filtered feed must not break the client's reconciliation
  for PARENT/PLAYER (they do not score; confirm in `apps/web` and in WP13's handover that only staff post events; if
  the client assumes a gap-free sequence, say so and handle it).
- Contract (game, minor bump): document the filtering; `just gen-api`.
- Web: the live match screen for a PARENT/PLAYER session renders the filtered feed without error; widget test.
- Authz matrix row updated; role-matrix API test extended (`@ParameterizedTest` over roles: staff see N events,
  PARENT with a linked player sees team events + that player's, PLAYER sees team + own, PARENT with no link sees
  team events only); cross-tenant 404 untouched.
- Guides (`docs/guides/*.md`, es/en/id) if they describe the feed.
- Security review: F-01 → resolved by WP33.

## Acceptance
- [ ] Failing tests first (application rule unit tests + role-matrix API test), then the change
- [ ] `./mvnw -B -ntp -T 1C verify` green (fresh; totals), `just web-test` green, `just isolation-check` green
- [ ] Authz matrix and contract updated; handover appended; ADR only if a visibility rule needed a judgment call
      (then ADR-0028)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
