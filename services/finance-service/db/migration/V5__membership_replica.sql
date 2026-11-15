-- finance-service V5 (WP118, ADR-0037 rules, ADR-0055): the part of core's roster the tenant filter needs: academies
-- (status, time zone) and members (login, roles, active), from the events of the topics core.tenant and core.person.
-- WP119 adds players, teams, team assignments, team staff and guardian links (V10-V19). Runs as finance_migrator.
-- Every replica table is a tenant table keyed by (tenant_id, id), so upserts never meet another tenant's row; each row
-- keeps the occurred_at and event_id of the event that wrote it (an older event never overwrites a newer one).
-- Removals are soft: the row stays with removed = true and no payload. No display names, birth dates or genders are
-- kept: the filter needs none (P-10).

create table finance.tenant_ref (
  tenant_id    uuid primary key,
  status       text,                     -- ACTIVE | SUSPENDED | WITHDRAWN; null when removed
  timezone     text,                     -- IANA zone of the academy; null when removed
  removed      boolean not null default false,
  occurred_at  timestamptz not null,
  event_id     uuid not null
);
select app.enable_tenant_rls('finance.tenant_ref');

create table finance.person_ref (
  tenant_id    uuid not null,
  id           uuid not null,
  subject      text,                     -- Keycloak sub of the login; null while the member has none or when removed
  roles        text[],                   -- tenant roles; null when removed
  active       boolean,                  -- null when removed
  removed      boolean not null default false,
  occurred_at  timestamptz not null,
  event_id     uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.person_ref');
create index person_ref_subject_idx on finance.person_ref (tenant_id, subject) where active and not removed;

-- Idempotency: a known event id is a duplicate (ADR-0037 §2).
create table finance.applied_event (
  tenant_id   uuid not null,
  event_id    uuid not null,
  topic       text not null,
  applied_at  timestamptz not null default now(),
  primary key (tenant_id, event_id)
);
select app.enable_tenant_rls('finance.applied_event');
create index applied_event_applied_at_idx on finance.applied_event (tenant_id, applied_at);

-- Invalid events (ADR-0037 §4): the one kind of row that may not name a tenant. Never the value, only where it was
-- and why. The app role may only insert; operators read it as finance_migrator.
create table finance.parked_event (
  id          bigint generated always as identity primary key,
  topic       text not null,
  partition   integer not null,
  "offset"    bigint not null,
  record_key  text,
  event_id    text,
  reason      text not null,
  parked_at   timestamptz not null default now()
);
revoke select, update, delete, truncate, references, trigger on finance.parked_event from finance_app;

-- The tenants the replica holds rows of (tenant ids only, no tenant content), so housekeeping jobs can enter each
-- one. The app role may read and insert, nothing else.
create table finance.replica_tenant (
  id             uuid primary key,
  first_seen_at  timestamptz not null default now()
);
revoke update, delete, truncate, references, trigger on finance.replica_tenant from finance_app;
