-- finance-service V1 (WP118, ADR-0056): an academy's finance settings. Runs as finance_migrator.
-- One ISO 4217 currency per academy (decision 94); amounts everywhere are integers in its minor unit. The currency is
-- fixed once the first due exists (checked by the use case against finance.due, V3).
create table finance.settings (
  tenant_id   uuid primary key,
  currency    char(3) not null check (currency ~ '^[A-Z]{3}$'),
  updated_at  timestamptz not null,
  version     integer not null default 0
);
select app.enable_tenant_rls('finance.settings');
