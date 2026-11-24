# WP142 — Infra, chart, CI: apply the outdated pins; the bump script tracks PostgreSQL

Model: Sonnet · high. Wave 1 (2026-11-24, tenth round): runs alongside WP143 (database spans in the services). You own
the pinned lines in `infra/compose/compose.yaml`, `deploy/helm/hoops/values.yaml`, `deploy/lib/platform.sh`,
`deploy/containers/*.Containerfile`, `scripts/sbom.sh`, `scripts/zap-api-scan.sh`, `infra/tofu/check.sh`,
`.github/workflows/*.yml`, `.github/actions/**`, the chart snapshots, `scripts/bump_pins.py` with its tests, and the
one Redpanda Dev Services line in common-quarkus' `META-INF/microprofile-config.properties` (WP143 appends its own
lines to that file: touch only the pin). Depends on: nothing. Skills: work-package, podman-dev-env, owasp-security,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp142-apply-the-outdated-pins`,
branch `wp142-apply-the-outdated-pins`.

Decision 116 of 2026-11-24: the pins that `scripts/bump-pins.sh --check` reports outdated are applied in this round,
including the workflow-file pins the weekly bot cannot touch, and the bump script learns to track PostgreSQL's minor
version. No ADR is expected; if you make a decision, ADR-0076 is reserved for the round's infra packages (ask the
orchestrator before using it).

## Scope
1. **Apply**: `scripts/bump-pins.sh --check` on `main` reported 12 of 16 pins outdated on 2026-11-24 (distroless
   java25, Redis 8.12.0, Redpanda v26.3.1 in the chart, compose, finance's tests and Dev Services, Mailpit v1.34.0,
   otel-lgtm 0.41.1, Trivy 0.76.2, Semgrep 1.186.0, oras v1.4.0, the ZAP digest, CloudNativePG 1.30.2, Reloader
   2.2.21). Run `--apply` (with the workflow files), re-record what the pins are recorded into
   (`deploy/helm/tests/run.sh --update`), then `actionlint`. Minor and patch only: a major jump is listed in the
   handover, not applied. An action pin is the dereferenced commit, never a tag object.
2. **Read before trusting**: for each bumped image read the release notes for breaking changes that touch this repo
   (Redpanda's admin API and ACL bootstrap, Redis ACL user, Semgrep rule ids and the acceptances in
   `.semgrep/accepted.json`, ZAP rule ids in the gate files, Trivy result format). Run the Semgrep image locally with
   the repo rules and the gate (`scripts/sarif-gate.py`) so a new finding is seen here, not in CI.
3. **PostgreSQL in the bump script**: red test first in the script's tests: a `Pin` for PostgreSQL that covers every
   place the major is pinned (`infra/compose/compose.yaml`, the `databases` sub-chart's `values.yaml`,
   `PostgresRlsResource`, finance's `pgtest.go`, `.github/workflows/images.yml`) and reports a newer minor of the same
   major; a new major is reported, never applied. Do not change the PostgreSQL version itself: WP144 does that in wave
   2 and will move your pin's files.

## Acceptance
- [ ] `scripts/bump-pins.sh --check` reports only what you deliberately left (name each, with the reason)
- [ ] `python3 -I -m unittest discover -s scripts/tests`, `deploy/helm/tests/run.sh`, `actionlint`, `just test-go`
      (the Redpanda Testcontainers pin) and `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh;
      totals)
- [ ] Semgrep run locally with the new image: gate result recorded
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
- Do not read, copy or print any `.env`. The compose stack that is running is the owner's: do not `just down` it, do
  not remove or recreate its volumes. What needs the real stack or the owner's database comes back "not run" in the
  handover; the orchestrator runs it from the main checkout at merge time.

## Handover
- Built: (1) `scripts/tests/test_postgres_pin.py` (red first, 10 tests) and the `postgresql` pin in `scripts/bump_pins.py`: one pin over
  the five files that name the major (`compose.yaml`, the `databases` sub-chart `values.yaml`, `PostgresRlsResource`,
  `pgtest.go`, `images.yml`; both `docker.io/library/postgres:` and `ghcr.io/cloudnative-pg/postgresql:`), tags resolved
  from `docker.io/library/postgres`. A newer minor of the pinned major is applied; a pin naming the major alone (today
  `17`) stays and the check prints `major 19.0 available (--major)` without counting it outdated; a new major is only
  applied with `--major`. A test also fails when a file names a PostgreSQL image outside the pin. The version itself is
  untouched (still 17). (2) The 12 outdated pins applied with `--apply` (workflow files included): distroless java25
  digest, Redis 8.12.0-alpine, Redpanda v26.3.1 (chart, compose, finance test, Dev Services), Mailpit v1.34.0, otel-lgtm
  0.41.1, Trivy 0.76.2 (ci.yml, image-publish action, sbom.sh, tofu/check.sh), Semgrep 1.186.0, oras v1.4.0, the ZAP
  digest, CloudNativePG 1.30.2, Reloader chart 2.2.21 (app v1.4.25). Chart snapshots re-recorded (`run.sh --update`).
- Verified (fresh, 2026-11-24): `./mvnw -o -B -ntp -T 1C verify -Dquarkus.http.test-port=0` BUILD SUCCESS: contracts 346,
  common-quarkus 580, core 1262, game 528, athlete 1026 tests, 0 failures/errors/skipped. `just test-go` rc 0 (all
  packages ok, incl. the Redpanda Testcontainers consumer test on v26.3.1; coverage gate and govulncheck passed).
  `python3 -I -m unittest discover -s scripts/tests`: 118 tests OK (1 skipped, as before). `deploy/helm/tests/run.sh`: ALL
  CHART TESTS PASSED. `actionlint`: clean. `scripts/bump-pins.sh --check`: 0 outdated of 17 pins (the only remark is the
  PostgreSQL note about major 19.0, deliberately not applied: WP144). Semgrep 1.186.0 run locally with the workflow's exact
  command: repo rule tests 11/11 passed; scan 441 rules on 1864 files, 27 findings (26 ERROR, 1 warning); the gate
  (`scripts/sarif-gate.py --fail-on error --baseline .semgrep/accepted.json`) exit 0, 26 of 26 accepted, no stale entry.
- Release notes read and what was run locally (image behaviour, throwaway containers, all removed afterwards):
  - Redpanda v26.2.7 -> v26.3.1 (docs.redpanda.com release notes; GitHub releases stop at v26.2.2): no on-disk format
    change listed, no irreversible flag or downgrade restriction listed; `protected_mode` is new but only for new
    development-mode clusters, "clusters upgraded from 26.2 are unchanged". Admin API additions only; ACL changes are about
    auto-topic CREATE and shadow links (not used here). Observed: a fresh dev-container broker with the compose command
    and `redpanda-bootstrap.yaml` reports `protected_mode: false` and answers the admin API through the published port.
    DATA VOLUME: tested in place: v26.2.7 on a throwaway volume, topic created and one record produced, container
    removed, v26.3.1 started on the SAME volume: healthy, the record read back at offset 0, no errors in the log. So the
    owner's `redpanda-data` volume moves 26.2 -> 26.3 in place. After the new version runs, treat the move as one way
    (the notes name no downgrade path): keep a copy of the volume if a way back is wanted.
  - Redis 8.10.3 -> 8.12.0: the chart's Redis is in-memory only (`--save ""`, `--appendonly no`, emptyDir), so there is no
    data volume to affect. Notes list only new commands/features. Ran the image with the chart's flags and an ACL file:
    ACL user works, default user off, `CONFIG` renamed away, protected-mode off accepted.
  - Mailpit v1.33.1 -> v1.34.0: security fix (SMTP crash); removes flags/env deprecated for 2+ years and validates
    settings at start. The chart sets only `MP_MAX_MESSAGES`: unaffected. No data volume in the chart.
  - otel-lgtm 0.41.0 -> 0.41.1: Grafana 13.3.1, Loki 3.7.10, container now fails when a required service exits. Compose
    keeps `/data` on a 512 MB tmpfs: no volume.
  - oras v1.3.6 -> v1.4.0 (oras-go v3, per-command auth cache): ran `scripts/sbom.sh attach` against a throwaway
    registry (a pushed artifact, SBOM attached, `oras discover` showed the referrer). Works.
  - Trivy 0.76.2: security rebuild only. Semgrep: see above. Reloader chart 2.2.21 / app v1.4.25 and distroless: digests
    only (release notes empty / floating tag). ZAP: floating `stable` digest.
  - CloudNativePG 1.30.1 -> 1.30.2 (operator, kind and the cloud VM): new default operand image is 18.7 for clusters that
    set no image (the chart sets `imageName` explicitly: unaffected); the operator needs `delete` on `leases` (the operator
    chart manifest brings its own RBAC; users managing RBAC by hand must add it); PostgreSQL 14 support dropped. No cluster
    data effect. WP144 should read the 1.30.2 notes: they name PostgreSQL 18.7 / 17.12 and 19 RC2.
- Decisions/ADRs: none (ADR-0076 not used).
- Not run: ZAP API scan with the new digest (needs the owner's stack: `scripts/zap-api-scan.sh`; the gate script tests
  pass), Trivy fs/image scan and the `image-publish` action with 0.76.2 (CI), the Semgrep job in CI itself, kind/Helm
  install of CloudNativePG 1.30.2 and Reloader 2.2.21 (`deploy/kind/up.sh`; no kind here, would collide with WP144), the
  Redpanda SASL/ACL chart path on kind (the Java `SaslRedpandaResource` tests ran on v26.3.1 in `verify`), the owner's
  running stack (untouched). `just isolation-check` / `db-role-check` not run by hand (no tenancy change; the commit hook's
  isolation check was green on commit).
- Open points: (1) the orchestrator recreating the owner's stack keeps the Redpanda volume: tested in place above.
  (2) `docs/runbooks/release.md` section 6 and `docs/security/sast-dast.md` still name old versions only in prose if
  at all; not touched (docs pass, WP147). It should mention that the bump script now also tracks PostgreSQL. (3) For
  WP144: the PostgreSQL pin's regex takes `\d+` or `\d+.\d+` followed by a non-tag character; a CloudNativePG tag such as
  `19.0-standard-trixie` is NOT matched as one tag, so WP144 must adapt the pin (regex, and `repo`/`tag_re` for CNPG's
  flavoured tags) when it changes the chart's `imageName`; `test_postgres_pin.py` fails until the pin matches every
  mention. Docs, prose comments in `PostgresRlsResource` and `pgtest.go` ("postgres:17") are not part of the pin.
  (4) The pre-commit isolation hook timed out several times under host load (and once failed on a Keycloak Testcontainers
  wait); retried without any bypass.
