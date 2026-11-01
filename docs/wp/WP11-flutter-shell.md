# WP11 — Flutter Web shell: auth (PKCE), routing, tenant switcher, generated clients, design system, PWA, i18n

Model: Sonnet. Depends on: WP2b (contracts); runtime needs WP1 (Keycloak) and later WP3 (`/me`). Lane WEB. ADR-0004.
Skills: flutter-feature, test-driven-development, clean-code.

## Scope
- `apps/web` Flutter project (`flutter create --platforms web --org com.hoopsacademy hoops_app`), Dart 3, Material 3.
- Packages: flutter_riverpod (+ riverpod_annotation/generator if desired), go_router, dio, oidc + oidc_default_store
  (PKCE; `web/redirect.html`), drift + sqlite3_flutter_libs/web (setup only), fl_chart, intl + flutter_localizations,
  freezed/json_serializable only if the generated clients need them. No Node tooling.
- Localisation: `l10n.yaml`, ARB files `app_es.arb` (template), `app_en.arb`, `app_id.arb` (Indonesian); a test that all
  three files share the same key set; language switcher (per-user preference persisted locally, default from tenant
  `default_locale` once `/me` is available).
- Generated clients via `scripts/gen-api.sh` into `lib/api/<svc>` (committed; regenerate on contract change).
- App shell: splash → login (Keycloak redirect) → tenant switcher (`/me`) → role-aware bottom navigation (Admin,
  Teams, Matches, Training, Players/Me, Profile), `X-Tenant-Id` + bearer interceptors, token refresh, Problem+JSON →
  `AppError`, offline banner (connectivity), error/empty/loading widgets, theme tokens, 360 px-first layouts.
- PWA: manifest (name, icons, theme), `flutter build web --pwa-strategy=offline-first`, standard CanvasKit renderer
  (no COOP/COEP), deferred imports per feature module placeholder.
- Dev: `apps/web/README.md` (run against `just up` stack with `--web-port 5173` behind nginx `/` or directly with CORS
  note), nginx placeholder replaced by instructions (WP1 keeps serving placeholder until WP18 wires the build).

## Acceptance
- [ ] `flutter analyze` clean; widget tests: auth guard redirects, tenant switcher lists memberships, nav per role, locale switch (es/en/id)
- [ ] l10n key-parity test; golden test of home shell at 360×780 and 1024×768
- [ ] integration_test on Chrome: login against compose Keycloak with a seeded user (document how to run; may require WP3 for `/me` — stub `/me` via a dev mock mode flag if WP3 is not merged yet, and say so)
- [ ] `flutter build web` succeeds; Lighthouse PWA installable (document manual check)

## Handover

### Built (`apps/web`, nothing committed by the agent)
- Flutter 3.47.9 / Dart 3.13 project (`com.hoopsacademy`, package `hoops_app`), Material 3, light/dark, tokens in `lib/app/theme.dart`
  (seed colour, spacing, radius, 48 px tap target, 720 px breakpoint). Layout per the flutter-feature skill:
  `lib/{app,core,features/<name>/{data,domain,application,presentation},l10n}`.
- **Generated clients**: `scripts/gen-api.sh` -> `apps/web/packages/{core,game,athlete}` (`hoops_core_api`, `hoops_game_api`,
  `hoops_athlete_api`, built_value), `path:` dependencies, excluded in `analysis_options.yaml`, committed. See Decisions for why
  not `lib/api`.
- **State/routing**: flutter_riverpod 3, go_router 18. Guard = pure `redirectFor(SessionState, location)` (`core/session/session.dart`)
  fed by `sessionProvider` (auth status -> `/me` -> selected tenant): splash (loading and `/me` error with Retry), login,
  `/tenants` switcher, `/no-access`, role-checked destinations, `/profile`, `/platform` for super_admin without memberships.
- **HTTP**: one `Dio` (`dioProvider`) shared with the generated clients (their default interceptors disabled). Chain: Accept-Language,
  `X-Tenant-Id` (not for `/me`/`/platform`; an explicit header from the generated method wins), bearer + 401 -> refresh once -> retry
  -> else `expireSession()` (guard sends the user to login), Problem+JSON -> `AppError` (kind, status, title, detail, code, traceId,
  violations) with localized messages via `AppErrorView`.
- **Auth**: `oidc` 5 + `oidc_default_store`, PKCE via discovery of the issuer, public client `web`, scopes
  `openid profile email offline_access`, `refreshBefore` 60 s (package refreshes proactively; the 401 interceptor is the backstop),
  `navigationMode: samePage`, `web/redirect.html` (from the package). `AuthService` port; `MockAuthService` for demo/tests.
- **Tenant**: `/me` -> memberships; selection persisted in `shared_preferences` (`hoops.selectedTenantId`), auto-select when exactly one,
  stale selection ignored; app bar shows tenant logo (`GET /api/core/tenant/logo`, 404/failure -> initials) + name, tap to switch.
  Nav per role (highest wins): ADMIN Admin/Teams/Matches/Training/Players; COACH/ASSISTANT Teams/Matches/Training/Players; PARENT
  Matches/Training/My players; PLAYER Matches/Training/Me; super_admin-only Platform. Bottom bar < 720 px, rail >= 720 px. Profile is the
  app-bar action.
- **i18n**: `l10n.yaml`, `app_es.arb` (template) / `app_en.arb` / `app_id.arb` (real Indonesian), generated code committed in
  `lib/l10n/gen`. Language picker in Profile persists locally (`hoops.locale`) and best-effort `PATCH /api/core/me`. Effective locale:
  stored choice > academy `defaultLocale` > `es`.
- **PWA**: manifest "Hoops Academy" (theme #E8590C), 192/512 + maskable icons and favicon generated programmatically (placeholder
  basketball), `flutter build web --pwa-strategy=offline-first` (CanvasKit, no COOP/COEP/wasm). Eight feature placeholders are
  **deferred libraries** (`lib/app/feature_modules.dart`; build emits `main.dart.js_1..9.part.js`).
- Offline banner (`connectivity_plus`), loading/empty/error widgets, **dev mock mode** `--dart-define=HOOPS_MOCK_API=true`
  (`core/http/mock_api_adapter.dart`: `/me` GET+PATCH, tenant profile, logo; two academies, ADMIN+COACH with logo and PARENT;
  enforces bearer and `X-Tenant-Id` like the real service). **This exists because core-service (WP3) is not merged: `/api/core/me`
  currently returns 502.**
- `apps/web/README.md` (run modes, CORS note, regeneration, tests, manual checks), `tool/keycloak_login_check.sh`.

### Verified (fresh, 2026-11-01)
- `flutter analyze` -> `No issues found!`
- `flutter test` -> `+64: All tests passed!` (core: AppError 5, interceptors 9, destinations 8, redirect/guard 9; l10n parity 3;
  widget: auth guard 5, tenant switcher 8 (0/1/many, persistence, stale selection, chip), nav per role 8 (+ rail on wide), locale 4
  (es/en/id switch, persisted, tenant default), offline banner 1, whole-stack mock mode 1; goldens 3). Tests were written first
  (red = compile failure / failing expectation) for each unit; the one structural surprise (provider cycle Dio <-> session/locale) was
  found by the mock-mode test and fixed with `RequestContext`.
- `flutter build web --pwa-strategy=offline-first` -> `Built build/web` (service worker, manifest, redirect.html, 9 deferred parts).
- `flutter build web --target integration_test/login_smoke_test.dart --dart-define=HOOPS_MOCK_API=true` compiles.
- Real Keycloak (compose stack started by me with `just up`, `just seed-users`): `tool/keycloak_login_check.sh` -> user `coach1`,
  PKCE S256 code exchange for client `web` with scope `openid profile offline_access email`, `azp=web`, issuer
  `http://localhost:8080/auth/realms/academy`, refresh-token grant OK. (Stack left running.)
- `bash -n scripts/gen-api.sh` ok; full `scripts/gen-api.sh` run, packages resolve and compile in the app.

### Acceptance checklist
| Item | Evidence |
|---|---|
| analyze clean; widget tests guard / tenant lists / nav per role / locale es-en-id | analyze clean; `auth_guard_test`, `tenant_switcher_test`, `navigation_roles_test`, `locale_test` green |
| l10n key parity; golden 360x780 and 1024x768 | `test/l10n/l10n_keys_test.dart` (keys + placeholders + not-a-copy); `test/golden/home_shell_golden_test.dart` + 3 PNGs in `test/golden/goldens/` |
| integration_test on Chrome with seeded user | **Partly.** `integration_test/login_smoke_test.dart` + `test_driver/` written and compiled for web; **not executed**: `flutter test -d chrome` does not support integration tests on web ("Web devices are not supported for integration tests yet") and `flutter drive` needs `chromedriver`, which is not installed; downloading and executing it was refused by the environment's permission check. Real-login evidence is the scripted PKCE run above. Blockers for full browser automation: chromedriver, and the Keycloak form being a different page/origin than the Flutter page (an in-page test cannot fill it). Exact commands and the manual browser check are in `apps/web/README.md`. |
| `flutter build web` succeeds | yes (see above) |
| Lighthouse PWA installable (manual) | Not run (no browser automation); manifest/icons/service worker present in `build/web`; steps in README |

### Decisions
- **Generated packages live in `apps/web/packages/<svc>`, not `lib/api/<svc>`; `scripts/gen-api.sh` default changed (and it now removes
  `.openapi-generator/`).** A path package nested inside the app's `lib/` makes `package_config.json` invalid: the Dart compiler fails
  with "language version override has to be the same in the library and its part(s)" (generated lib is Dart 2.18, parts resolve to the
  app's 3.13). Forcing the SDK constraint up does not work (the generated `abstract class XMixin = Object with _$XMixin` is not
  Dart 3 compatible). This is the alternative WP2b already listed; `just gen-api` works unchanged.
- Dio is shared and the generated clients are created with `interceptors: const []`; tenant/locale reach the interceptors through the
  plain `RequestContext` holder published by `HoopsApp` (providers would form a cycle: `/me` and profile providers use Dio).
  The locale interceptor yields one microtask for the same reason.
- Roles: highest role wins when several are held; Profile and language switching are an app-bar action, not a nav tab.
- Hash URL strategy (no server rewrite rules needed behind nginx). `samePage` OIDC navigation (no popup blockers, automation friendly).
- Language: stored choice > tenant `defaultLocale` > es (`/me.locale` is only written, not used as default, so the brief's
  "default from tenant default_locale" holds).
- Deferred loading seam `libraryLoaderProvider` + `featureModules` map; tests preload the libraries (`runAsync`) and make loading synchronous.
- Not added: drift / sqlite3 / fl_chart (brief says "setup only"; no feature needs them yet and drift on web needs wasm/worker assets —
  WP13 adds them with the offline queue), freezed/json_serializable (generated clients use built_value).

### How WP12-WP14 add features
See `apps/web/README.md` "Adding a feature": replace the placeholder screen in `features/<name>/presentation/`, keep the deferred import in
`lib/app/feature_modules.dart`, add sub-routes under the `ShellRoute` in `lib/app/router.dart`, build repositories on the generated clients with
`HoopsCoreApi(dio: ref.watch(dioProvider), interceptors: const [])`, map errors with `AppError.of`, add ARB keys to all three files, and add the
standard tests (providers, widget states + roles, goldens). Widget tests use `test/support/harness.dart` (`Harness`, `FakeMeRepository`,
`FakeTenantRepository`). New feature modules (e.g. a "My player" detail) need a `destinationsFor` entry only if they are top-level.

### Open points / follow-ups
- **WP1 owner**: add `http://localhost:5173/*` (redirect + post-logout) and web origin `http://localhost:5173` to client `web` in
  `infra/keycloak/realm-academy.json` to run `flutter run --web-port 5173` against the real realm (otherwise serve the build via nginx
  on :8080). API CORS for a cross-origin dev server is also an infra matter. nginx must serve `redirect.html` and the SPA assets when WP18 wires the build.
- **Repo owner**: root `.gitignore` still has `apps/web/lib/api/**/.openapi-generator/` (stale; the script now deletes that folder) and
  `CLAUDE.md` / `libs/contracts/README.md` / WP2b mention `apps/web/lib/api`; update to `apps/web/packages`.
  Generated packages carry their own `.gitignore` (`.dart_tool`, `pubspec.lock`).
- **WP3**: when `/api/core/me` exists, switch off the mock (it is only enabled by the define) and run the manual real-login check in the README.
  If `/me` 404s for an unprovisioned subject the shell shows the localized "not found" error with Retry/Sign out.
- Run the Chrome `flutter drive` smoke (needs chromedriver) and the Lighthouse installability check manually; CI can add chromedriver later.
- `--pwa-strategy` is deprecated in Flutter 3.47 (still works). Wasm dry run succeeded (we stay on CanvasKit by design).
- super_admin who also has memberships currently gets the tenant navigation only (no Platform entry); add one if the product wants it.
- Goldens use the test font, so they are layout-only and stable across OSes; icon glyph changes will also show up there.
- Per-user language is also saved to the server via `PATCH /api/core/me` (best effort, errors ignored).
