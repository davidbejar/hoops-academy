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

## Handover
- Built:
  - **game-service**: `domain.PlayerVisibility` (everyone / only some players), `domain.events.EventVisibility`
    (player events follow their player; PERIOD_START/END, OPPONENT_SCORE, TIMEOUT, NOTE without player are team-level;
    a VOID follows its target through VOID-of-VOID chains, unknown target or cycle = visible), `application.StatVisibility`
    (the one rule: ADMIN / staff of the match's team everything, else PARENT-linked + PLAYER-own). `GetBoxScore` now uses
    it; `GetMatchEvents` filters with it (filtered callers: whole match read, filter, then `after`/`limit`/`hasMore` over
    visible events; `lastServerSeq` stays the match's). Resource unchanged.
  - **Contract** game **2.1.0** (description only, wire unchanged): which types are team-level, VOID rule, seq gaps,
    team figures from `getBoxScore`. `scripts/gen-api.sh game` (core not regenerated; whitespace normalised).
  - **Web**: offline sync needed no change (cursor = max held `serverSeq`, never gap-free; only staff and parents post,
    parents only about linked players, so their events come back). But the live screen scored from the local replay,
    which a filtered feed breaks: `domain/projector/team_figures.dart` (`reconcileTeamFigures` = box-score snapshot +
    local events after its `lastServerSeq` / unsynced), `LiveMatch.team`; controller fetches `GET box-score` for
    non-staff on build, on feed changes and every 15 s; offline fallback = cached match score (period scores / totals
    hidden). Court for non-staff = one "Players" list (subs of others are hidden); tile numbers only for own/linked.
    `feed_visibility.dart` mirrors the rule for `MockGameApi` and the test fakes.
  - Docs: ADR-0028, ADR-0021 §3, authz matrix feed row + note, security review F-01 → Fixed, conformance S-30/R-11,
    guides parent/player/coach (es/en/id), game-service README.
- Verified (fresh, 2026-11-05):
  - Red first: `MatchEventFeedRoleMatrixTest` 16/26 failed (the 8 filtered callers × 2) before the change; unit tests
    and web tests failed to compile / asserted 2 instead of 5. Negative control: periodic refresh disabled → controller
    test fails.
  - `./mvnw -B -ntp -T 1C clean verify`: BUILD SUCCESS; contracts 134, common 172, game **238** (was 196), athlete 586,
    core 701; 0 failures; all coverage checks met (game lines 98.6 %, domain 98.8 %).
  - `just web-test`: 556 passed; `flutter analyze`: no issues. `just isolation-check`: 6 tests passed.
- Decisions/ADRs: ADR-0028 (substitutions are player events; COACH of another team gets the filtered feed like the box
  score; VOID visibility; unfiltered `lastServerSeq`; client team figures from the box score).
- Open points / follow-ups:
  - Filtered feed reads all events of the match per request; push the filter into SQL if it ever shows up in profiles.
  - Hidden players' events reach a parent's score with the next refresh (≤ 15 s online).
  - ADR number: the WP32 brief may also claim 0028 — renumber on merge if WP32 lands first.
  - Commits carry `Co-Authored-By: Claude Opus 5.5` (the model that did the work), not the brief's "Fable 5.1" line.
