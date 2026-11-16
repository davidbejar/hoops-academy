-- finance-service V11 (WP119): a member's display name in the replica, for the person who recorded or voided a
-- payment (the contract's PersonRef). Runs as finance_migrator. Null until the member's next event (or a replay) and
-- when removed; still no birth date, gender or contact data (P-10).
alter table finance.person_ref add column display_name text;
