# Session handover (updated 2026-11-24 — ninth round WP126–WP140 done: the audit's duplication and inefficiencies)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05, the four rounds of 2026-11-06/07, the sixth round
of 2026-11-10, the seventh of 2026-11-14, the eighth of 2026-11-15/16 and the ninth of 2026-11-23/24, the product
owner's decisions 1–113 and the backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder
(`.../Code/Claude/projects/dummy-project2`) is archived and must not be written to. Hoops Academy is a learning
project, not a commercial product (ADR-0025).

## State
- Built and committed: all v1 work packages (WP0–WP20), WP21–WP25, the twelve WPs of 2026-11-05 (WP26–WP37), the
  rounds of 2026-11-06/07 (WP38–WP90, no WP79), the sixth round (WP91–WP103), the seventh (WP104–WP110), the eighth
  (WP111–WP125) and the ninth round of 2026-11-23/24 (WP126–WP140; details in FOLLOW-UPS "Resolved", "Ninth round").
  Five deployables: core, game, athlete (Quarkus, Java 25), `pdf-service` (Rust) and `finance-service` (Go), plus the
  web image (ADR-0051).
- **The ninth round** came from a read-only audit of the whole repository for duplication and inefficiencies on
  2026-11-23 (173 findings: 119 confirmed, 49 confirmed with corrections, 5 already known). The audit files are local,
  untracked working material (decision 111); every brief names its finding IDs (`CORE-01`, `X-03`, `INF-03`, …) and
  every handover ends with an ID-by-ID table, so the record is in `docs/wp/WP126-*.md` … `WP139-*.md`. No new feature;
  bugs found on the way were fixed with a red test first.
  Merged into `main` in this order (handover or last docs commit of each; 2026-11-23 and 2026-11-24, Jakarta time):
  - WP129 (983691e2) web: lists a screen needs whole read every page through `fetchAll`, one kit `Pager` (ADR-0061);
    the live match stops polling when left; dead keys and `ModulePlaceholder` gone.
  - WP126 (45273b84) game: one read of the match per ingest batch, `sync_receipt` dropped (V9), the feed cursor race
    and a record parked twice fixed (V8) (ADR-0030, ADR-0037 amendments).
  - WP127 (a93bbb2a) athlete: per-request roster answers and `teamsOf`, the tenant zone from the caller's context
    (ADR-0059; V11), the 90 % domain gate (athlete had none), the Monday-dependent `ScheduleApiTest`.
  - WP128 (df5fcf26) core: guardian-link N+1, the outbox sent per batch (ADR-0060), one paged-query builder, dead
    code, V20 / V21, Quarkus test boots 6 → 4.
  - Orchestrator 2c47222f: Semgrep rule `hoops-tenant-setting-rebound-by-hand` and the six call sites accepted again
    after WP128's `SessionSettingsRepository`; core's model page regenerated.
  - WP132 (8a76ebb9) pdf-service: test helpers, one test binary, token leeway 0 s and the common Problem slugs
    (ADR-0064).
  - WP133 (ee44cd18) CI: concurrency groups, each gate once, six composite actions, a `scripts` job, pin tests,
    `gen-api.sh` reads the generator version (ADR-0065).
  - WP131 (896b56d6) finance: test support once, one Postgres per `just test-go`, `applied_event` retention, the
    contract guard strict, leeway 0 s (ADR-0063).
  - WP130 (7937a127) the roster replica pipeline once in common-quarkus (ADR-0062, ADR-0037 amendment; game V10).
  - WP135 (65120abb) web: one home for dates, validators, error words, block states and server exports (ADR-0067).
  - WP136 (87e5fd68) chart 0.14.0: library chart `hoops-lib`, one pins file `deploy/lib/platform.sh` for kind and the
    cloud, delta snapshots (ADR-0068).
  - WP134 (5a5f6745) the membership rule once in common-quarkus, under PIT once (ADR-0066, ADR-0053 amendment).
  - WP138 parts 1 (699be74a) and 2 (5c0049c2) web: tests on the seeded demo mock (ADR-0070).
  - WP137 (ffe907ee, 7197ffa8) common plumbing, shared properties, poms, test support, one copy of the vectors;
    `finance.yaml` 1.1.0 (ADR-0069, ADR-0053 and ADR-0014 amendments).
  - WP138 part 3 (6d126f83); orchestrator bf586552 (the chart test reads the OTel build keys from common-quarkus,
    where WP137 put them); WP138 part 4 (b0f374b3).
  - WP139 (bb12d2e0) chart 0.15.0: one name for the realm URL and one for the admin base (ADR-0071), one PKCE login
    helper for the scripts, database roles from one list (ADR-0006, ADR-0055 amendments); kind proof of 0.14.0 /
    0.15.0. Orchestrator b8443244: `e2e/bin/services-up.sh` builds in its own compose call; then `just e2e` on compose:
    38 tests green.
  - WP138 part 5 (e0cf6902, 17d3dbb1): the last fakes go; no repository fake is left in the web tests.
  Contract versions now (read from the files): **core 3.7.0, game 2.4.0, athlete 3.0.0, common 1.1.1, pdf 1.0.0,
  finance 1.1.0** (`pdf.yaml` lost an unused schema without a version change); event schemas unchanged. Dart packages:
  core 3.7.0, game 2.4.0, athlete 3.0.0, `hoops_finance_api` 1.1.0. Helm chart **0.15.0** (library chart `hoops-lib`
  0.1.0; sub-charts unchanged: `databases` 0.1.0, `keycloak` 0.6.0, `hoops-service` 0.9.0, `web` 0.2.0, `pdf-service`
  0.2.0, `finance-service` 0.2.0). New ADRs 0059–0071 (0058 reserved and unused); amended ADR-0006, ADR-0014,
  ADR-0030, ADR-0031, ADR-0037, ADR-0040, ADR-0053 (twice), ADR-0055, ADR-0070 (twice).
- Tests, as the last handovers report them (none re-run by WP140):
  - **Java**: WP139's fresh `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (2026-11-24): contracts 346,
    common-quarkus 580, core 1,262, game 528, athlete 1,026, e2e 38 (32 skipped) — **3,780** as the sum of those
    counts; 0 failures; coverage, SpotBugs, PMD / CPD gates met. The round started at 3,556 (WP123).
  - **Rust**: **105 tests**, 95.72 % lines / 99.80 % domain, `cargo deny` ok (WP132; the same in WP137).
  - **Go**: `just test-go` green with 88.66 % / 98.84 % domain and govulncheck clean (WP137, WP139); the last count is
    WP131's **167 top-level tests** (158 before).
  - **Flutter**: `flutter test` **1,954 passed** (WP138 part 5; 1,801 at the start of the round, 1,861 after WP129,
    1,921 after WP135, 1,953 after WP138 part 4). Every widget and provider test runs on the seeded demo mock.
  - **Mutation** (WP137, the last run): common 486/487, core 920/921, game 505/507, athlete 620/620; web unchanged
    (every manifest file at 100 %, 2026-11-15). `docs/quality/mutation.md` has the history of the round.
  - **Gates and scripts**: `just isolation-check` 6 Java + 4 Go tests and `just db-role-check` 13 Java + 2 Go, run by
    hand in each worktree (every handover of the round); Python tests of `scripts/tests` 108 OK, 1 skipped, shell tests
    tenancy-gate 55/55, doctor drop-in 5/5, env-jdk 3/3, `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED with
    kubeconform 397/397 (WP139).
  - **e2e on compose**: the orchestrator's `just e2e` after the WP139 merge, 38 tests green (b8443244); CI `e2e` on
    17d3dbb1: 38 tests, 0 failures, 0 skipped.
- **Kind this round**: WP136's proof on chart 0.14.0 did not reach a Ready stack (VM load about 30; API-server TLS
  time-outs; the bash 3.2 bug of `up.sh` it found was fixed). WP139 proved 0.14.0 and 0.15.0 together:
  `up.sh --deploy --from-host`, the first `helm --wait` failed on Keycloak's progress deadline at load 31, the same
  `helm upgrade --install` passed once Keycloak was Ready; `seed-users.sh`, then `smoke.sh core game athlete` **57
  checks** (logins through the new PKCE helper, events into both replicas, finance isolation and `finance_app`,
  pdf-service). Cluster deleted. **Not proven on kind**: `tilt ci` (last on 0.9.0), the e2e journey, ESO and Reloader
  with the finance Secrets. Nothing in the cloud (decision 88).
- **Local stack**: the owner's compose stack runs the merged round (the orchestrator's `just e2e` after the WP139
  merge). Its database was not rebuilt, so the role bootstrap from the one list ran there only through `db-roles.sh`
  (`just finance-up`), and its Keycloak volume predates the current realm file (the INF-07 retrofit in
  `infra/keycloak/seed-users.sh` stays until it is rebuilt). The compose database still holds junk tenants and admins
  from the ZAP scans.
- **Security**: F-01..F-24 and P-01..P-13 unchanged. New acceptances without an expiry: Semgrep's
  `hoops-tenant-setting-rebound-by-hand` on six call sites in core (2c47222f) and one `PagedQuery` acceptance in
  common instead of three (WP137). Seen once and not accepted: ZAP 40018 on core's `audit-events:export` (e2e
  45235457191; FOLLOW-UPS "Security").
- CI on `main` (observed with `gh run list -b main` on 2026-11-24 by WP140): on **17d3dbb1** `ci` 45330282441, `e2e`
  45330282648 (38 tests, 0 skipped; the ZAP API scans of core, game, athlete and finance through their gates),
  `codeql` 45330282845, `semgrep` 45330282755, `images` 45330282631 and `pages` 45330283134 all **green**; on
  **b8443244** `ci` 45329697215, `e2e` 45329697578, `codeql` 45329697262, `semgrep` 45329697245, `images` 45329697306,
  `pages` 45329697209 all green; on f856d929 (the orchestrator's observation) `ci` 45318729233, `e2e` 45318729015,
  `semgrep` 45318729086, `codeql` 45318729135, `images` 45318729040, `pages` 45318729128 green. Reds of the round,
  each followed by a fix or a green next run: `semgrep` on 4317662a, 745f40f7, 498519fb and `model-diagrams` on
  745f40f7, 498519fb (2c47222f); `ci` `backend` on 7f2a75a7 (the Monday-dependent athlete test, WP127); `ci`
  `helm-chart-tests` on 2195fa03 and 21af40a0 (bf586552); Maven Central download failures in `e2e` on 35e685d8, `ci`
  `backend` on 498519fb, `images` athlete on beaaffaf, `ci` `trivy-fs` on 393b5676 and 2195fa03, `ci` `zap-baseline`
  on fe792e33; the `e2e` ZAP step on 2c47222f (core 40018 on the audit export), 312cf764 and 0c1ac2ae (one scan's
  ZAP daemon could not bind its proxy port, "Address already in use"). Run ids in FOLLOW-UPS "Infra, CI, e2e".
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0), branch `main`. Open: Dependabot PR #22 (pub); the stale `bump-pins` PR #21 was closed on
  2026-11-24. PR #6 was merged on 2026-11-22,
  the eighth round's Dependabot PRs are merged or closed. Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secrets `NVD_API_KEY` (repository and Dependabot). Images per
  commit on ghcr.io with their SBOMs as OCI referrers. Dependabot: weekly grouped updates (Maven, pub, GitHub Actions
  as SHA + tag including `.github/actions/*` since WP133, `cargo`, `gomod`) with a 7-day cooldown; the
  `json-schema-validator` major is ignored (WP43).
- The eighth round's state (pdf-service, finance-service, its kind proofs and CI) is in FOLLOW-UPS "Resolved",
  "Eighth round", and in the WP111–WP125 handovers.

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

## 2026-11-22/23: dependency merges before the ninth round
- Merged: the `bump-pins` PR #6 (container and kind pins) and Dependabot PRs #11, #14–#18 (pdf `base64`, `skrifa`
  0.50.0, finance `golang.org/x/text`, Maven, Actions, pub); #19 made `main` green after them; #20 ignores Python
  bytecode caches. pdf-service: `jiff` replaces the unmaintained `chrono` / `chrono-tz` (2d9c08d7, ADR-0052
  amendment), which ended the `rust` job's `cargo deny` red; `url` 2.5.9 (RUSTSEC-2026-0592). Also nginx 1.30.7 in the
  web image, sqlite3.wasm and the drift worker of sqlite3 3.9.1, and a pin bump now moves every copy of a pin
  (f5d431d4).

## Pending user actions
1. **First real `tofu apply`** (still the first candidate; WP104 handover, `docs/runbooks/cloud.md` "Before the
   first apply"). The owner prepares: an Alibaba Cloud international account with a payment method; a RAM user
   `hoops-tofu` with programmatic access only and the runbook's regional ECS/VPC policy; its key in `.env`
   (`ALIBABA_CLOUD_ACCESS_KEY_ID` / `_SECRET`) or an aliyun profile; `TF_VAR_state_passphrase` (16+ characters, backed
   up); `terraform.tfvars` with their IP as /32 and their public key; a `main` commit whose images are on ghcr.io; strong
   fresh values everywhere in `.env` (`install.sh` refuses `change-me`), including the finance keys.
2. **Season rollover wizard** (owner decision; WP138 part 2): the web wizard sends the season it was opened on as both
   the target (path) and `fromSeasonId`; core refuses that (`ROLLOVER_SAME_SEASON`), so the wizard works only against
   the demo mock. Not checked on the real stack. A fix makes the wizard offer a target season.
3. **Audit files**: deleted on 2026-11-24 with the owner's agreement (decision 111). Nothing in the repository
   linked to them.
4. **IDR minor digits** (owner decision, WP121 / WP124): finance stores IDR with 2 minor digits (ISO 4217) and the web
   shows whole amounts without decimals. Change the service's currency table and the web's copy together if 0 is
   wanted, before the first real IDR due.
5. **Real-browser checks nobody ran** (FOLLOW-UPS "Pending user actions"): the two PDF buttons and the whole Finance
   area against the real services, the super admin's landing on the application admin hub, a calendar `.ics` in a
   calendar app, the server-side CSVs downloaded from the web, the avatar menu and the chooser's cards. The compose
   nginx does not serve the web app: start it locally (`./start.sh` or `flutter run`, README) and sign in, e.g. as
   `testcoach1@hoops-academy.com` with `TEST_ACADEMY_PASSWORD`.
6. **Other stacks and `.env` files**: any `.env` other than the main checkout's renames the two retired Keycloak
   variables of ADR-0071 to `KEYCLOAK_ADMIN_URL` or deletes them (the compose defaults fit) and has
   `FINANCE_MIGRATOR_PASSWORD` / `FINANCE_APP_PASSWORD`, which `just up` now requires; a private `values-local.yaml`
   that sets a retired name or calls `hoops-service.*` helpers follows (ADR-0071, `hoops-lib.*`). Any other stack after
   the eighth round still needs `just finance-up`, `just events-backfill force` and `just seed-academy`.
7. **PR #21 (bump-pins)**: closed on 2026-11-24 as stale; `scripts/bump-pins.sh --check` on `main` finds the same
   bumps in `deploy/lib/platform.sh`, so the next weekly run opens a fresh PR (close and reopen a `GITHUB_TOKEN`
   PR so `ci` / `e2e` start). Review Dependabot PR #22. Next candidate from the owner: PostgreSQL 17 to 19
   (FOLLOW-UPS "Infra, CI, e2e").
8. **Workflow-file pins by hand**: Trivy 0.76.2, Semgrep 1.186.0 and the ZAP digest (listed in PR #21) with
   `scripts/bump-pins.sh --apply`, then `actionlint`. Optional: a fine-grained PAT (contents + pull requests +
   workflows) so the weekly PR includes them and starts its own checks.
9. **File the Envoy Gateway issue** from `docs/upstream/envoy-gateway-global-ratelimit-descriptor-collision.md`
   (decision 49; WP100 re-tested on v1.10.0: still collides, add that to the draft); drop the `path: /` selector once
   fixed upstream.
10. **Podman machine, in a quiet window (optional)**: `just doctor`'s real write-and-restart path for the drop-in ran
    only against stubs, and `podman machine init --playbook infra/podman/machine-playbook.yml` was never run (WP93).
11. **Local chromedriver** is 156, CI pins Chrome for Testing + chromedriver 157.0.8103.38; update the local one when
    the local Chrome moves.
12. Review the Dependabot and `bump-pins` PRs as they arrive (weekly, Monday).

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
  Agents of the eighth and ninth rounds ran `just isolation-check` / `just db-role-check` by hand in their worktrees
  (open item in FOLLOW-UPS). A `git commit` run inside a helper script is not seen by the hook at all (WP128): commit
  one at a time with a plain `git commit` in the Bash call.
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
  load 13–66 (WP120 at 40). At load about 30 kind's API server timed out TLS handshakes (WP136) and Keycloak's first
  start (about 150 s of re-augmentation) missed its Deployment's progress deadline, so `up.sh --deploy` failed its
  `helm --wait` once; the same `helm upgrade --install` passed once Keycloak was Ready (WP139). The LGTM pod needs about 1.2 GiB: kind with it fits only with compose stopped.
- **Podman API idle timeout**: the `--time=0` drop-in (WP87) is on the VM; `just doctor` checks it and rewrites it when
  missing (WP93), `infra/podman/machine-playbook.yml` restores it after a re-init.
- **`podman compose` on this Mac delegates to Docker.app's `docker-compose` v2.15.1** (`podman compose version`), not
  to `podman-compose`. It refuses `up --no-deps --build` ("no such service: keycloak"), so `e2e/bin/services-up.sh`
  builds in its own call since b8443244. `compose.yaml` fixes the project name, container names and ports, so no
  second compose stack can run beside the owner's (WP139).
- **Realm and admin URLs** (ADR-0071): the realm is `OIDC_AUTH_SERVER_URL` (default
  `http://localhost:8080/auth/realms/academy`, set once in common-quarkus for the Quarkus services), the Admin API base
  `KEYCLOAK_ADMIN_URL` (default `http://localhost:8080/auth`; core and the e2e suite). The retired names and the old
  port listed in ADR-0071 are gone: `scripts/tests/test_realm_variables.py` fails on them in any tracked file outside
  `docs/adr` and `docs/wp` (so write them only there).
  `just up` requires `FINANCE_MIGRATOR_PASSWORD` and `FINANCE_APP_PASSWORD`. The owner's `.env` was checked at the
  WP139 merge and needed no change.
- **Database roles from one list** (ADR-0006 amendment): the rows between `-- roles: begin` / `-- roles: end` of
  `infra/db/init/01_roles_schemas.sql`; `02_passwords.sh` requires `<ROLE>_PASSWORD` for every role, and
  `infra/compose/db-roles.sh` (run by `just finance-up` and `services-up.sh`, was `finance-db.sh`) re-applies roles and
  every password from `.env` on an existing volume.
- **Shared settings live in common-quarkus** (ADR-0069): its `META-INF/microprofile-config.properties` holds the
  keys all three Quarkus services share (OTel build keys, realm URL, broker defaults, …). Checks outside a service's
  build read them there: the chart test under `deploy/helm/tests` reads the OTel build keys from that file
  (bf586552, after WP137 moved them). When a change moves build properties, run `deploy/helm/tests/run.sh` too.
- **Transient Maven Central failures in CI**: on 2026-11-23/24 downloads from Maven Central failed in `ci`
  (`trivy-fs`, `zap-baseline`, `backend`), `images` and `e2e`; each passed on the next push. Read the failed step
  before suspecting the change; once `trivy-fs` resolved `dependency:` to the wrong plugin after such a failure.
- **Roster replicas are the default**: a service started without a broker in prod or dev mode needs
  `GAME_ROSTER_SOURCE=rest` / `ATHLETE_ROSTER_SOURCE=rest` (the test profile pins `rest`); since WP117 game, like
  athlete, refuses `replica` with its consumer off. Since WP130 both run common's pipeline with one policy
  (`hoops.roster.replica.max-attempts` 5, `GAME_ROSTER_REPLICA_MAX_ATTEMPTS` replaced game's `apply-attempts`). After seeding or a manual change, `just events-drift` checks core
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
  worktree's `git status` and log before trusting its last report. An agent whose context runs out hands back at a
  green commit and a fresh agent continues in the same worktree (WP138 ran in five parts).
- **Fresh Helm install with events on**: core's producer is created at the first send and recovers by itself;
  `smoke.sh` checks the producer login after the seed.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH.
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/*.conf` with `[alert=..][url=..][expires=..]` scoping (one
  file per scanned API, `api-finance.conf` since WP123). The Actions token cannot push workflow files. The `ci` job
  `dependency-check` can fail on NVD API errors: re-run it. Since WP133 a pull request run is cancelled by a newer
  push, never a run on `main`; tool versions live in the composite actions under `.github/actions` (setup-java,
  setup-flutter, setup-pinned-chrome, setup-go, setup-chart-tools, image-publish); `scripts/tests` runs in the `ci` job
  `scripts`, but not `env-jdk.test.sh` and `tenancy-gate.test.sh`, which fail on Linux and run only in
  `just test-hooks` on macOS.
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
  (Pending 1): plan, apply, kubeconfig, `install.sh`, seed and smoke through `with-cloud.sh`, destroy, each step of
  `docs/runbooks/cloud.md` marked NOT YET RUN today; then narrow the RAM policy.
- **The rollover wizard** once the owner decides (Pending 2): offer a target season, then a check against the real
  stack.
- **The rounds on a real stack**: `just up` on a fresh `hoops_pgdata` volume (the one role list has not run there), the
  owner's browser walk-through (Pending 5), the Keycloak volume rebuilt from the current realm file so the INF-07
  retrofit can go; then the journey on kind, `tilt ci` on 0.15.0, ESO and Reloader with the finance Secrets, and a
  longer Keycloak start allowance on kind (`startupProbe` or `progressDeadlineSeconds`).
- **Privacy gate before real academies** (P-01..P-05): an ADR for erasure as pseudonymisation and a per-person export
  across the four data services; the purge job with written periods (finance included); a core job deleting old
  published outbox rows; an audit trail for health writes; a privacy notice in es / en / id and a DPIA note.
- **Observability depth**: database spans, request metrics for pdf and finance, Keycloak / Envoy / Redpanda logs to the
  collector, alerting on `hoops_authz_denied_total`.
- **Tooling and CI**: mutation testing for Rust (`cargo-mutants`) and Go (`gremlins`), a finance replica lag metric,
  the commit hook following the commit's worktree, the shell tests that fail on Linux made portable (then into the
  `scripts` job), full plugin coordinates for `dependency:go-offline` in `ci.yml`, compose on Mailpit like kind.
- **Leftovers of the audit round** (FOLLOW-UPS "Ninth-round findings left on purpose", "Web helpers left as they are",
  "CI findings left", "Infra findings left"): each with its reason; none blocks anything.
- **Recapture the landing screenshots** (owner's wish; also the PDF icons and the Finance area).
- **Users area depth**: e-mail change and a temporary password from the application admin's Users list.
- **Billing** module on the existing seams (`billing.*`, `EntitlementService`, the published outbox events; the hub's
  placeholder); stays in core, in Java (ADR-0051).
- Smaller: the finance and PDF leftovers (FOLLOW-UPS "Product / contract decisions"), the language and theme on the
  profile screen, the breached-password check (decision 60), an optimised Keycloak image (decision 63), the kit wishes
  of WP92, the remaining 155 fitness-norm placeholders (`docs/domain/norms.md`).
