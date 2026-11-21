# Session handover (updated 2026-11-16 — eighth round WP111–WP125 done: pdf-service in Rust, finance-service in Go)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05, the four rounds of 2026-11-06/07, the sixth round
of 2026-11-10, the seventh of 2026-11-14 and the eighth of 2026-11-15/16, the product owner's decisions 1–103 and the
backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder (`.../Code/Claude/projects/dummy-project2`)
is archived and must not be written to. Hoops Academy is a learning project, not a commercial product (ADR-0025).

## State
- Built and committed: all v1 work packages (WP0–WP20), WP21–WP25, the twelve WPs of 2026-11-05 (WP26–WP37), the
  rounds of 2026-11-06/07 (WP38–WP90, no WP79), the sixth round (WP91–WP103), the seventh round (WP104–WP110; WP109's
  JDK 25 merged on 2026-11-15, bef81d3d) and the eighth round of 2026-11-15/16 (WP111–WP125; details in FOLLOW-UPS
  "Resolved", "Eighth round"). Five deployables now: core, game, athlete (Quarkus, Java 25), `pdf-service` (Rust) and
  `finance-service` (Go), plus the web image (ADR-0051).
  Merged into `main` in this order (handover or last commit of each; WP112 and WP115 on 2026-11-15, the rest on
  2026-11-16, Jakarta time):
  - WP112 (af408107) LINDDUN privacy threat model `docs/security/privacy-threat-model.md`, findings P-01..P-13
    (P-01..P-05 must be closed before real academies).
  - WP115 (7c4421eb) language and theme on the academy chooser; compose nginx `limit_req` (10/min + 2/s per IP) for the
    CSV exports and the public academy request; `team.roster_exported` wording.
  - WP113 (bea1365c) PMD 7.29.0 and CPD in `verify` (ADR-0053, `docs/quality/pmd.md`).
  - WP114 (d56c43eb) Java services on distroless `java25-debian13:nonroot` by digest, no shell, uid 65532 (ADR-0054):
    closes the `images` red of the seventh round.
  - Orchestrator: 4d10d7cf (the WP115 nginx limit counted the super admin's list of academy requests; now only the
    public POST), 54e7a2da (`tenant_timezone_test.dart` failed late on Sundays in UTC), ef6cb697 (dated ZAP acceptance,
    40018 on `/platform/academy-requests`, until 2027-05-16).
  - WP111 (2a8172c2) `pdf-service` in Rust: Cargo workspace with crates as layers, krilla, Clippy pedantic, coverage
    gates, `cargo deny`, distroless image, compose profile `pdf`, chart 0.11.0 sub-chart without a route (ADR-0052,
    ADR-0051 amendment). Orchestrator dd54179d: the realm's `pdf-service` audience mappers on `core-service` and
    `game-service`.
  - WP116 (c06988b0) core 3.7.0: the roster export as PDF by `Accept: application/pdf` through pdf-service (audited,
    `format` `pdf`; 503 `UPSTREAM_UNAVAILABLE`, 422 over the sheet's limits); the audit `team` target named (ADR-0048,
    ADR-0034 amendments).
  - WP117 (a8ac9890) game 2.4.0: `GET /api/game/matches/{id}/box-score:pdf`, the match sheet for every member who sees
    the box score; game V7 keeps the academy name in its replica; the start guard for `replica` without its consumer.
  - WP118 (a40d3960) `finance-service` in Go: the whole `finance.yaml` 1.0.0 (26 operations), settings and fee plans,
    the tenancy harness in Go wired into `just isolation-check` / `just db-role-check`, membership replica, distroless
    static image, compose profile `finance`, chart 0.12.0 (ADR-0055, ADR-0056). Orchestrator fe0a1e9a (the web client's
    `finance-service` audience in core's `RealmTokenPolicyTest`), 0c9309aa (the `images` finance check's cleanup),
    a9649e02 (Go before CodeQL's init).
  - WP122 (55de9963) web: PDF buttons on the team page (ADMIN, the team's current coach) and on the live match (every
    role that opens it).
  - WP120 (d677c9c9) one Grafana LGTM pod behind the collector on kind and as a compose profile, metrics through the
    collector, three dashboards, 24 h retention, anonymous Viewer; chart 0.13.0; the cloud values keep the in-memory
    Jaeger (ADR-0046 amendment).
  - WP121 (3e932f7e) web: the Finance area for ADMIN under the admin hub (currency, fee plans, dues, payments).
  - WP119 (1edf2029) finance: full roster replica (V10–V12), dues by hand (with a preview) and by an hourly-ticking
    daily job under an advisory lock, payments and voids, waivers, amount changes, the coach's and the family's reads
    (ADR-0056 amendment).
  - WP124 (94c27d7c) web: expenses, the season balance and both CSV exports for ADMIN; "Dues up to date" on the team
    page for its current coach; a "Dues" tab for parents and players.
  - WP123 (faa732eb) finance: expenses (V20), season balance, CSV exports, no operation left 501 (V21, V22: slug and
    team names in the replica); journey steps 14–18 and 55; the `e2e` workflow starts pdf-service and finance-service
    and scans finance with ZAP; the finance demo data in `just seed-academy` (ADR-0056 amendment).
  - Orchestrator after the docs pass was cut: 9bb4bdb2 (the seed's finance phase failed on macOS: a `-0` day offset
    that BSD `date` rejects, HTTP 400 after the dues), 031e1155 (`services-up.sh` starts pdf and finance with
    `--no-deps`: in CI compose had recreated Postgres, Redpanda and Keycloak under the running jars, e2e run
    43813211365, login page 502), 3f964fb2 (`HOOPS_FINANCE_BIND`, default 127.0.0.1, 0.0.0.0 in the e2e workflow: on
    Linux nginx could not reach a loopback-published port, e2e run 43814612481, 502 on `/api/finance`).
  Contract versions now (read from the files): **core 3.7.0, game 2.4.0, athlete 3.0.0, common 1.1.1, pdf 1.0.0,
  finance 1.0.0**; event schemas unchanged (finance and game read the existing `core.*` topics). Dart packages: core
  3.7.0, game 2.4.0, `hoops_finance_api` 1.0.0 (new). Helm chart **0.13.0** (`databases` 0.1.0, `keycloak` 0.6.0,
  `hoops-service` 0.9.0 for core / game / athlete, `web` 0.2.0, `pdf-service` 0.2.0 as `pdf`, `finance-service` 0.2.0 as
  `finance`). New ADRs 0052–0056; amended ADR-0051 (twice), ADR-0046, ADR-0048 (twice), ADR-0034, ADR-0056 (twice).
- Tests, as the last handovers report them (none re-run by WP125):
  - **Java**: `just test` at WP123 (its worktree, 2026-11-16): Maven **3,556 tests**, 0 failures, 0 errors, 32 skipped
    (the e2e module runs 38: 6 `MailSinkTest` and 32 journey steps skipped without `e2e.baseUrl`); PMD / CPD,
    SpotBugs and JaCoCo gates met. Last per-module counts: common-quarkus 403, core 1,225 (WP116), game 541, athlete
    1,003, contracts 322 (WP117; WP116's branch had 323); WP118 then added finance contract suites. Under `-T 1C` the
    console can lose module summaries (WP117): count from the surefire reports.
  - **Rust** (`just test-rust`): **100 tests**, line coverage 95.41 % workspace / 99.80 % domain, `cargo deny` ok
    (WP111; the same in WP118, WP119, WP123).
  - **Go** (`just test-go`): **204 tests** (158 top-level), coverage 89.05 % module / 98.84 % domain, golangci-lint 0
    issues, govulncheck nothing reachable (WP123).
  - **Flutter**: `flutter test` **1,801 passed** (WP124; 1,507 at the start of the round, 1,542 after WP122, 1,652
    after WP121).
  - **Mutation**: core 932/933 (WP116), game 555/557 (WP117); common 337/338 and athlete 690/690 unchanged since WP109;
    web: every file of the manifest at 100 % (494 viable mutants, 2026-11-15). No mutation testing for Rust or Go yet.
  - **Gates and scripts**: `just isolation-check` 6 Java + 4 Go tests, `just db-role-check` 13 Java + 2 Go (WP123);
    `just test-hooks` 55/55 + 5/5 + 3/3 and 43 Python tests OK, 1 skipped (WP120, WP123); `deploy/helm/tests/run.sh`
    ALL CHART TESTS PASSED, 231 checks, kubeconform 397 resources (WP120).
  - **e2e on compose**: the orchestrator's `just e2e` from the main checkout after the WP123 merge: 38 tests, 0
    failures, `JourneyTest` 32 steps, none skipped: the first real core -> pdf-service and game -> pdf-service calls
    (WP116, WP117 and WP123 had only stubs; their worktrees could not sign in to the shared database).
- **Kind this round** (each in its own window with compose stopped, cluster deleted afterwards): WP111 on 0.11.0
  (`smoke.sh` 52 ok twice; core's token refused until the audience mappers were added at runtime, then a roster PDF
  rendered by pdf-service), WP118 on 0.12.0 (`smoke.sh` with finance 61 ok: replica lag 0, a fee plan through the
  gateway, academy B 404, `finance_app` not owner / superuser / BYPASSRLS), WP120 on 0.13.0 (`smoke.sh` 60 ok; a trace
  gateway -> core -> pdf-service -> render in Grafana; logs of all five services in Loki). **Not proven on kind**: `tilt
  ci` (last on 0.9.0), the e2e journey, the dues / payments / expenses code of WP119 and WP123 (WP120's images predate
  them), ESO and Reloader with the new Secrets. Nothing in the cloud (decision 88).
- **Local stack**: compose has pdf-service and finance-service (started by the orchestrator's `just e2e`); after
  9bb4bdb2 the orchestrator ran `just events-backfill force` and then `just seed-academy` twice ("7 things created",
  then "nothing to create"; `just events-drift` equal), so the Test Academy holds the finance demo data. The compose
  database still holds junk tenants and admins from the ZAP scans.
- **Security**: F-01..F-24 unchanged (22 fixed, F-11 and F-22 accepted by design; SD-03 accepted until 2027-05-07).
  New: privacy findings P-01..P-13 (2 Medium, 8 Low, 3 Info; P-07 and P-12 partly mitigated, P-10 for finance, P-11
  in code: `docs/security/privacy-threat-model.md` "Status after the eighth round"). New acceptances until 2027-05-16:
  ZAP 40018 on `/platform/academy-requests` (core) and on the two finance export paths (pre-accepted, not yet seen).
  Trivy on the new images: 0 HIGH / CRITICAL (core, game, athlete on distroless; pdf; finance after golang.org/x/net
  0.62.0).
- **Interruptions**: a network outage stopped wave 2 for about five hours (the watchdog resumed the agents); a usage
  limit stopped wave 4 once (resumed after the reset).
- CI on `main` (observed with `gh run list -b main -L 15` on 2026-11-16, after the orchestrator's 3f964fb2): on
  3f964fb2 `ci` 43815905569, `e2e` 43815905637 (`JourneyTest` 32 run, 0 failures, 0 skipped; ZAP API scans of core,
  game, athlete and finance through the gate), `codeql` 43815905544 and `semgrep` 43815905530 all **green**; no
  `images` run for it (no image input changed): the last `images` is 43813211306 on 2f51edb3, **green**. Reds of the
  round, all followed by a fix or a re-run: `images` red until WP114 (last red 43739416660 on 97b10331; first green
  43739804752 on d31dfd05) and on 53df1e6e (43792899975, fixed by 0c9309aa); `codeql` red on 53df1e6e and 0c9309aa
  (fixed by a9649e02); `ci` job `flutter` red on 97b10331, d31dfd05, 4d10d7cf (the Sunday time-zone test, 54e7a2da);
  `ci` job `dependency-check` red on 54e7a2da (43741030041), on 2f51edb3 (43813211248) and on the first attempt of
  7f7d4284 (43811663987, green on re-run) through NVD API errors (a third-party outage); `e2e` red on 5af6b6ea,
  97b10331, d31dfd05, 4d10d7cf (the WP115 nginx limit, 4d10d7cf / ef6cb697), on 2f51edb3 (43813211365, 031e1155) and
  on 031e1155 (43814612481, 3f964fb2).
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0), branch `main`. Open: pull request #6 (bump-pins) and the
  Dependabot PRs #8, #9, #10, #11, #13 (the first `cargo` updates for pdf-service among them). Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secrets `NVD_API_KEY` (repository and Dependabot). Images per
  commit on ghcr.io with their SBOMs as OCI referrers, now also `pdf-service` and `finance-service`. Dependabot: weekly
  grouped updates (Maven, pub, GitHub Actions as SHA + tag, and since this round `cargo` and `gomod`) with a 7-day
  cooldown; the `json-schema-validator` major is ignored (WP43). The weekly `bump-pins` PR covers the Java runtime
  digest and the LGTM pin, not the pdf / finance base images nor pins inside workflow files.

## 2026-11-21: Java4Shell patch and documentation site
- **CVE-2026-114938 ("Java4Shell")**, memory corruption in the JDK's hardware-accelerated Base64 decoder (x86-64 with
  AVX-512 VBMI only), fixed in JDK 25.0.5.1 and 21.0.13.1. Patched here: the runtime image digest of
  `deploy/containers/service.Containerfile` (Temurin 25.0.5.1+2), Keycloak 26.8.1 -> 26.8.2 (Red Hat JDK 21.0.13.1;
  compose, chart, `TestRealm`), and `just doctor` now requires JDK >= 25.0.5.1 (`brew upgrade openjdk@25`). CI takes
  the newest Temurin 25 on each run. Nothing was deployed anywhere, so there was no exposed instance.
- **Keycloak 26.8.2 needs the `kc-admin-api` client scope** on `core-service` (Admin API audience check). The realm
  file has it, and `just seed-users` adds it to a realm imported earlier without touching its data
  (`docs/runbooks/troubleshooting.md`, "core-service gets 401 from the Keycloak Admin API").
- **Documentation site** (ADR-0057): `docs/` built by Zensical, strict build in `ci` (`docs-site`), published to
  GitHub Pages by `pages.yml`. `just docs-serve` / `just docs-build`; `docs/runbooks/docs-site.md`.

## Pending user actions
1. **First real `tofu apply`** (still the first candidate; WP104 handover, `docs/runbooks/cloud.md` "Before the
   first apply"). The owner prepares: an Alibaba Cloud international account with a payment method; a RAM user
   `hoops-tofu` with programmatic access only and the runbook's regional ECS/VPC policy; its key in `.env`
   (`ALIBABA_CLOUD_ACCESS_KEY_ID` / `_SECRET`) or an aliyun profile; `TF_VAR_state_passphrase` (16+ characters, backed
   up); `terraform.tfvars` with their IP as /32 and their public key; a `main` commit whose images are on ghcr.io; strong
   fresh values everywhere in `.env` (`install.sh` refuses `change-me`), including the three finance keys.
2. **Other stacks after the round**: on the owner's compose stack the orchestrator already ran the backfill and the
   seed (State). Any other stack (another machine, kind, the cloud): `just finance-up` (roles, migrations to V22),
   `just events-backfill force` (slug and team names in finance's replica, academy names in game's: until then the
   match sheet prints "Hoops Academy"), then `just seed-academy`. `.env` has three new keys (`FINANCE_MIGRATOR_PASSWORD`,
   `FINANCE_APP_PASSWORD`, `REDPANDA_FINANCE_SERVICE_PASSWORD`): the main checkout's `.env` has them since 2026-11-16;
   any other `.env` needs them (kind's `env-keys.sh` refuses to start without).
3. **IDR minor digits** (owner decision, WP121 / WP124): finance stores IDR with 2 minor digits (ISO 4217) and the web
   shows whole amounts without decimals. Change the service's currency table and the web's copy together if 0 is
   wanted, before the first real IDR due.
4. **Real-browser checks nobody ran**: the two PDF buttons (a real download, the name from `Content-Disposition`, the
   PDF opening) and **the whole Finance area** against the real finance-service (admin screens, coach status, family
   dues, the CSV exports): built and tested against the demo mock only (WP121, WP122, WP124). Older ones still open:
   sign in as `superadmin@hoops-academy.com` (should land on the application admin hub); the hub and the context
   switcher on the real stack; a calendar `.ics` in a calendar app; the server-side roster and audit CSVs downloaded
   from the web; the avatar menu and the chooser's language and theme cards; the families' catalogue; the WP107 demo
   data next to the landing screenshots. The compose nginx does not serve the web app: start it locally (`./start.sh`
   or `flutter run`, README) and sign in, e.g. as `testcoach1@hoops-academy.com` with `TEST_ACADEMY_PASSWORD`.
5. **bump-pins PR #6** (mailpit v1.33.1, External Secrets Operator v2.15.0): close and reopen it so `ci` / `e2e`
   start (a `GITHUB_TOKEN` PR starts no checks); the ESO bump needs a kind proof (`up.sh --eso --deploy --from-host`,
   ExternalSecrets synced) before merging. Review the Dependabot PRs #8–#13.
6. **Workflow-file pins by hand**: Trivy, Semgrep and the ZAP digest with `scripts/bump-pins.sh --apply`, then
   `actionlint`. Optional: a fine-grained PAT (contents + pull requests + workflows) so the weekly PR includes them and
   starts its own checks.
7. **File the Envoy Gateway issue** from `docs/upstream/envoy-gateway-global-ratelimit-descriptor-collision.md`
   (decision 49; WP100 re-tested on v1.10.0: still collides, add that to the draft); drop the `path: /` selector once
   fixed upstream.
8. **Podman machine, in a quiet window (optional)**: `just doctor`'s real write-and-restart path for the drop-in ran only
   against stubs, and `podman machine init --playbook infra/podman/machine-playbook.yml` was never run (WP93).
9. **Local chromedriver** is 156, CI pins Chrome for Testing + chromedriver 157.0.8103.38; update the local one when the
   local Chrome moves.
10. Review the Dependabot and `bump-pins` PRs as they arrive (weekly, Monday).

## Working conventions learned the hard way
- **Parallel sessions and rounds of work packages:** follow `.claude/skills/wp-round` (one worktree per session or WP
  under `$HOME`, never switch branches in a shared checkout; `gitleaks protect --staged` + `git commit` with explicit
  paths; waves of at most four building agents, ownership, ADR numbers, merge protocol and traps).
- **Three languages in `just test`** (eighth round): Maven `verify`, then `just test-rust` (rustfmt, Clippy all +
  pedantic with warnings denied, tests under cargo-llvm-cov with 80 % / 90 % domain gates, `cargo deny`), then `just
  test-go` (gofmt, golangci-lint, tests with the RLS and isolation suites, 80 % / 90 % domain gates, govulncheck). The
  Rust toolchain is pinned in `services/pdf-service/rust-toolchain.toml` (1.99.1, rustup installs it on first use), Go
  by `go.mod`'s `toolchain go1.27.4`; `scripts/bootstrap.sh` installs rustup, cargo-llvm-cov, cargo-deny and the Go
  tools, `just doctor` checks them. Skills: `rust-service`, `go-hexagonal-service`.
- **PMD / CPD gate in `verify`** (ADR-0053): a violation fails the module with `PMD Failure: <Class>:<line> Rule:...`
  or `CPD Failure`; refactor first (table "When the gate fails" in `docs/quality/pmd.md`), accept only with a reason
  line in `config/pmd/exclude-*.properties`; never a blank line in the CPD file (the plugin then accepts every
  duplication; `scripts/tests/test_pmd_exclusions.py` guards it), never `// NOPMD`.
- **Distroless images have no shell** (ADR-0054; also pdf-service and finance-service): no `kubectl exec ... curl`;
  read metrics with `kubectl port-forward` (as `deploy/kind/smoke.sh` now does) or an ephemeral `kubectl debug`
  container; extra JVM flags go in `JDK_JAVA_OPTIONS`. Pods run as 65532.
- **The commit hook gates the main checkout, not the worktree**: `.claude/hooks/tenancy-gate.sh` runs `just
  isolation-check` in the session's working directory, so an agent committing in its worktree checks `main`'s tree.
  Agents of this round ran `just isolation-check` / `just db-role-check` by hand in their worktrees (open item in
  FOLLOW-UPS).
- **Agents' worktrees have no usable `.env` for the shared compose database**: a worktree `.env` built from
  `.env.example` is refused by Postgres (`core_app`, `finance_app` password authentication failed), and agents were
  told not to copy the main checkout's values. So real calls against compose (the journey, pdf-service, the seed) run
  from the main checkout after the merge; plan that step in the briefs (WP116, WP117, WP123 could not run them).
- **Shared compose database and finance migrations**: a finance binary with fewer migrations than the database has
  refuses to start (history without files, WP119), like Flyway without `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS` for
  the Java services; branch binaries of finance should not migrate the shared database before their merge.
- **`git commit --no-verify` is refused in agent sessions**: agents commit with a plain `git commit` and explicit paths
  after `gitleaks protect --staged`; the pre-commit hooks then run, and their whitespace fixers can trim generated Dart
  files (re-add and commit again).
- **Flutter 3.50.0 / Dart 3.14** on this Mac: widgets come from the `material_ui` and `cupertino_ui` packages, not
  `package:flutter/material.dart` (51f2dd0c). The repository does not pin Flutter and CI follows the stable channel, so
  a new stable can turn `flutter analyze` red without a commit of ours.
- **OpenTofu and JDK 25 installed with Homebrew** (`opentofu` 1.13.9, `openjdk@25` 25.0.5): `scripts/env.sh` selects
  exactly JDK 25; `just tofu-check` needs OpenTofu.
- **Wait for `ci` before stacking the next web merge**: the browser smoke (`web-browser`) runs only in `ci`.
- **Pass known gate rules to agents in their prompts**: constant SQL with bound parameters (CodeQL), the tenant-switch
  rule of Semgrep (a nil-tenant bind needs a dated acceptance), no environment-derived program names in scripts and
  tests (Semgrep taint), the PMD thresholds; for Go and Rust their own linters run inside `just test`.
- Claude Code hook (`.claude/settings.json` -> `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude runs
  `git commit` it runs `just isolation-check` (~40 s; since WP118 also finance's Go `TestCrossTenant*` tests); before
  `git push`, `just db-role-check` (also finance's Go role tests). It parses the command and gates only a real
  `git commit` / `git push`; by choice an unquoted `echo git commit` and a heredoc with unbalanced quotes still gate.
  `--no-verify` does not skip it; commits made in a terminal are not gated. `just test-hooks` runs its case table.
- **Load on the 2-CPU, 8 GB Podman VM.** Four parallel builds hold, but under load the hook's isolation check can time
  out (retry once a build has finished; never bypass it), a parallel build can take a fixed port (WP119: "Port already
  bound: 8081"; re-run the module with `-Dquarkus.http.test-port=0`), and on kind liveness probes restart services at
  load 13–66 (WP120 at 40). The LGTM pod needs about 1.2 GiB: kind with it fits only with compose stopped.
- **Podman API idle timeout**: the `--time=0` drop-in (WP87) is on the VM; `just doctor` checks it and rewrites it when
  missing (WP93), `infra/podman/machine-playbook.yml` restores it after a re-init.
- **Roster replicas are the default**: a service started without a broker in prod or dev mode needs
  `GAME_ROSTER_SOURCE=rest` / `ATHLETE_ROSTER_SOURCE=rest` (the test profile pins `rest`); since WP117 game, like
  athlete, refuses `replica` with its consumer off. After seeding or a manual change, `just events-drift` checks core
  against both Quarkus replicas (not finance's, and not game's new academy name column); a replica lags 1–2 s.
- **Model diagrams**: after a Flyway migration or a `domain` / `application` type change in core, game or athlete run
  `just diagrams` and commit the pages; `just diagrams-check` (CI job `model-diagrams`) fails otherwise. Finance has no
  generated page (ADR-0056 holds its model).
- **Test academy**: `just seed-academy` (needs `just up`, `just seed-users`, `just services-up` and
  `TEST_ACADEMY_PASSWORD` in `.env`; since WP123 also `just finance-up`) is idempotent; it retries on the nginx `auth`
  limit; a withdrawn academy keeps its slug and its Keycloak logins. `SEED_ACADEMY_DEMO=0` skips the demo phase,
  `SEED_ACADEMY_DEMO_ONLY=1` runs only it; a full run takes 1.5–4 minutes.
- **finance-service behind the compose nginx**: works on macOS by default; on Linux only with
  `HOOPS_FINANCE_BIND=0.0.0.0` (the port is published on 127.0.0.1 by default and nginx cannot reach a loopback-published
  port there; the e2e workflow sets it, 3f964fb2).
- **Compose profiles**: `just pdf-up` (:8084), `just finance-up` (:8085), `just observability-up` (Grafana on
  127.0.0.1:3000, anonymous Viewer; `HOOPS_OTEL_SDK_DISABLED=false` for pdf / finance, `QUARKUS_OTEL_SDK_DISABLED=false`
  for `quarkus:dev`); `just down` stops all of them. A change to `infra/compose/nginx*.conf` needs `podman exec
  hoops-nginx nginx -s reload` (WP115).
- **Rate-limit and outage pauses** (agent sessions): an agent may pause and resume in the same worktree; check the
  worktree's `git status` and log before trusting its last report.
- **Fresh Helm install with events on**: core's producer is created at the first send and recovers by itself;
  `smoke.sh` checks the producer login after the seed.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH.
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/*.conf` with `[alert=..][url=..][expires=..]` scoping (one
  file per scanned API, `api-finance.conf` since WP123). The Actions token cannot push workflow files. The `ci` job
  `dependency-check` can fail on NVD API errors: re-run it.
- `.env` needs `RATELIMIT_REDIS_PASSWORD`, the `REDPANDA_*_PASSWORD` keys and (since WP118) the finance keys, otherwise
  `deploy/kind/secrets.sh` and `eso-store.sh` stop; the SMTP keys are optional locally.
- Time-dependent tests: CI runs at any hour; derive dates from the test's "now" in the zone the code uses, never a fixed
  weekday and local time (54e7a2da: a test failed late on Sundays in UTC).
- Realm changes need a Keycloak re-import (`just down && podman volume rm hoops_pgdata && just up && just seed-users`)
  or, for the settings it knows (clients, audience mappers), `just seed-users` alone.
- Parallel worktrees share the compose database: a Quarkus service started from a branch that lacks a migration another
  worktree already applied needs `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future,*:missing'` until both are merged.
- **Podman VM clock drift** after the host sleeps: the hook scripts step the VM clock before each check; by hand:
  `podman machine ssh "sudo date -u -s @$(date +%s)"`.

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- **First candidate: the real `tofu apply` on Alibaba Cloud** once the owner has prepared the account and key
  (Pending 1): plan, apply, kubeconfig, `install.sh` (now with pdf-service and finance-service), seed and smoke through
  `with-cloud.sh`, destroy, each step of `docs/runbooks/cloud.md` marked NOT YET RUN today; then narrow the RAM policy.
- **The round on a real stack**: the owner's browser walk-through of the Finance area and the PDF buttons (Pending 4)
  after Pending 2; then a kind proof of the whole round (`up.sh --deploy` with current images, the journey on kind,
  `tilt ci` on 0.13.0, ESO and Reloader with the finance Secrets).
- **Privacy gate before real academies** (P-01..P-05): an ADR for erasure as pseudonymisation and a per-person export
  across the four data services; the purge job with written periods (finance included); a core job deleting old
  published outbox rows; an audit trail for health writes; a privacy notice in es / en / id and a DPIA note.
- **Observability depth**: database spans (`quarkus.datasource.jdbc.telemetry=true`, a pgx tracer), request metrics
  for pdf and finance, Keycloak / Envoy / Redpanda logs to the collector, alerting on `hoops_authz_denied_total`.
- **Tooling for the new languages**: mutation testing for Rust (`cargo-mutants`) and Go (`gremlins`), the pdf / finance
  base images in `bump-pins`, a finance replica lag metric and `applied_event` retention, generated finance diagrams;
  the commit hook following the commit's worktree.
- **Recapture the landing screenshots** (owner's wish; now also the PDF icons and the Finance area).
- **Users area depth**: e-mail change and a temporary password from the application admin's Users list.
- **Billing** module on the existing seams (`billing.*`, `EntitlementService`, the published outbox events; the hub's
  placeholder); stays in core, in Java (ADR-0051).
- Smaller: the finance and PDF leftovers (FOLLOW-UPS "Product / contract decisions"), the language and theme on the
  profile screen, the breached-password check (decision 60), an optimised Keycloak image (decision 63), the kit wishes
  of WP92, the remaining 155 fitness-norm placeholders (`docs/domain/norms.md`).
