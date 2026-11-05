# ADR-0029: Reading the audit trail: academy ADMINs under RLS, the super admin through a platform read policy

- Status: Accepted
- Date: 2026-11-06 (WP34)
- Records: the product owner's decision 8 of the 2026-11-05 interview (`docs/wp/FOLLOW-UPS.md`, "Plan (2026-11-05)")
- Amends: ADR-0017 ("There is no REST read endpoint"; core_platform "may only append")
- Related: ADR-0006 (RLS), ADR-0023 (the platform reads the administrators' identity), ADR-0026 / ADR-0028 (audit rows
  written into other academies), WP34

## Context
`core.audit_event` (ADR-0017, V9) has been written by about twenty use cases and read by nothing. Decision 8 asks for a
read API for an academy's ADMIN and for the super admin across academies, with names resolved when read (metadata holds
no personal data), a published list of action names, and screens in both consoles. The tenant table is protected by RLS
(`tenant_id = app.current_tenant()`); core_platform, the super admin's datasource role, could only insert into it, and has
never read tenant content tables (persons, players …) except through `TenantScope.runAs` for the administrators
(ADR-0023).

## Decision
1. **One source of action names.** `AuditAction` (core, `application.port`) lists every action with the type of row it
   is about (`AuditTargetType`: person, player, tenant, approval_request, guardian_link). `AuditEvent.of` takes only an
   `AuditAction`, so an action cannot be written without being in the enum. `AuditActionCompletenessTest` keeps the enum
   equal to the contract enums `AuditAction` / `AuditTargetType` (core 2.5.0) and to `docs/domain/audit-events.md`.
   `member.invitation_accepted` is new: the first sign-in (`/me` turning PENDING into ACCEPTED) records it with the person
   as actor (`AuditLog.recordAs`). `player.approved` / `player.rejected` already existed.
2. **Academy path** `GET /api/core/audit-events` (ADMIN; other roles 403; non-members and a super_admin without
   membership 404): core_app in the academy's RLS scope, plus an explicit `tenant_id` predicate for the indexes. Names
   (persons, the person of a player, the academy) are resolved in the same scope, so an id of another academy can never
   resolve, even in a forged row.
3. **Platform path** `GET /platform/audit-events` (super_admin; optional `tenantId`, 404 when unknown): the platform
   datasource, through a new permissive policy `audit_event_platform_read` (`for select to core_platform using (true)`)
   and `grant select` (V11) — the mechanism core_platform already uses for the registry and usage snapshots. No
   BYPASSRLS, no security-definer function, no grant on any content table; UPDATE / DELETE stay impossible. The academy's
   name comes from a join to `core.tenant`.
4. **Names on the platform path stay within ADR-0023**: academies, and persons who are *active administrators* of their
   academy, looked up per academy inside `TenantScope.runAs` (core_app, that academy's RLS). Other persons and players are
   shown by id and type only. The actor kind (PERSON / PLATFORM / SYSTEM) is derived from the stored row: a person id
   means a member, `system` a background job, any other subject without a person the super admin.
5. **Query shape**: `from` inclusive, `to` exclusive (RFC 3339 instants; the web sends local calendar days as UTC
   instants), `action` repeated for several actions, newest first (`at desc, seq desc`), page size 1–200.
   Indexes (V12), measured with EXPLAIN ANALYZE on one million rows: `(tenant_id, action, at desc)` for the action filter
   (a rare action of a large academy: 65 ms → 0.05 ms) and `(at desc)` for the platform page (300 ms → 0.2 ms).
6. **Retention**: none in v1; the contract says so. A purge job (as `core_migrator`, the only role the append-only
   trigger lets delete) is a v2 item.

## Alternatives rejected
- **Platform path through `TenantScope.runAs` for every academy** and a merge of the per-academy pages: a page needs
  `(page + 1) × size` rows from each academy and one transaction per academy; slow and complex for a read the policy
  answers in one statement.
- **Resolving every person and player name on the platform path**: it would widen what the platform reads beyond the
  administrators' identity (ADR-0023) to children's names; the super admin opens the academy's own console (as an
  administrator of it) when names matter.
- **Storing names in metadata at write time**: personal data in an append-only table that is never purged in v1, and
  stale after a rename.
- **A `team` target type**: no action targets a team today; it is added together with the first such action.

## Consequences
- core_platform now reads the audit rows of every academy (actions, ids, metadata). Metadata carries no personal data
  by rule; the exception is the super admin's own free-text `reason` on `tenant.suspended` / `tenant.withdrawn`.
- Adding an action means: an `AuditAction` constant, a contract enum value (minor bump), a row in
  `docs/domain/audit-events.md`, and a label in the web's ARB files (es/en/id; a test requires one per action).
- Counting a large unfiltered trail still scans it (about 0.1–0.2 s per million rows); acceptable in v1.
