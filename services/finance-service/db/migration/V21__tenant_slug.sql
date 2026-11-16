-- finance-service V21 (WP123, ADR-0048): the academy's slug from core.tenant (tenant.changed carries it), for the
-- export file names hoops-<academy-slug>-<what>-<yyyyMMdd>.csv. Not personal data. Null until the academy's next event
-- or a backfill (`just events-backfill force`); the file name then leaves the part out. Runs as finance_migrator.
alter table finance.tenant_ref add column slug text;
