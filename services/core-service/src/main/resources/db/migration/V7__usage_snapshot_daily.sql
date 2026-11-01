-- ============================================================================
-- WP15 / V7 — one usage snapshot per tenant per (UTC) day: the nightly job and on-demand reads upsert it.
-- snapshot_date is derived from collected_at, so it cannot disagree with it. Earlier rows (one per usage call)
-- are reduced to the latest of each day first; the table is FORCE-RLS, so the owner steps out of RLS for that.
-- ============================================================================
alter table core.usage_snapshot no force row level security;
delete from core.usage_snapshot old
 using core.usage_snapshot newer
 where old.tenant_id = newer.tenant_id
   and (old.collected_at at time zone 'UTC')::date = (newer.collected_at at time zone 'UTC')::date
   and (old.collected_at, old.id) < (newer.collected_at, newer.id);
alter table core.usage_snapshot force row level security;

alter table core.usage_snapshot
  add column snapshot_date date generated always as ((collected_at at time zone 'UTC')::date) stored;
create unique index usage_snapshot_day_uq on core.usage_snapshot (tenant_id, snapshot_date);

-- the upsert updates today's row
grant update on core.usage_snapshot to core_platform;
