-- finance-service V3 (WP118, ADR-0056): dues and payments, the model WP119 fills. Runs as finance_migrator.
-- A due: what one player owes under one plan for one period (decision 97: the full amount for every period with the
-- player on the roster on any day). OPEN -> PAID (one hand-recorded payment, decision 95) or WAIVED (ADMIN, with a
-- reason); a voided payment makes the due OPEN again. While OPEN, ADMIN may change the amount with a reason.
-- Immutable: plan, player, period and its dates. Reasons and notes are short and hold no health or family details
-- (P-12); they never reach logs, spans or audit metadata.
create table finance.due (
  tenant_id            uuid not null,
  id                   uuid not null,
  fee_plan_id          uuid not null,
  player_id            uuid not null,
  team_id              uuid not null,           -- the team through which the player owed it (the first one found)
  period               text not null,           -- "YYYY-MM", "YYYY-Qn" or "SEASON" (the plan's cadence)
  period_start         date not null,
  period_end           date not null,
  amount_minor         bigint not null check (amount_minor between 0 and 100000000000),
  plan_amount_minor    bigint not null check (plan_amount_minor between 1 and 100000000000),
  status               text not null check (status in ('OPEN', 'PAID', 'WAIVED')),
  reason               text check (char_length(reason) between 1 and 200), -- of the last waiver or amount change
  created_at           timestamptz not null,
  updated_at           timestamptz not null,
  version              integer not null default 0,
  primary key (tenant_id, id),
  constraint due_once_per_period unique (tenant_id, fee_plan_id, player_id, period),
  constraint due_period_dates check (period_end >= period_start),
  constraint due_fee_plan_fk foreign key (tenant_id, fee_plan_id) references finance.fee_plan (tenant_id, id)
);
select app.enable_tenant_rls('finance.due');
create index due_player_idx on finance.due (tenant_id, player_id, period_start);
create index due_team_idx on finance.due (tenant_id, team_id, period_start);

-- A payment settles a due in full. Voiding keeps the row (voided_at, reason, by whom) and opens the due again; at
-- most one payment per due is not voided. No partial payments, no refunds (decision 95).
create table finance.payment (
  tenant_id        uuid not null,
  id               uuid not null,
  due_id           uuid not null,
  amount_minor     bigint not null check (amount_minor between 0 and 100000000000),
  paid_on          date not null,
  method           text not null check (method in ('CASH', 'BANK_TRANSFER', 'CARD', 'OTHER')),
  note             text check (char_length(note) between 1 and 200),
  recorded_by      uuid not null,               -- the recording ADMIN's person id
  recorded_at      timestamptz not null,
  voided_at        timestamptz,
  void_reason      text check (char_length(void_reason) between 1 and 200),
  voided_by        uuid,
  primary key (tenant_id, id),
  constraint payment_void_complete check ((voided_at is null) = (void_reason is null) and (voided_at is null) = (voided_by is null)),
  constraint payment_due_fk foreign key (tenant_id, due_id) references finance.due (tenant_id, id)
);
select app.enable_tenant_rls('finance.payment');
create unique index payment_one_valid_per_due on finance.payment (tenant_id, due_id) where voided_at is null;
