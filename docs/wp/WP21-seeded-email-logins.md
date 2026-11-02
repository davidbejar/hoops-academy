# WP21 — Seeded dev users become e-mail logins

Model: Haiku. Depends on: WP1, WP16, WP18, ADR-0022. Skills: verification-before-completion, clean-code.

E-mail is the login (core-service creates every Keycloak user with username = e-mail, `KeycloakIdentityProvider.java:87`).
The six seeded dev users still use bare usernames and `@hoops.local`, which also fails the contract's `format: email`
(WP18 note). Make them `<name>@hoops-academy.com` everywhere.

## Scope
- `infra/keycloak/seed-users.sh` (compose) and `deploy/kind/seed-users.sh` (kind): the six users are
  `superadmin@hoops-academy.com`, `admin1@…`, `coach1@…`, `assistant1@…`, `parent1@…`, `player1@…` with
  **username = email**, same first/last names, password `DEV_USER_PASSWORD`, `emailVerified=true`, and the realm role
  `super_admin` for `superadmin@hoops-academy.com`.
  - Legacy migration (both scripts): if a user with exact username `<name>` (old style) exists, **delete it** before
    ensuring the new one (dev-only data: these users hold no memberships; `superadmin` re-registers its `app_user` by the
    new `sub` on its first `/me`). Print `migrated <name> -> <email>`.
  - Idempotent: a second run creates nothing and deletes nothing. The kind script also updates email/enabled/
    emailVerified when the user exists (compose already does).
  - Lookups by exact username (`-q username=<email> -q exact=true`); keep secrets out of command lines as today.
  - Keep the existing `loginTheme=hoops` step in the compose script.
- Realm SMTP sender `no-reply@hoops.local` -> `no-reply@hoops-academy.com` in `infra/keycloak/realm-academy.json`; run
  `scripts/sync-chart-files.sh` and `deploy/helm/tests/run.sh --update` (only that line may change in the snapshots).
- Callers of the old usernames: `deploy/kind/smoke.sh` (`user_token superadmin`), `apps/web/tool/keycloak_login_check.sh`
  (`HOOPS_E2E_USER` default), `apps/web/tool/browser_login_check.py` (`--user` default and docstring/README examples),
  `e2e/src/test/java/com/hoopsacademy/e2e/JourneyTest.java` (`tokens.login("superadmin", …)`).
- Fixtures and mocks using `@hoops.local` -> `@hoops-academy.com`: `apps/web/test/support/fixtures.dart`,
  `apps/web/test/support/core_fixtures.dart`, `apps/web/lib/core/http/mock_api_adapter.dart`,
  `apps/web/lib/core/mock/mock_core_api.dart` (`@demo.hoops.local` -> `@demo.hoops-academy.com`),
  `apps/web/test/features/admin/members_test.dart`. Do NOT touch `hoops.locale` (a prefs key, not an e-mail).
- Docs: `README.md`, `apps/web/README.md`, `docs/runbooks/{local-stack,kind,onboard-tenant,e2e}.md`: new user names.
  User guides `docs/guides/<role>.<lang>.md` (admin, coach, parent, player, super-admin × en/es/id): one sentence near
  the top that you sign in with your e-mail address (translated). Historical WP briefs/handovers stay untouched.

## Acceptance
- [x] `shellcheck -S warning` clean for both seed scripts and `deploy/kind/smoke.sh`
- [x] `just seed-users` run twice against the running compose stack: first run migrates, second prints only `exists`;
      `kcadm get users` shows the six new users and none of the six old usernames (e2e-created users may also exist)
- [x] `apps/web/tool/keycloak_login_check.sh` green with the new default user
- [x] `python3 -I apps/web/tool/browser_login_check.py --user player1@hoops-academy.com` green (app must be running)
- [x] `deploy/helm/tests/run.sh` green; snapshot diff limited to the SMTP sender
- [x] `cd apps/web && flutter analyze && flutter test` green
- [x] `grep -rn "hoops\.local" --exclude-dir={target,build,.dart_tool,.git} .` only in historical `docs/wp/WP<1-20>*` files
- [x] Handover section appended

## Handover

- Built:
  - Seed scripts (compose `infra/keycloak/seed-users.sh`, kind `deploy/kind/seed-users.sh`): the six users are
    `<name>@hoops-academy.com` with username = e-mail, same names, `emailVerified=true`, password `DEV_USER_PASSWORD`;
    `superadmin@hoops-academy.com` has `super_admin`. A legacy user with the bare name is deleted first and prints
    `migrated <name> -> <email>`. The kind script now also updates email/enabled/emailVerified on existing users.
  - Realm SMTP sender `no-reply@hoops-academy.com` (`infra/keycloak/realm-academy.json`), chart copy synced with
    `scripts/sync-chart-files.sh`, Helm snapshots re-recorded with `--update`.
  - Callers: `deploy/kind/smoke.sh`, `apps/web/tool/keycloak_login_check.sh` (default `coach1@hoops-academy.com`),
    `apps/web/tool/browser_login_check.py` (default and docstring), `JourneyTest.java` (login argument only; the Actor
    label stays `superadmin`), one comment in `apps/web/integration_test/login_smoke_test.dart` (not in the brief list).
  - Fixtures/mocks to `@hoops-academy.com`: `test/support/fixtures.dart`, `test/support/core_fixtures.dart`,
    `lib/core/http/mock_api_adapter.dart`, `lib/core/mock/mock_core_api.dart` (`@demo.hoops-academy.com`),
    `test/features/admin/members_test.dart`. `hoops.locale` untouched.
  - Docs: `README.md`, `apps/web/README.md`, `docs/runbooks/{local-stack,kind,onboard-tenant,e2e}.md`, and one sentence
    (en/es/id) near the top of the 15 files in `docs/guides/`. No WP1-20 or FOLLOW-UPS edits.
- Verified (all run in this session, fresh):
  - `shellcheck -S warning` on the two seed scripts and `smoke.sh`: no output, exit 0.
  - `just seed-users` run 1: `migrated` x6 (superadmin, admin1, coach1, assistant1, parent1, player1) and `created` x6,
    exit 0. Run 2: `exists` x6 only, exit 0.
  - kcadm `get users -r academy --fields username`: all six `@hoops-academy.com` users present; none of the six bare
    names left. Besides them, e2e leftovers (`e2e-*@hoops.local`, `e2e-*@e2e.example.org`) and one unrelated user
    `admin@hangtuah.co.id` are present; I did not touch them. `get-roles --uusername superadmin@hoops-academy.com` lists
    `super_admin`.
  - `apps/web/tool/keycloak_login_check.sh` (default user): discovery S256, login form, token exchange,
    `preferred_username=coach1@hoops-academy.com`, `refresh_token grant OK`, `OK: coach1@hoops-academy.com logged in`,
    exit 0.
  - `python3 -I apps/web/tool/browser_login_check.py --user player1@hoops-academy.com`: steps 1-5 done, Keycloak page
    shows branded theme `hoops`, `OK: login round trip stays in the app`, `OK: signed out, at http://localhost:5173/#/login`,
    exit 0. The signed-in landing shows the generic not-found text (no membership yet, as in FOLLOW-UPS).
  - `deploy/helm/tests/run.sh`: 37 `ok`, 0 FAIL, `ALL CHART TESTS PASSED`, exit 0. Snapshot diff is the sender line in
    the realm chart copy plus, in `umbrella-default.yaml` and `umbrella-kind.yaml`, the sender line and the derived
    `checksum/realm` annotation (the realm file's hash changed). Nothing else.
  - `cd apps/web && flutter analyze`: `No issues found!`. `flutter test`: `All tests passed!` (481), exit 0.
  - `grep -rn "hoops\.local"` (excluding build dirs): remaining hits are historical WP11 and WP18 lines, this brief's own
    text, and `hoops.locale` (a prefs key in code, excluded by the brief). No other hits.
  - `./mvnw -q -pl e2e test-compile`: exit 0 (the Java e2e suite was not run, per the orchestrator).
- Open points:
  - The kind script and `deploy/kind/smoke.sh` were only shellcheck'd and read; no kind cluster was run here.
  - The running compose Keycloak keeps its old realm SMTP sender until the realm is re-imported (realm JSON is imported
    only into an empty volume). Not reset, per instructions.
  - `superadmin@hoops-academy.com` re-registers its `app_user` under the new `sub` on its first `/me` (WP18 note). Not
    exercised here: the login checks above do not call core.
  - Old e2e leftover users stay in the local realm. Clean up with a stack reset when convenient.
