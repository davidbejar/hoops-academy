-- ============================================================================
-- WP90 / V17 — invitation-only sign-up (decisions 51 and 58, ADR-0044)
-- A platform table: requests for a NEW academy come from anonymous visitors and belong to no tenant. Only core_platform
-- (the super admin's datasource, and the public POST /platform/academy-requests) reads and writes it; core_app gets
-- nothing (RLS forced, no policy, every default privilege revoked). The requester's data is immutable once stored:
-- core_platform may only update the decision columns (column grants); no role but core_migrator deletes.
-- Retention: none in v1 (as the audit trail); a purge of decided requests is a v2 item (ADR-0044).
-- ============================================================================

-- One comparison for academy names everywhere (requests and the tenant registry): trimmed, inner whitespace collapsed,
-- lower-cased. The application never compares names itself, so both sides can never disagree.
create function core.academy_name_key(name text) returns text
  language sql immutable strict parallel safe
  return lower(regexp_replace(btrim(name, E' \t\r\n'), '\s+', ' ', 'g'));

create table core.academy_request (
  id                uuid primary key,
  status            text not null default 'PENDING' check (status in ('PENDING', 'ACCEPTED', 'REJECTED')),
  requester_name    text check (char_length(requester_name) between 1 and 120),
  email             text not null check (char_length(email) between 3 and 254),
  requester_role    text not null check (requester_role in ('ADMIN', 'COACH', 'PARENT')),
  academy_name      text not null check (char_length(academy_name) between 1 and 120),
  locale            text not null check (locale in ('es', 'en', 'id')),
  requested_at      timestamptz not null default now(),
  decided_at        timestamptz,
  decided_by        text check (char_length(decided_by) between 1 and 255),
  reason            text check (char_length(reason) between 1 and 500),
  -- the academy created on acceptance (not tenant_id: this row belongs to no tenant; no FK, a failed onboarding
  -- compensation deletes the registry row while the request goes back to PENDING)
  created_tenant_id uuid,
  notified_at       timestamptz,
  constraint academy_request_decision check (
       (status = 'PENDING'  and decided_at is null and decided_by is null and reason is null
                            and created_tenant_id is null and notified_at is null)
    or (status = 'ACCEPTED' and decided_at is not null and decided_by is not null and reason is null
                            and created_tenant_id is not null)
    or (status = 'REJECTED' and decided_at is not null and decided_by is not null and reason is not null
                            and created_tenant_id is null))
);

-- An academy name is taken while a request for it is pending or accepted (a rejected one frees it again).
create unique index academy_request_open_name_uq on core.academy_request (core.academy_name_key(academy_name))
  where status in ('PENDING', 'ACCEPTED');
-- The workbench: one status, newest first.
create index academy_request_status_idx on core.academy_request (status, requested_at desc);
-- The spam guard counts the pending requests of one e-mail.
create index academy_request_pending_email_idx on core.academy_request (lower(email)) where status = 'PENDING';
-- The name check against the registry.
create index tenant_name_key_idx on core.tenant (core.academy_name_key(name));

alter table core.academy_request enable row level security;
alter table core.academy_request force row level security;
create policy academy_request_platform on core.academy_request to core_platform using (true) with check (true);
create policy academy_request_migrator on core.academy_request to core_migrator using (true) with check (true);

revoke all on core.academy_request from core_app;
grant select, insert on core.academy_request to core_platform;
grant update (status, decided_at, decided_by, reason, created_tenant_id, notified_at) on core.academy_request
  to core_platform;
revoke all on function core.academy_name_key(text) from public;
grant execute on function core.academy_name_key(text) to core_platform, core_app;
