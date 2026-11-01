# WP20 — Documentation and final spec-conformance review

Model: Sonnet (docs) + Opus (review). Depends on: WP18.

## Scope
- User guides per role (admin, coach/assistant, parent, player, super admin) in es/en/id (docs/guides/).
- Runbooks: onboard tenant, rotate secrets, CNPG backup/restore, kind rebuild, release process.
- Architecture overview with diagrams; roadmap (billing, events v2, native images, push notifications, purge job).
- Opus review: walk `docs/SPEC.md` + `docs/PLAN.md` §2 line by line with evidence (tests/e2e) → conformance checklist;
  simplification pass (dead code, duplicated patterns between game/athlete RosterPort adapters → move to common);
  ADR completeness.

## Acceptance
- [ ] conformance checklist with every spec statement mapped to a test or e2e step; gaps listed with follow-ups
