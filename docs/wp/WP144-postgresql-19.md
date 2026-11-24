# WP144 — Database, compose, chart, tests: PostgreSQL 17 to 19

Model: Opus · high. Wave 2 (2026-11-24, tenth round): starts after wave 1 is merged and runs alone; you are the wave's
only kind user. You own every place that pins the PostgreSQL major (`infra/compose/compose.yaml`,
`deploy/helm/hoops/charts/databases/**`, `PostgresRlsResource` in common-quarkus' test-jar,
`services/finance-service/internal/testsupport/pgtest/pgtest.go`, `.github/workflows/images.yml`), `infra/db/init/**`,
`deploy/kind/**`, `deploy/lib/platform.sh`, the chart snapshots, `scripts/bump_pins.py`'s PostgreSQL pin (written by
WP142), the runbooks that name the version and `CLAUDE.md`'s stack line. Depends on: WP142 (CloudNativePG 1.30.2, the
PostgreSQL pin in the bump script). Skills: work-package, podman-dev-env, tenant-isolation-testing,
quarkus-hexagonal-service, go-hexagonal-service, owasp-security, systematic-debugging, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp144-postgresql-19`, branch `wp144-postgresql-19`.

Decision 114 of 2026-11-24: the project moves to PostgreSQL 19 (19.0 is published by Docker Hub and by CloudNativePG
as `19.0-standard-trixie` and siblings; there is no plain `19` tag there). If a dependency refuses 19, the package
lands on 18.7 instead and says so. Decision 115: the owner's local database is not yours: the orchestrator dumps it,
starts a fresh volume and reseeds at merge time. ADR-0073 is reserved for you (the version, why, what was checked, how
a stack with data moves).

## Scope
1. **Compatibility first, written down**: before changing a pin, establish from the projects' own documentation and
   release notes (not from memory) that these accept PostgreSQL 19: CloudNativePG 1.30.x (and which image flavour and
   Debian base the chart should name), Keycloak 26.8.x, Flyway as shipped by the Quarkus BOM (it refuses or warns on
   unknown majors), the PostgreSQL JDBC driver, pgx, and the `postgres` client tools in the scripts and images. Then
   read the PostgreSQL 18 and 19 release notes' incompatibility sections for what this repo uses: row-level security
   and `FORCE`, `set_config` / `current_setting`, role attributes and membership, `initdb` defaults (data checksums,
   the data directory path of the official image changed in 18: the compose volume mount must follow), `md5`
   passwords, `uuid` functions, and anything the Flyway migrations call. One table in the ADR: component, version,
   source, verdict. A refusal you cannot work around cleanly means 18.7 for everything; do not mix majors.
2. **One version, said once**: a failing test first that every place names the same major (extend the existing pin or
   stack tests in `scripts/tests`), then the change. Pin a minor, not a floating major, wherever the repo's rule for
   the file says so.
3. **The suites are the proof**: `just test` (Maven with the RLS and isolation suites, Rust, Go), `just
   isolation-check` and `just db-role-check` run by hand in your worktree, all on the new version. A behaviour change
   in RLS or roles is a stop-and-report, not a test edit.
4. **Fresh bootstrap**: the database bootstrap from the one role list (`infra/db/init`, WP139) has never run on a
   fresh compose volume. Prove it on the new version without touching the owner's stack: a throwaway container from
   the same image, the same init mounts and environment as `compose.yaml`, on another port and with a throwaway volume
   you remove afterwards (the `images.yml` finance step does something close). Record the roles and schemas it leaves.
5. **kind**: `deploy/kind/up.sh --deploy`, `deploy/kind/seed-users.sh`, `deploy/kind/smoke.sh core game athlete` on
   the new version, cluster deleted afterwards. The Podman VM has 2 CPUs: if `helm --wait` misses Keycloak's deadline
   under load, wait for Keycloak and repeat the same command (WP139 saw this; WP146 hardens it).
6. **Moving a stack with data**: write the runbook section the orchestrator will follow for the owner's compose stack:
   `pg_dumpall` (or per database: `hoops` and `keycloak`) with the OLD version's tools into a directory outside the
   repo, the old volume kept under another name until the new stack is proven, a fresh volume, `just up`, the seeds
   (`just seed-users`, `just seed-academy`, `just finance-up`, `just events-backfill force`), and the way back (old
   image, old volume). Also the CloudNativePG path for a cluster with data (the operator's own major-upgrade
   procedure), described, not run. Make it a script if the steps are mechanical (`scripts/`), with a test of its
   argument handling and a dry-run mode; it must never print a password and never delete the old volume.
7. **INF-07**: with a fresh Keycloak database the realm is imported from the current realm file, so the retrofit in
   `infra/keycloak/seed-users.sh` is no longer needed for a new stack. Do not delete it in this package (other stacks
   still have old realms); say in the handover what can go once the owner's stack is rebuilt.

## Acceptance
- [ ] The compatibility table is in ADR-0073 with a source per row; the version actually adopted is stated in the
      first line of the handover
- [ ] `just test` green on the new version (fresh; totals per module); `just isolation-check`, `just db-role-check`
      green in the worktree
- [ ] Fresh-bootstrap proof and kind smoke recorded (or precisely what failed)
- [ ] `deploy/helm/tests/run.sh`, `python3 -I -m unittest discover -s scripts/tests`, `just docs-build` green
- [ ] The handover lists, step by step, what the orchestrator runs on the owner's stack and how to go back
- [ ] Red tests committed before each change
- [ ] Handover appended: what was built, fresh verification with totals, what was not run, open points

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
- kind and the owner's compose stack do not fit in the Podman VM's memory together with the LGTM pod: keep
  `global.observability` as the kind values have it and do not start the compose observability profile.
- Do not read, copy or print any `.env`. The compose stack that is running is the owner's: do not `just down` it, do
  not remove or recreate its volumes. What needs the real stack or the owner's database comes back "not run" in the
  handover; the orchestrator runs it from the main checkout at merge time.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->

**Adopted: PostgreSQL 19.0** (`docker.io/library/postgres:19.0-trixie`, `ghcr.io/cloudnative-pg/postgresql:19.0-minimal-trixie`).
No dependency refuses 19; CloudNativePG 1.30.2 and Keycloak 26.8.2 do not list it yet (supported up to 18) and Flyway
12.0.0 warns ("newer than the version Flyway has been verified with … 18"); every suite, the fresh bootstrap and the kind
smoke ran on 19 without a difference, so the 18.7 fall-back was not taken (ADR-0073, table with sources).

- Built:
  - **The pin** (`scripts/bump_pins.py`, red test first): the regex takes the version out of flavoured tags
    (`19.0-trixie`, `19.0-minimal-trixie` are one mention each, tag `19.0`); option `flavours` resolves a version only
    when **every** registry publishes it in the pinned flavour (CloudNativePG publishes later than Docker Hub); a newer
    major is reported, applied only with `--major`; a major-only pin still stays. `test_postgres_pin.py` (16 tests):
    the five places, one minor of major 19, the flavour per registry, the one-registry-only minor not applied, the
    rewrite keeps the flavours, the compose volume. The repo now pins a **minor** in all five places.
  - **The five places** on 19.0: `compose.yaml`, the `databases` sub-chart (`19.0-minimal-trixie`: no extension used,
    JIT off by default in 19; the old `postgresql:17` was a deprecated rolling tag = 17.11 on **bullseye**, no 17.12
    fix), `PostgresRlsResource`, finance's `pgtest.go`, `images.yml`; comments no longer repeat the version. Chart
    snapshots re-recorded (only the two `imageName` lines changed).
  - **Compose volume per major**: `pgdata-19` (`hoops_pgdata-19`) mounted at `/var/lib/postgresql` (the 18+ image's
    `PGDATA` is `/var/lib/postgresql/19/docker`). `hoops_pgdata` is no longer declared: compose neither reuses nor drops
    it; it is the way back.
  - **`scripts/pg-major-move.sh`** (red tests first, `test_pg_major_move.py`, 15 tests with stub `podman`/`just`): dry run
    by default; `--apply` checks (container running on the old volume, older major than compose,
    `standard_conforming_strings` on, new volume absent), `pg_dumpall` with the old server's tools inside its container (socket, no password)
    under `umask 077` into `--out` (absolute, outside the repo, 0700; dump 0600 + `.sha256`), then `just down`, `just up`,
    check of the new major and that the old volume is still there; prints next steps and the way back; a failed `just up`
    after `just down` stops with what to do by hand. Never removes a volume, never prints a password or verifier
    (tested). `--dump-only`, `--container`, `--old-volume`.
  - **ADR-0073**, runbook `docs/runbooks/postgresql-major.md` (compose move and way back; the CloudNativePG path for a
    cluster with data: import into a new cluster, not an `imageName` flip, because in-place `pg_upgrade` needs the same
    Debian base and the old tag is bullseye), runbooks naming 17 / `hoops_pgdata` updated (local-stack, kind,
    backup-restore, rotate-secrets, troubleshooting, e2e, `infra/compose/README.md`), CLAUDE.md stack line, ADR index.
  - **kind smoke race fixed** (`deploy/kind/smoke.sh`): academy B's checks waited for a consumer lag of 0, true before
    core's outbox (1 s poll) has published; on 19 finance answered 404 "no membership" 20 ms before it applied B's
    events, 2 runs of 2 (data correct right after: `finance.person_ref`/`tenant_ref` rows present). The smoke now waits
    for core's published counter to grow by B's two events. A timing bug of the script, not a database behaviour
    (timestamps: B created 13:38:39.08, events published 40.233, finance's 404s at 40.210, applied at 40.228). No control
    run on 17 was made, and the fix has no committed red test (the two failing smoke runs were the red).
- Verified (fresh, 2026-11-24, all on PostgreSQL 19.0):
  - `./mvnw -o -B -ntp -T 1C verify -Dquarkus.http.test-port=0`, with
    `MAVEN_ARGS=-Daether.remoteRepositoryFilter.prefixes=false` (see open points): **BUILD SUCCESS**: contracts 346,
    common-quarkus 585, core 1267, game 530, athlete 1028 tests, 0 failures/errors (e2e module: 38, of which the 32
    `JourneyTest` journeys skip without a running stack); WP143's `DatabaseSpansTest` ran (core 5, game 2, athlete 2);
    coverage gates passed; Flyway logged "Using PostgreSQL 19.0 which is newer than the version Flyway has been verified
    with" and migrated everything.
  - `just test-go`: rc 0, 15 packages ok (174 test functions, RLS + isolation suites, the dues-list tracing test), coverage
    88.75 % / domain 98.84 %, govulncheck ok. `just test-rust`: rc 0, 105 tests, coverage 95.72 % / domain 99.80 %,
    cargo deny ok.
  - `just isolation-check` (worktree): 6 Java + 4 Go tests passed. `just db-role-check` (worktree): 13 Java + 2 Go tests
    passed. Both start the worktree's pinned image (19.0-trixie).
  - `python3 -I -m unittest discover -s scripts/tests`: 138 tests OK (1 skipped, as before). `deploy/helm/tests/run.sh`:
    ALL CHART TESTS PASSED. `just docs-build`: no issues. `actionlint images.yml`, `shellcheck pg-major-move.sh`: clean.
    `scripts/bump-pins.sh --check` (live): `ok postgresql: 19.0`, 0 outdated of 17. On the compose image (19.0):
    `scripts/model-diagrams.sh --check` "pages up to date" (catalog-derived ER diagrams unchanged),
    `scripts/tests/events-drift.test.sh` 49 passed. `podman compose --env-file .env.example ... config`: volume
    `pgdata-19` → `hoops_pgdata-19`, target `/var/lib/postgresql`.
  - **Fresh bootstrap** (throwaway `wp144-pg` from `postgres:19.0-trixie`, compose's three init mounts and environment,
    own port 55439, network and volume at `/var/lib/postgresql`, generated passwords never printed; all removed after):
    `PGDATA=/var/lib/postgresql/19/docker`, `data_checksums=on`, `password_encryption=scram-sha-256`. Roles: the nine
    service roles NOSUPERUSER NOINHERIT NOCREATEROLE NOCREATEDB NOBYPASSRLS LOGIN, limits 50/-1/10 as listed,
    `search_path` per row; `keycloak` (login, owner of db `keycloak`); every verifier SCRAM-SHA-256. Schemas: `app`
    (postgres), `core`, `billing` (core_migrator), `game`, `athlete`, `finance` (their migrators). Databases `hoops`,
    `keycloak` (libc, en_US.utf8). RLS probe: owner under FORCE sees one tenant, `core_app` in tenant A sees A's row and
    updates 0 of B's, no tenant → `42501 app.tenant_id is not set`, `core_app` cannot TRUNCATE; `core_app` and
    `keycloak` log in over TCP with their passwords. **Keycloak 26.8.2** `start-dev --import-realm` on it: Liquibase
    created 101 tables, realm `academy` imported, issuer served.
  - The move script on a throwaway **PostgreSQL 17** (`wp144-pg17`): dry run and `--apply --dump-only` as expected; the
    dump (0600 in a 0700 dir) restored into a throwaway 19.0 with one error only ("role postgres already exists"): 9
    roles, 6 schemas. All removed.
  - **kind**: `deploy/kind/up.sh --deploy --from-host` (throwaway `.env` of random values, removed after): CNPG 1.30.2,
    `hoops-db` and `keycloak-db` healthy on 19.0 (`data_checksums=on`, scram, locale C), managed roles as listed, all
    pods Ready (services restarted 2-3 times while the databases initialised, as on a fresh install).
    `deploy/kind/seed-users.sh` ok; `deploy/kind/smoke.sh core game athlete`: 56 ok + the race above twice, then with the
    fix **SMOKE PASSED, 57 checks** (incl. finance pods as `finance_app`: no superuser, no BYPASSRLS, owns nothing).
    Cluster deleted (`just kind-down`; `kind get clusters`: none).
- Decisions/ADRs: ADR-0073 (19.0, flavours, volume per major, move script, CNPG import path).
- **For the orchestrator, on the owner's stack at merge** (from the main checkout, stack running on 17):
  1. `scripts/pg-major-move.sh --out "$HOME/hoops-pg17-dump"` (dry run: must say 17 on `hoops_pgdata`, 19 on
     `hoops_pgdata-19`)
  2. `scripts/pg-major-move.sh --out "$HOME/hoops-pg17-dump" --apply` (dump, `just down`, `just up` on 19)
  3. `just seed-users`, `just services-up`, `just seed-academy`, `just finance-up`, `just events-backfill force`
  4. `just events-drift` (exit 0), and `podman exec hoops-postgres psql -XAt -U postgres -d hoops -c 'show
     server_version'` (19.0) plus the roles query of the runbook. (`just isolation-check` / `db-role-check` use their
     own Testcontainers database: they prove the code on 19, not the owner's stack; both are green above.)
  - **Way back**: `git checkout <pre-WP144 commit> -- infra/compose/compose.yaml` (or revert the merge), `just down &&
    just up` (17 on the untouched `hoops_pgdata`), `just events-backfill force`. The dump is a second copy. Remove
    `hoops_pgdata` by hand only once 19 has proven itself. `.env` needs no change.
- Not run: the move on the owner's stack (orchestrator, above); `--apply` past the dump (`just down`, `just up`, the
  major check) and the way back ran only against stubs; `just up` from this worktree (would recreate the
  owner's containers); a CloudNativePG cluster with data moved by import (described only; no such cluster exists);
  the images workflow and CI on 19 (CI runs them); the compose `observability` profile.
- Open points:
  0. **Urgent at merge**: README.md (line 82), `docs/HANDOVER.md` (line 289) and older WP notes (WP32, WP139) still say
     `podman volume rm hoops_pgdata` as the reset command. After the move that deletes the way back (17's data), not the
     live database: the live volume is `hoops_pgdata-19`. The runbooks of this package already say `hoops_pgdata-19`.
  1. INF-07: after step 2 Keycloak imports the current `realm-academy.json` into a fresh database, so the realm
     retrofit in `infra/keycloak/seed-users.sh` (the `kc`/`kcadm` login, `client_id_of`, `realm_file` and the four
     blocks bearer-only, audiences, admin-scope, hardening, about lines 19-100) and its test in `test_local_stack.py`
     (`test_the_retrofit_reads_the_realm_file_with_one_helper`) can go once the owner's stack is rebuilt, unless other
     stacks with old realms remain. Not deleted here.
  2. Docs pass (WP147): README.md (line 32 "PostgreSQL 17"), `docs/HANDOVER.md`, PLAN, architecture, conformance,
     threat model, ADR-0055/0063 prose still name 17. `.dependency-check-suppressions.xml` no longer names a version.
  3. Maven: even with `-o` the resolver's prefix filter fetched `prefixes.txt` from repository.jboss.org and hung on its
     socket (thread dump); `MAVEN_ARGS=-Daether.remoteRepositoryFilter.prefixes=false` avoids it. The hooks and
     `build-images.sh --from-host` would need it while jboss is down (not changed: outside scope).
  4. When CloudNativePG 1.31 (about 2026-12-01) or a Keycloak release lists 19, or a Flyway release knows it, update
     ADR-0073's table; nothing else changes.
  5. Seen, unchanged: `app.enable_tenant_rls(regclass)` keeps PostgreSQL's default `EXECUTE` for PUBLIC besides the
     explicit grants to the migrators (as on 17; it runs with the caller's rights, so only a table owner can use it).
