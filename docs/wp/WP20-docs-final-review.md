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

## Handover (docs)

Documentation half of WP20 (Sonnet). The Opus review half (conformance checklist, simplification pass, ADR completeness)
is **not** done; the acceptance box above stays open. No code, contract, infra, deploy or other docs/wp file was touched, and
no git command was run.

### Written (lines)
- User guides, es/en/id each, in `docs/guides/`: `admin` 90/87/90, `coach` 87/82/85, `parent` 52/49/52, `player` 41/39/39,
  `super-admin` 47/46/45 (15 files, 931 lines in total, suffixes `.es.md`, `.en.md`, `.id.md`).
- Runbooks (new): `onboard-tenant.md` 60, `rotate-secrets.md` 64, `backup-restore.md` 68 (design), `release.md` 67,
  `troubleshooting.md` 83.
- `docs/architecture.md` 191 (five Mermaid diagrams: context, containers, request flow with tenant header and RLS, offline
  sync sequence, eligibility/rollover; ADR table; data ownership; testing strategy; security posture).
- `docs/roadmap.md` 92. Root `README.md` 83 (refreshed). Existing runbooks (`local-stack`, `kind`, `e2e`) were not edited.

### How it was checked
- Menu and button names in the guides come from `apps/web/lib/l10n/app_{es,en,id}.arb` (dumped and read); screens and rights
  from the WP11-WP14 handovers and `docs/domain/authz-matrix.md`. Relative links in README, architecture, roadmap, runbooks and
  guides were checked with a script: none broken. Mermaid blocks were scanned for `;` (a known parser trap) and fixed; they
  were **not rendered** here.
- Commands in the runbooks and README were copied from the justfile, scripts, `kind.md`, `e2e.md`, `local-stack.md` and the
  apps/web README. I did not run any of them.

### Could not verify
- No screen was clicked through in a browser; every guide ends with a status line saying so. Guides describe the app as built
  according to the handovers (e.g. the player box score shows team totals only, per WP13, while the authz matrix says "self").
- Test counts in `architecture.md` are copied from the WP17 verification table (JVM) and WP14 (Flutter 447); not re-run.
  The e2e journey (20 steps) is documented as PARTIAL in `WP18-e2e.md`; I found no later record of a full green run.
- `rotate-secrets.md`: compose and Keycloak rotation steps and `ALTER ROLE`/`kcadm update clients` are not executed (marked);
  the kind path follows `kind.md`/ADR-0012.
- `backup-restore.md` is design only (CNPG barman-cloud plugin names, `pg_dump`/`pg_restore` flags, owner handling after
  restore). `release.md`: no release, tag, registry or CI run exists; the Helm/image steps follow WP16 and the workflows.
- `onboard-tenant.md`: the MailHog `jq` expression assumes the MailHog API v2 shape used by `e2e/.../MailHog.java`; kind
  mailpit access follows WP17 notes.
- Invented nothing about push notifications, billing or purge beyond "not built"; the roadmap marks undesigned items.

### Doc drift noticed (not fixed, outside my files)
- `docs/runbooks/e2e.md` says game/athlete have no health extension and lists the realm `basic` scope as an open blocker;
  WP17 fixed both. `docs/runbooks/kind.md` still says game/athlete use TCP probes.
- `CLAUDE.md`, `libs/contracts/README.md` and WP2b still mention `apps/web/lib/api` (now `apps/web/packages`).
- `apps/web/README.md` still says core-service "does not exist yet" and that the realm only allows :8080 (WP17 added 5173).
- `docs/PLAN.md` describes `servers: /api/<svc>` and symlinked chart files; the implementation differs (copies plus
  `scripts/sync-chart-files.sh`).

### Open points for the Opus review
Conformance walk of `docs/SPEC.md` and PLAN section 2 against tests/e2e; WP19 is unbuilt; F-01 needs a product decision before
the authz matrix and the guides can state what parents and players see in the event feed.
