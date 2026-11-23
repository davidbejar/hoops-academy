# ADR-0063: finance-service prunes its applied event ids, has no token leeway, and tests copy one database

- Status: Accepted
- Date: 2026-11-24
- Related: ADR-0037 (replica rules; amendment of WP82: retention), ADR-0036 (topics, tombstone retention), ADR-0055
  (finance-service stack and harness), WP131, audit of 2026-11-23 (FIN-03, FIN-11, X-11), decisions 104 and 112

## Context
- `finance.applied_event` gained a row per consumed event and nothing deleted it; game and athlete prune theirs since
  WP82 (`ReplicaRetentionJob`: older than 7 days, configurable with 7 days as default and minimum, batches of 1000,
  advisory lock, daily). finance already had the index (`applied_event_applied_at_idx`) and the tenant list
  (`finance.replica_tenant`) the job needs.
- finance's token verifier allowed 10 s of clock skew; core, game and athlete set no
  `quarkus.oidc.token.lifespan-grace`, and quarkus-oidc 3.40.1.2 then leaves jose4j 0.9.6's allowed clock skew at its
  default of 0 s (`OidcProvider` calls `setAllowedClockSkewInSeconds` only when the property is set).
- Each of the four database test binaries started and migrated its own `postgres:17` container in `just test-go`.

## Decision
1. **Retention.** `application.ReplicaRetention` deletes the applied event ids older than 7 days (the topics' tombstone
   retention) academy by academy, each batch of at most 1000 (`for update skip locked`) in its own transaction bound
   to the academy, under the advisory lock `finance.replica-retention`; `job.Retention` runs it at start and every 24
   hours on each instance (the lock lets one run), logs the counts and feeds
   `hoops_roster_replica_pruned_total{table="applied_event"}`. The values are constants, not configuration: 7 days is
   both the Java default and the minimum, and nobody has asked for more. `parked_event` keeps its rows: finance has
   no `inspected_at` column and its app role may not delete parked records (operators clear them as the owner).
2. **Leeway.** The verifier allows no clock skew (`oidc.Leeway = 0`), the Java services' value; pdf-service took the
   same value in WP132. A test states the number.
3. **Test database.** `scripts/check.sh` starts one server for the run (`internal/testsupport/pgtest/serve`:
   bootstrap with `infra/db/init`, migrations of `hoops`) and exports `PGTEST_TEMPLATE_URL`; every test binary
   creates its own database from `hoops` as a template (copying hoops' database privileges, which `CREATE DATABASE`
   does not) and drops it after its run. Tests keep connecting only as `finance_app` / `finance_migrator`; the
   superuser URL only copies and drops databases. `go test` on one package without the variable starts a container
   of its own, as before.

## Consequences
- `applied_event` stays bounded to about a week of events per academy; a redelivery older than that is stale anyway
  (the `occurred_at` guard).
- A token is refused from the second of its `exp`; clocks of the cluster must agree (they already must for the Java
  services).
- `just test-go` starts one Postgres instead of four (37.2 s to about 25 s on the owner's Mac); the binaries cannot
  see each other's rows, which the daily-job test (all tenants) and the schema-wide RLS checks need.
