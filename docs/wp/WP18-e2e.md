# WP18 — End-to-end journey suite (compose and kind) + Flutter integration tests

Model: Sonnet. Depends on: WP12–WP14, WP16. Skills: test-driven-development, verification-before-completion.

## Scope
- `e2e/` Maven module (REST Assured + Keycloak token helper + Awaitility) run against `BASE_URL` (compose `http://localhost:8080`
  or kind ingress). Journey: super admin creates tenant → first admin invite (read MailHog) → admin invites coach/parent
  → coach requests player → admin approves → assignment → match created, scored by coach + parent (parent restricted
  checks) → box score → training session + attendance → injury → physical test with band → season rollover produces
  orphan → resolved → cross-tenant 404s throughout → tenant suspended → 404s.
- Flutter `integration_test` smoke on Chrome: login, tenant switch, open match, enter one event offline, sync.
- `just e2e` recipe; CI job (compose on GitHub runner).

## Acceptance
- [ ] journey passes against compose and against kind; Flutter smoke passes; CI job green
