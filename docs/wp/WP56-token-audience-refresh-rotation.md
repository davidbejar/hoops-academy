# WP56 — Realm and services: token audience per service (F-14), refresh-token rotation (F-08)

Model: Opus. Wave 1 (2026-11-06, fourth round): runs alongside WP52 (web), WP58 (core service), WP60 (game
service), WP63 (kind), WP64 (workflows). You own `infra/keycloak/realm-academy.json`, the realm copies the chart
holds (`scripts/sync-chart-files.sh`), `src/main/resources/application*.properties` of the three services (OIDC
section only), `libs/common-quarkus` auth code and tests, `e2e/` token helpers, `apps/web/lib/core/auth` (if the
client must request audiences). WP58 and WP60 edit Java in core and game but not their properties or auth classes;
tell the orchestrator if you must touch a use case. Depends on: ADR-0004/0013 (auth), security review F-08, F-14.
Skills: owasp-security, quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp56-token-audience`, branch `wp56-token-audience`.

Decision 38 of 2026-11-06: every service verifies the token audience (one audience per service, mapped by the
realm; the web client's token carries all three), and the realm rotates refresh tokens with reuse detection.
ADR-0034 reserved for you.

## Scope
1. **Audience**: realm audience mappers (`core-service`, `game-service`, `athlete-service`) on the web client's scope
   and on every client used by e2e, seed users and the internal calls (`/internal/authz` from game/athlete to core:
   which token do they use? check and keep it working); `quarkus.oidc.token.audience` per service; a token without
   the audience is 401 (test first, per service, with a Testcontainers Keycloak token minted for another audience).
2. **Refresh rotation**: realm `revokeRefreshToken: true`, `refreshTokenMaxReuse: 0`, SSO idle/max unchanged; the
   web client survives rotation (the OIDC library stores the new refresh token; prove with `browser_login_check.py`
   or a widget test on the auth service); reuse of an old refresh token is rejected (e2e or Testcontainers test).
3. **Keep green**: `just isolation-check`, the e2e journey on compose (`just e2e`), seed-users, the Tilt/kind realm
   copy (`scripts/sync-chart-files.sh`, chart test on drift).
4. **Docs**: ADR-0034; `docs/security/review-2026-11.md` rows F-08 and F-14 (you own those rows), ASVS rows
   touched; `docs/runbooks/` realm re-import note (realm changes need `just down && podman volume rm hoops_pgdata &&
   just up && just seed-users`).

## Acceptance
- [ ] Red tests first (audience rejection per service, refresh reuse rejection)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `just e2e` 21/21 on compose
      with the new realm; `deploy/helm/tests/run.sh` green after the chart sync
- [ ] `apps/web` still signs in (`browser_login_check.py` evidence or the auth widget test)
- [ ] ADR-0034 written and indexed (append your row at the end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. The compose stack ports (8080, 5432) are yours this wave.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
