# WP115 — Small fixes: language and theme on the academy chooser, compose nginx limits, audit wording

Model: Sonnet · effort medium. Wave 1 (2026-11-15, eighth round): runs alongside WP111 (compose.yaml, chart, CI),
WP112, WP113 (poms) and WP114 (Containerfile). You own `apps/web/lib/features/tenant/**` with its tests and goldens,
`infra/compose/nginx.conf` (and `infra/compose/nginx/**`), `docs/domain/audit-events.md`. No other WP touches
`apps/web` in this wave. Depends on: the WP105 handover (avatar menu, pickers), ADR-0033 (the gateway's limits),
ADR-0044, ADR-0048. Skills: flutter-feature, test-driven-development, clean-code, verification-before-completion.
Worktree: `~/code/hoops-wt/wp115-small-fixes`, branch `wp115-small-fixes`.

Decision 100 of 2026-11-15 (owner): the small fixes bundle.

## Scope
1. **Academy chooser**: someone with several academies who has not chosen one can change language and theme there
   (reuse WP105's pickers; the chooser sits outside the shell). Widget tests first; goldens in light and dark.
2. **Compose nginx**: `limit_req` for the CSV export paths and the public `POST /platform/academy-requests`, with
   the gateway's numbers (10/min + 2/s per IP, ADR-0033 and its amendments); a 429 answers as the existing zones do.
   Prove with a loop of requests against `just up` (record the first 429).
3. **Audit wording**: `docs/domain/audit-events.md`, `team.roster_exported`: ADMIN or the team's *current* coach
   (decision 83).

## Acceptance
- [ ] Red tests committed before the web change
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] nginx: `nginx -t` passes in the container; the 429 observed for both paths
- [ ] Handover appended: the new goldens, the limits as configured

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- Built:
  - Academy chooser (`app/screens/tenant_switcher_screen.dart`, the screen for `NeedsTenant`): language and theme cards
    below the list. WP105's two cards were extracted from the avatar menu into `LanguageSection` / `ThemeSection`
    (`app/avatar_menu.dart`, same keys `lang-*`, `theme-*`, same `chooseLanguage` incl. server `updateLocale`); the avatar
    menu uses the same widgets, behaviour unchanged. The profile screen still has no picker (not in scope).
  - Tests: red first (981a0f60): `test/app/tenant_switcher_test.dart` (pickers present, language stored and applied,
    theme stored), `test/golden/chooser_golden_test.dart`.
  - Goldens new: `chooser_{360x780,1024x768}_{light,dark}.png`. No other golden changed.
  - nginx (`infra/compose/nginx.conf`, new `nginx/export-limits.conf`): zones `export_min` 10r/m and `export_sec` 2r/s per
    IP, applied with `burst=9 nodelay` and `burst=1 nodelay` to `roster:export`, `/api/core|/platform/audit-events:export`
    and `= /platform/academy-requests`; 429 from `limit_req_status`. nginx decodes `%3A`, so one regex covers both forms.
  - `docs/domain/audit-events.md`: `team.roster_exported` now "ADMIN or the team's current coach (decision 83)".
- Verified: `flutter analyze` no issues; `just web-format-check` 0 changed of 456; full `flutter test` (apps/web): 1507 passed, 0 failed.
  nginx proved on a throwaway container (`nginx:1.30-alpine`, port 18115, backend absent so allowed requests
  answer 502): `nginx -t` ok; `POST /platform/academy-requests` at one request per 0.6 s: 11 x 502, first 429 at
  request #12 (10 burst plus one refill at 6 s); the three export paths, incl. `%3A`, answered 429 at once (they share
  the same per-IP zones); 4 fast requests: 429. The shared `just up` nginx was not reloaded (it mounts the main checkout's
  files); the change takes effect there after merge and `podman exec hoops-nginx nginx -s reload`.
- Decisions/ADRs: none. The zones are shared by all four paths per client IP (the gateway counts per route): stricter,
  accepted for the dev proxy.
- Open points: the profile screen (outside the shell) still has no language/theme picker; the chooser lives in
  `app/screens`, outside the brief's `features/tenant` ownership (no other WP touched it).
