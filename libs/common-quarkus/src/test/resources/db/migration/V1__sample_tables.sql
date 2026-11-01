-- Sample tables used by common-quarkus' own tests. They live in the real `core` schema and are created by
-- core_migrator, so the production privilege model (owner vs. non-owner app role, FORCE RLS) is exercised.

create table core.sample_widget (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null,
  name       text not null,
  size_cm    integer not null,
  created_at timestamptz not null default now(),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('core.sample_widget');

-- Child table with a tenant-scoped composite FK (needs a fixture override in GenericRlsIsolationTest).
create table core.sample_widget_part (
  id         uuid primary key,
  tenant_id  uuid not null,
  widget_id  uuid not null,
  label      varchar(40) not null,
  weight_g   numeric(8,2) not null,
  fragile    boolean not null,
  foreign key (tenant_id, widget_id) references core.sample_widget (tenant_id, id)
);
select app.enable_tenant_rls('core.sample_widget_part');

-- Global lookup table (no tenant_id): must be declared in RlsSchemaMetaTest.globalTables().
create table core.sample_colour (
  code  text primary key,
  label text not null
);
