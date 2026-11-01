-- ============================================================================
-- WP17 / V9 — audit trail of administrative actions (ADR-0017, ASVS 16.3 / 16.4.2)
-- Tenant-scoped, append-only for the application: core_app inserts and reads its tenant's rows, a trigger rejects
-- UPDATE/DELETE of any row it can see (RLS hides other tenants' rows, so a cross-tenant attempt touches 0 rows);
-- core_platform (tenant lifecycle) may only append. Retention clean-up runs as core_migrator.
-- metadata never carries personal data (no names, e-mails, phone numbers, notes) — only ids, role names, field
-- names and enum values.
-- ============================================================================
create table core.audit_event (
  id              uuid primary key,
  seq             bigint generated always as identity,
  tenant_id       uuid not null,
  actor_sub       text not null,
  actor_person_id uuid,
  action          text not null,
  target_type     text not null,
  target_id       text not null,
  metadata        jsonb not null default '{}'::jsonb,
  at              timestamptz not null default now()
);
create index audit_event_tenant_at_idx on core.audit_event (tenant_id, at desc);
select app.enable_tenant_rls('core.audit_event');

create policy audit_event_platform_append on core.audit_event for insert to core_platform with check (true);
grant insert on core.audit_event to core_platform;
grant usage on sequence core.audit_event_seq_seq to core_platform;

create function core.audit_event_append_only() returns trigger
  language plpgsql as $$
begin
  if current_user = 'core_migrator' then
    return coalesce(new, old);
  end if;
  raise exception 'core.audit_event is append-only' using errcode = '42501';
end;
$$;

create trigger audit_event_append_only before update or delete on core.audit_event
  for each row execute function core.audit_event_append_only();
