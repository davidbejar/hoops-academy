-- ============================================================================
-- WP3 / V3 — platform: usage snapshots, transactional outbox, billing seams
-- ============================================================================

-- Aggregated usage reports (GET /platform/tenants/{id}/usage). Written by core_platform, readable by the tenant.
create table core.usage_snapshot (
  id           uuid primary key,
  tenant_id    uuid not null,
  collected_at timestamptz not null default now(),
  report       jsonb not null
);
create index usage_snapshot_tenant_idx on core.usage_snapshot (tenant_id, collected_at desc);
select app.enable_tenant_rls('core.usage_snapshot');
create policy usage_snapshot_platform on core.usage_snapshot to core_platform using (true) with check (true);

-- Transactional outbox (insert only in v1; the publisher is WP19). Events are written in the same transaction as
-- the change they describe; platform lifecycle events are appended by core_platform (insert only, no read).
create table core.outbox (
  id             uuid primary key,
  tenant_id      uuid not null,
  event_type     text not null,
  aggregate_type text not null,
  aggregate_id   text not null,
  payload        jsonb not null,
  occurred_at    timestamptz not null default now(),
  published_at   timestamptz
);
create index outbox_unpublished_idx on core.outbox (occurred_at) where published_at is null;
select app.enable_tenant_rls('core.outbox');
create policy outbox_platform_append on core.outbox for insert to core_platform with check (true);

-- Billing extension points (plan §1): a global plan catalogue and one subscription per tenant.
create table billing.plan (
  code        text primary key,
  name        text not null,
  max_members integer,
  max_players integer,
  max_teams   integer
);
insert into billing.plan (code, name) values ('FREE', 'Free (unlimited during v1)');

create table billing.tenant_subscription (
  tenant_id  uuid primary key,
  plan_code  text not null references billing.plan (code),
  status     text not null default 'ACTIVE' check (status in ('ACTIVE', 'CANCELLED')),
  started_at timestamptz not null default now()
);
select app.enable_tenant_rls('billing.tenant_subscription');
create policy tenant_subscription_platform on billing.tenant_subscription to core_platform
  using (true) with check (true);
