-- finance-service V4 (WP118, ADR-0017 pattern, ADR-0055): the audit trail of finance writes. Runs as finance_migrator.
-- Written by the use cases in the same transaction as the change. Tenant table, append-only for the application: a
-- trigger rejects UPDATE / DELETE of any row the app role can see (RLS hides other tenants' rows, so a cross-tenant
-- attempt touches 0 rows); retention runs as finance_migrator. metadata never carries personal data, amounts' reasons
-- or notes (P-12): ids, enum values and the names of changed fields only.
create table finance.audit_event (
  id               uuid primary key,
  seq              bigint generated always as identity,
  tenant_id        uuid not null,
  actor_sub        text not null,
  actor_person_id  uuid,
  action           text not null,
  target_type      text not null,
  target_id        text not null,
  metadata         jsonb not null default '{}'::jsonb,
  at               timestamptz not null default now()
);
select app.enable_tenant_rls('finance.audit_event');
create index audit_event_tenant_at_idx on finance.audit_event (tenant_id, at desc);

create function finance.audit_event_append_only() returns trigger
  language plpgsql as $$
begin
  if current_user = 'finance_migrator' then
    return coalesce(new, old);
  end if;
  raise exception 'finance.audit_event is append-only' using errcode = '42501';
end;
$$;

create trigger audit_event_append_only before update or delete on finance.audit_event
  for each row execute function finance.audit_event_append_only();
