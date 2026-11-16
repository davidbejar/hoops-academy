-- finance-service V20 (WP123, ADR-0056): expenses. Runs as finance_migrator.
-- Money the academy spent (decision 99): a day, one of the fixed categories, an amount in the academy's currency (minor
-- units, the currency of finance.settings), what it was for and an optional note. The note is short and holds no health
-- details and no named person's salary (P-12); it never reaches logs, spans, audit metadata or exports. A deleted expense
-- is gone (hard delete); the audit trail keeps that it existed (expense.deleted with its id and category).
create table finance.expense (
  tenant_id     uuid not null,
  id            uuid not null,
  spent_on      date not null,
  category      text not null check (category in ('COURT_RENTAL', 'SALARIES', 'KIT', 'TOURNAMENT_FEES', 'TRAVEL', 'OTHER')),
  amount_minor  bigint not null check (amount_minor between 1 and 100000000000),
  description   text not null check (char_length(description) between 1 and 120),
  note          text check (char_length(note) between 1 and 200),
  created_at    timestamptz not null,
  updated_at    timestamptz not null,
  version       integer not null default 0,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.expense');
create index expense_spent_on_idx on finance.expense (tenant_id, spent_on desc, created_at desc, id desc);
