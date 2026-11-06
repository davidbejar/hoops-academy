-- ============================================================================
-- WP67 / V14 — the outbox publisher (ADR-0008 amended, ADR-0036)
-- core.outbox stays a tenant table (tenant_isolation policy, FORCEd RLS). What changes:
--   * topic : the Redpanda topic a row is published to (core.<aggregate>); null = an internal v1 notification row
--             (tenant.created, player.approved, ...) that is kept but never published.
--   * seq   : insert order. The publisher sends each tenant's rows in seq order and never sends a row while an older
--             unpublished row of the same aggregate is locked by another publisher (FOR UPDATE SKIP LOCKED).
--   * occurred_at defaults to clock_timestamp(): the time of the insert, not of the transaction start, so the events
--             of one aggregate (serialised by the row lock the writer takes) are stamped in commit order.
-- The publisher reads and marks a tenant's rows as core_app with that tenant bound. To find which tenants have a
-- backlog it reads the queue columns through the platform role: tenant_id, topic, occurred_at, published_at of every
-- tenant (its own permissive SELECT policy, as for the registry and the audit trail), never payload, aggregate id or
-- event type, which describe tenant content. No UPDATE / DELETE for core_platform.
-- ============================================================================
alter table core.outbox add column topic text check (topic ~ '^core\.[a-z]+(-[a-z]+)*(\.v[0-9]+)?$');
alter table core.outbox add column seq bigint generated always as identity;
alter table core.outbox alter column occurred_at set default clock_timestamp();

drop index core.outbox_unpublished_idx;
create index outbox_pending_idx on core.outbox (tenant_id, seq) where published_at is null and topic is not null;

create policy outbox_platform_backlog on core.outbox for select to core_platform using (true);
grant select (tenant_id, topic, occurred_at, published_at) on core.outbox to core_platform;
