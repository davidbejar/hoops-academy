-- The replica bookkeeping tables of game and athlete (ADR-0037, one shape in both schemas since WP130, ADR-0062), so the
-- shared stores (JdbcReplicaHistory, JdbcParkedEvents) are tested here with the production privilege model.

-- Applied event ids per tenant (a tenant table: RLS shows the bound tenant's rows only).
create table core.applied_event (
  tenant_id   uuid not null,
  event_id    uuid not null,
  topic       text not null,
  applied_at  timestamptz not null default now(),
  primary key (tenant_id, event_id)
);
select app.enable_tenant_rls('core.applied_event');

-- The tenants the replica holds rows of (global, ids only): the app role may read and insert.
create table core.replica_tenant (
  id             uuid primary key,
  first_seen_at  timestamptz not null default now()
);
revoke update, delete, truncate, references, trigger on core.replica_tenant from core_app;

-- Records that broke their contract (global: a broken record may name no tenant). The app role inserts, and reads only
-- the columns retention filters on and logs; operators read the rest as the owner.
create table core.parked_event (
  topic         text not null,
  partition     integer not null,
  kafka_offset  bigint not null,
  record_key    text,
  event_id      uuid,
  reason        text not null,
  parked_at     timestamptz not null default now(),
  inspected_at  timestamptz,
  primary key (topic, partition, kafka_offset)
);
revoke select, update, delete, truncate, references, trigger on core.parked_event from core_app;
grant select (topic, partition, kafka_offset, parked_at, inspected_at), delete on core.parked_event to core_app;
