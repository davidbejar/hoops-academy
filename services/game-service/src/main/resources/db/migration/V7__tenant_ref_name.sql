-- game-service WP117: the academy's name, printed on the match sheet PDF (decisions 89 and 90). core's tenant.changed
-- always carried it (libs/contracts/events/core.tenant.schema.json); the replica now keeps it. Null for a tenant whose
-- last tenant.changed was applied before this migration (until core sends the next one, a forced backfill or a replay:
-- docs/runbooks/events.md) and for a removed tenant. Runs as game_migrator; RLS on the table is unchanged.
alter table game.tenant_ref add column name text;
