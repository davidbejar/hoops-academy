-- ============================================================================
-- WP34 / V11 — the super admin reads the audit trail of every academy (GET /platform/audit-events, ADR-0029)
-- core_platform already appends lifecycle rows (V9). It may now also read every row through its own permissive
-- policy, as it reads the registry (core.tenant) and usage snapshots: the same platform mechanism, no BYPASSRLS, no
-- security definer. It still gets nothing on tenant content tables (person, player, …), and UPDATE / DELETE stay
-- impossible (no grant, plus the append-only trigger). core_app keeps reading its bound tenant's rows only.
-- ============================================================================
create policy audit_event_platform_read on core.audit_event for select to core_platform using (true);
grant select on core.audit_event to core_platform;
