-- ============================================================================
-- WP128 / V20 — CORE-12 (audit 2026-11-23): since V7 every read of core.usage_snapshot and the nightly upsert go
-- through usage_snapshot_day_uq (tenant_id, snapshot_date), which also serves the tenant prefix; nothing filters or
-- orders by collected_at, so the V3 index only cost a write per upsert.
-- ============================================================================
drop index core.usage_snapshot_tenant_idx;
