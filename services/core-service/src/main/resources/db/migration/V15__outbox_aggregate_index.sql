-- ============================================================================
-- WP81 / V15 — the events backfill (POST /platform/events/backfill) asks, per tenant and topic, which aggregates have
-- a roster event already (`aggregate_id` of the rows with that topic, optionally after a `seq`). Without this index it
-- reads the tenant's whole outbox once per topic. Roster rows only (topic not null); no new table, no grant change.
-- ============================================================================
create index outbox_aggregate_idx on core.outbox (tenant_id, topic, aggregate_id, seq) where topic is not null;
