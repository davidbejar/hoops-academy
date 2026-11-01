-- A table that holds GLOBAL rows (tenant_id null, read-only for tenants) next to tenant rows, like athlete's plan
-- templates and norms. It is declared in RlsSchemaMetaTest.nullableTenantTables() and must use one policy per
-- command: USING and WITH CHECK differ, and a single FOR ALL policy would let DELETE through on global rows
-- (DELETE only evaluates USING).
create table core.sample_template (
  id        uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name      text not null
);
alter table core.sample_template enable row level security;
alter table core.sample_template force row level security;
create policy sample_template_select on core.sample_template for select
  using (tenant_id is null or tenant_id = app.current_tenant());
create policy sample_template_insert on core.sample_template for insert
  with check (tenant_id = app.current_tenant());
create policy sample_template_update on core.sample_template for update
  using (tenant_id = app.current_tenant()) with check (tenant_id = app.current_tenant());
create policy sample_template_delete on core.sample_template for delete
  using (tenant_id = app.current_tenant());
