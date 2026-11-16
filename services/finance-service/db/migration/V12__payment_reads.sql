-- finance-service V12 (WP119): the reads of a due's payments (every payment of a due, oldest first). Runs as
-- finance_migrator. The partial unique index of V3 covers only the valid payment.
create index payment_due_idx on finance.payment (tenant_id, due_id, recorded_at);
