# WP19 — v2 events: transactional outbox + Redpanda + local replicas (optional)

Model: Opus. Depends on: WP17. ADR-0008.

## Scope
- core: outbox publisher (`FOR UPDATE SKIP LOCKED` polling, `quarkus-messaging-kafka`), topics `core.person`,
  `core.player`, `core.team`, `core.team-player`, `core.team-staff`, `core.guardian-link`, `core.tenant`.
- game/athlete: consumers upserting `*_ref` replica tables (RLS), `RosterPort` replica adapter behind
  `hoops.roster.source=rest|replica`.
- compose + Helm: Redpanda single node; Dev Services for tests.

## Acceptance
- [ ] replica equals core after replay from empty; duplicate delivery idempotent; adapter swap passes the same contract tests
