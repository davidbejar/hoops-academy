# ADR-0073: PostgreSQL 19, one minor in every place, a new volume per major

- Status: Accepted (amends the PostgreSQL 17 line of PLAN and ADR-0006's stack)
- Date: 2026-11-24
- Related: decisions 114 and 115 of 2026-11-24, [WP144](../wp/WP144-postgresql-19.md), WP142 (the pin in
  `scripts/bump_pins.py`, CloudNativePG 1.30.2), ADR-0006 (RLS and the one role list), ADR-0068 (one source for the deploy
  pins), [runbook: a new PostgreSQL major](../runbooks/postgresql-major.md)

## Context
The project ran PostgreSQL 17 (compose and the test harnesses `postgres:17`, the chart CloudNativePG's
`postgresql:17`). PostgreSQL 19.0 was released on 2026-11-19. Decision 114: move to 19, fall back to 18.7 for everything
if a dependency refuses 19 and the refusal cannot be worked around cleanly; never mix majors. Decision 115: the owner's
compose database is dumped, a fresh volume is bootstrapped and reseeded, not restored. Two facts shaped the how:

- CloudNativePG's registry publishes 19 only as flavoured tags (`19.0-minimal-trixie`, `19.0-standard-trixie`,
  `19.0-system-trixie`, the same on bookworm); there is no plain `19`. The chart's old `postgresql:17` was one of the
  deprecated rolling tags: it still pointed at **17.11 on Debian bullseye** (built 2026-08-31, no 17.12 security fix).
- From 18 the official image keeps its cluster in `/var/lib/postgresql/<major>/docker` (19: `PGDATA=
  /var/lib/postgresql/19/docker`) and declares the volume at `/var/lib/postgresql`; compose mounted `.../data`.

## What was checked (sources read on 2026-11-24)
| Component | Version here | Source | Verdict |
|---|---|---|---|
| CloudNativePG operator | 1.30.2 | `docs/src/supported_releases.md` (release-1.30): "Supported Postgres versions 15 - 18"; release notes v1.30.0 (in-place `pg_upgrade` to 19 with extension images), v1.30.2 (default operand 18.7, 19 RC2 named); `postgres-containers` README (19 published 2026-11-19, EOL 2031-11-19) | **Not listed** (19 came out after 1.30.0; 1.31.0 is due about 2026-12-01). The project publishes the 19.0 operand images itself; no check refuses a newer major. **Works here**: kind clusters `hoops-db` and `keycloak-db` healthy on `19.0-minimal-trixie`, managed roles reconciled, `deploy/kind/smoke.sh core game athlete` passed (57 checks) |
| CloudNativePG image flavour | `19.0-minimal-trixie` | `postgres-containers` README: `minimal` = PGDG packages on Debian; `standard` adds PGAudit, pgvector, all locales, JIT; `system` deprecated; recommended tag form `MM.mm-TYPE-OS` | `minimal`: no extension is used, JIT is off by default in 19 anyway; trixie = the official image's Debian 13 |
| Keycloak (server) | 26.8.2 | `docs/guides/server/templates/databases.adoc` at tag 26.8.2: PostgreSQL "18.x, 17.x, 16.x, 15.x, 14.x", tested 18 (`pom.xml` `postgresql.version` 18); db guide: "not a supported configuration if the … Hibernate dialect allows the use of a version that differs" | **Not listed**, no refusal. **Works here**: fresh schema (Liquibase, 101 tables) and realm import of `realm-academy.json` on 19.0 (compose-like throwaway), and on kind (production mode, `keycloak-db`) |
| Keycloak's JDBC driver | pgjdbc 42.7.13 | Keycloak `pom.xml` 26.8.2 | see pgjdbc |
| Flyway (Quarkus BOM 3.40.1.2) | 12.0.0 (`flyway-database-postgresql`) | bytecode of `PostgreSQLDatabase.ensureSupported`: `recommendFlywayUpgradeIfNecessaryForMajorVersion("18")`, which only logs `Log.warn`; the same "18" in 12.10.0 and 13.13.0 (newest on Maven Central) | **Warns, does not refuse** ("Using PostgreSQL 19.0 which is newer than the version Flyway has been verified with"); no Flyway release knows 19 yet, so no bump helps. **Works here**: every migration of core, game, athlete in `just test` |
| PostgreSQL JDBC driver | 42.7.13 | pgjdbc README ("compatible with PostgreSQL 8.4 and higher", regression tests against every version since 9.1 and master); CHANGELOG 42.7.10: "fix: non-standard strings failing test for version 19"; 42.7.4+: protocol 3.2 cancel keys | **Supported** |
| pgx (finance-service) | v5.13.0 | pgx README "Supported Go and PostgreSQL Versions": the PostgreSQL majors of the last five years, "PostgreSQL 14 and higher" | **Supported** |
| finance-service migrations | own runner | `internal/adapters/out/persistence/migrate.go` (no version check) | **Works here** (`just test-go`) |
| Testcontainers (Java 2.x, Go v0.45.0) | — | `PostgreSQLContainer` and the Go module pass the image through; no data volume | **Works here** |
| `postgres` client tools | the server image's own | every script runs `psql`/`pg_dumpall` inside the server container or the CNPG pod (`db-roles.sh`, `events-replay.sh`, `events-drift.sh`, `scripts/lib/throwaway-pg.sh`, `deploy/kind/smoke.sh`) | Same major by construction |

PostgreSQL's own release notes, read for what this repository uses (18.0: "Migration to Version 18"; 19.0: "Migration to
Version 19"):

| Change | Here |
|---|---|
| 18: `initdb` enables data checksums by default | `data_checksums = on` on the fresh compose bootstrap and on both kind clusters (CloudNativePG 1.30.2 keeps the default). No effect on behaviour |
| 18: MD5 passwords deprecated (warnings); 19: a warning after MD5 authentication | Every role has a SCRAM-SHA-256 verifier (`password_encryption = scram-sha-256`; checked on the fresh bootstrap) |
| 18: RESTRICT foreign-key violations report `23001` instead of `23503` | No `ON DELETE/UPDATE RESTRICT` in any migration; the tests that expect `23503` insert a child without its parent (unchanged) |
| 18: AFTER triggers run as the role active when the event was queued | Only finance's `BEFORE` trigger on `audit_event`; no role switch inside a transaction |
| 18: VACUUM/ANALYZE process inheritance children; unlogged partitioned tables refused; `COPY` CSV `\.` | Not used |
| 18/19: full text search and pg_trgm follow the database's locale provider | Not used (`V7__session_plans.sql`: no pg_trgm); the provider is libc anyway |
| 19: `standard_conforming_strings` always on | Already on; `scripts/pg-major-move.sh` refuses a dump while it is off |
| 19: JIT off by default; `max_locks_per_transaction` 64 → 128; `io_workers` removed; RADIUS removed | No setting of these anywhere |
| Row-level security, `FORCE`, policies, `set_config`/`current_setting`, role attributes and membership, default privileges, `search_path`, `gen_random_uuid` | **No change listed in 18 or 19.** Observed on 19.0: the bootstrap leaves the same nine NOINHERIT, NOBYPASSRLS login roles with their connection limits and `search_path`, the six schemas with the same owners; `FORCE` binds the owner; `app.current_tenant()` raises `42501` without a tenant; `core_app` sees and updates only its tenant's rows; the RLS, role and isolation suites are green |

## Decision
1. **PostgreSQL 19.0 everywhere.** No component refuses 19. Two of them (CloudNativePG 1.30, Keycloak 26.8) do not list it
   yet and Flyway warns; the suites, the fresh bootstrap and the kind smoke ran on 19 without a difference, so the
   fall-back to 18.7 is not taken. When CloudNativePG 1.31 or a Keycloak release lists 19, nothing changes here.
2. **One minor in five places, a flavour per registry**: `docker.io/library/postgres:19.0-trixie` (compose,
   `PostgresRlsResource`, finance's `pgtest.go`, the images workflow) and `ghcr.io/cloudnative-pg/postgresql:
   19.0-minimal-trixie` (the `databases` sub-chart). `scripts/bump_pins.py` reads the version out of the flavoured tags
   and applies a newer minor only when **both** registries publish it in the pinned flavour (CloudNativePG publishes
   later than Docker Hub); a new major is only reported. `scripts/tests/test_postgres_pin.py` holds the five places, the
   flavours and the major together.
3. **A volume per major in compose**: `pgdata-19` (`hoops_pgdata-19`) mounted at `/var/lib/postgresql`. The old
   `hoops_pgdata` is no longer declared, so compose neither reuses it nor drops it (`down -v` only removes declared
   volumes); it is the way back until the owner removes it by hand. Podman cannot rename a volume, and a new name avoids
   an export/import of the old one.
4. **The move of a compose stack with data** is `scripts/pg-major-move.sh` (dry run by default; `--apply`: checks,
   `pg_dumpall` with the old server's own tools into a 0600 file outside the repository, `just down`, `just up`, check of
   the new major), then the reseed of decision 115. Runbook: `docs/runbooks/postgresql-major.md`.
5. **A CloudNativePG cluster with data** does not change major by editing `imageName`: CloudNativePG's offline in-place
   upgrade needs the same Debian distribution on both sides and the old tag is bullseye, for which no 19 image exists.
   It moves by import into a new cluster (`bootstrap.initdb.import`, or logical replication), described in the runbook.
   Only throwaway kind clusters exist today; the cloud VM was never applied.

## Consequences
- Flyway logs `WARN Using PostgreSQL 19.0 which is newer than the version Flyway has been verified with. The latest
  verified version of PostgreSQL is 18.` at every migration run until a release knows 19.
- `data_checksums` is on for every new compose, test and CloudNativePG database (18's initdb default); a later in-place
  `pg_upgrade` must match it.
- The docs that name `hoops_pgdata` or PostgreSQL 17 as the current version (README, HANDOVER, PLAN, architecture,
  conformance, threat model) are the docs pass's (WP147); the runbooks of this package say `hoops_pgdata-19`.
- The next major: bump the major in the five places with `scripts/bump-pins.sh --apply --major`, rename the compose
  volume to `pgdata-<major>` (the test asks for it), run `scripts/pg-major-move.sh`.
