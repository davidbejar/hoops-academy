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
