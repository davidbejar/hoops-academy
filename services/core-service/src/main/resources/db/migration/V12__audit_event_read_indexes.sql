-- ============================================================================
-- WP34 / V12 — indexes for reading the audit trail (GET /api/core/audit-events, GET /platform/audit-events)
-- Measured with EXPLAIN ANALYZE on 1,000,000 rows (50 academies, one with 40 %, 20 actions, two years); see
-- docs/wp/WP34-audit-log-read-api-and-console.md:
--   * (tenant_id, action, at desc): a rare action of a large academy went from a 65 ms parallel seq scan (page) and
--     81 ms (count) to 0.05 ms / 0.03 ms; a common action within 30 days from 2.5 ms to 0.1 ms;
--   * (at desc): the platform page over every academy went from a 300 ms top-N sort of all rows to 0.2 ms.
-- The unfiltered academy page keeps using audit_event_tenant_at_idx (V9).
-- ============================================================================
create index audit_event_tenant_action_at_idx on core.audit_event (tenant_id, action, at desc);
create index audit_event_at_idx on core.audit_event (at desc);
