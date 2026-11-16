-- finance-service V22 (WP123, ADR-0056): a team's name from core.team (team.changed carries it), for the team column
-- of the dues export. Not personal data. Null until the team's next event or a backfill; the column is then empty.
-- Runs as finance_migrator.
alter table finance.team_ref add column name text;
