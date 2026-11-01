# WP15 — Usage statistics aggregation

Model: Sonnet. Depends on: WP3, WP6, WP8. Skills: quarkus-hexagonal-service, test-driven-development.

## Scope
- core: `GET /platform/tenants/{id}/usage` aggregating core counts (members by role, players by status, teams, seasons)
  with game (`matches`, `events`) and athlete (`sessions`, `attendance`, `injuries`, `test results`) via `/internal/usage`
  with client-credentials; nightly `usage_snapshot` job; list endpoint for trends.
- game/athlete: implement/complete `/internal/usage/{tenantId}` counts.

## Acceptance
- [ ] WireMock tests for peer failures (partial data flagged, 200 with `partial=true`); snapshot job idempotent per day
- [ ] super_admin only; contract validation; verify green
