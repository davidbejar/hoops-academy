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
- Built:
  - Realm: `oidc-audience-mapper` protocol mappers on the clients (not realm `clientScopes`, which would drop the
    built-in scopes), least privilege: `web` -> core, game, athlete; `core-service` -> game, athlete; `game-service`
    and `athlete-service` -> core. A service's own token is never for itself. `revokeRefreshToken: true`,
    `refreshTokenMaxReuse: 0`; SSO idle/max and the 5-minute access token unchanged. Chart copy synced, Helm
    snapshots re-recorded.
  - Services: `quarkus.oidc.token.audience=<service>-service` (OIDC section only). `/internal` calls keep working:
    game/athlete -> core with their client-credentials tokens (aud core), core -> game/athlete with its own.
  - Finding: Keycloak 26 **ends the client session** when a spent refresh token comes back (the newest token is
    refused too: "Session doesn't have required client"). Two browser tabs refresh before the same expiry, so the
    second one would have signed the user out every few minutes. `apps/web/lib/core/auth/serial_refresh.dart`
    (token hook of `OidcAuthService`): refreshes run under the Web Lock `hoops-oidc-refresh`, send the stored refresh
    token when the tab's copy is stale, and hold the lock until `package:oidc` has stored the answer.
  - `infra/keycloak/seed-users.sh` adds the mappers (read from the realm file) and the rotation settings to an older
    realm, so `just e2e` works without a volume reset.
  - Tests: common test-jar `TestRealm` (real realm file + a `web` copy with direct grants + a client for audience
    `another-service` with role `service` + a user), `RealmKeycloakResource`, `RealmTokens`,
    `RealBearerTokensProfile`; `TokenAudienceKeycloakTest` in core, game, athlete; `RealmRefreshTokenRotationKeycloakTest`
    (core); `RealmTokenPolicyTest` (verify); e2e steps 52/53; `oidc_refresh_rotation_test.dart`. game/athlete got
    the `keycloak-it` profile. Contract common 1.1.1 (bearer scheme names the audience).
- Verified (2026-11-06):
  - Red first (commit 790008d): core 4/4, game 4/4, athlete 4/4 failed (200 instead of 401), reuse 200 instead of 400,
    policy 5/7.
  - `-Pkeycloak-it`: core `TokenAudienceKeycloakTest` 4/4, rotation 3/3, `CrossTenantAccessTest` 6/6, game 4/4,
    athlete 4/4.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 2073 tests, 0 failures (e2e journey
    skipped there), coverage gates met, 4:37 min.
  - `just e2e` on compose: 23/23 (21 + 2 new), 73 s; the realm predated WP56 and `just seed-users` updated it.
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED; `sync-chart-files.sh --check` clean.
  - Web: `flutter analyze` clean, `flutter test` 673 + 6 new pass, format clean. `browser_login_check.py` (coach1):
    5/5 OK. Two-tab soak in headless Chrome (scratch script, realm access token lowered to 75 s, then reset to 300):
    both tabs signed in after 150 s, Keycloak session kept client `web`, last access 13 s before the end.
- Decisions/ADRs: ADR-0034 (indexed).
- Open points:
  - `deploy/kind/smoke.sh` (WP63's file) calls each service with that service's own token and expects "not 401"; by
    ADR-0034 that is now a 401. Fix: call game or athlete with core's token and core with game's or athlete's.
  - The volume reset (`podman volume rm hoops_pgdata`) was refused by the permission system; the fresh import of the
    realm file is proven by the Testcontainers tests instead.
  - No control run of the soak without `SerialRefresh` in a real browser (the unit test and the Keycloak test show
    the failure mode).
