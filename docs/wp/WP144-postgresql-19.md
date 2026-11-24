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
