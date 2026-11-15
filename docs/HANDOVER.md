# Session handover (updated 2026-11-14 — seventh round WP104–WP109 done, `images` red on `main`)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05, the four rounds of 2026-11-06/07, the sixth round
of 2026-11-10 and the seventh of 2026-11-14, the product owner's decisions 1–85 and the backlog are in
`docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder (`.../Code/Claude/projects/dummy-project2`) is archived
and must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20), WP21–WP25, the twelve WPs of 2026-11-05 (WP26–WP37), the
  rounds of 2026-11-06/07 (WP38–WP90, no WP79), the sixth round of 2026-11-10 (WP91–WP103; details in FOLLOW-UPS
  "Resolved") and the seventh round of 2026-11-14 (WP104–WP109).
  Before the round, on `main`: Quarkus platform 3.40.1.1 → 3.40.1.2 (c8ae9580; full verify green, 3,379 tests; the
  guava pin stays, the BOM still manages 33.6.0-jre); Flutter 3.47.9 → 3.50.0 / Dart 3.14 with the migration from
  `package:flutter/material.dart` to the `material_ui` and `cupertino_ui` packages (51f2dd0c, 189 Dart files); section
  10 "Domain model" in `docs/architecture.md` (28a02264); the service image on a newer `ubi9/openjdk-21-runtime:1.24`
  digest with `microdnf -y update` in the runtime stage (de481062; `images` stays red, see CI below).
  Merged into `main` on 2026-11-14 in this order (handover or last commit of each):
  - WP105 (3b2b6f27) light / dark / system theme (default system, remembered in the browser); language and theme in the
    menu behind the avatar on every shell screen, removed from the profile; a theme button in the landing header.
  - WP107 (c8b5e559) demo phase of `just seed-academy`: a second team, an assistant coach, schedules, past sessions
    with attendance, plans, an assignment, an absence, three matches (finished, live, scheduled), injuries,
    measurements and tests, looking like the landing screenshots (`SEED_ACADEMY_DEMO=0` skips it,
    `SEED_ACADEMY_DEMO_ONLY=1` runs only it; runbook `local-stack.md` "Demo data in the Test Academy").
  - WP104 (771a18aa) OpenTofu module `infra/tofu` for one k3s VM on Alibaba Cloud, Jakarta; `values-cloud.yaml` and
    `deploy/cloud/*` to install the chart on it; `just tofu-check` and the CI job `tofu-check`; runbook `cloud.md`;
    ADR-0050. **Code only: nothing applied**, no account or key used.
  - WP106 (5ca19230) core 3.6.0: the roster export for ADMIN and the team's current coach only, a former coach gets 403
    (decision 83, ADR-0048 amendment); `givenName` / `familyName` per membership in `/me` (decision 84); core Dart
    package 3.6.0.
  - WP108 (b4a77568) web: the exercise catalogue for PARENT and PLAYER (`/training/exercises`, "Exercises" chip in
    Training), the "Your name" form from the `/me` names, the export button only for ADMIN and the current coach.
  - WP109 (handover 0027acdf on `main`) JDK 25 on the branch `jdk-25` (83024d44, 36e2abbf, 77fe32fe after its rebase
    on f59c7f85), draft pull request #7, **not merged** (decision 81).
  Contract versions now: **core 3.6.0, game 2.3.0, athlete 3.0.0, common 1.1.1**; event schemas unchanged. Helm chart
  **0.10.0** unchanged (`keycloak` 0.6.0, `hoops-service` 0.8.0, `databases` 0.1.0, `web` 0.2.0; WP104 adds the overlay
  `values-cloud.yaml`, no template change). New ADR-0050; ADR-0048 amended (the ADR-0003 amendment is on `jdk-25` only).
- Tests, as the handovers report them: `./mvnw -B -ntp -T 1C verify` at WP106 **3,388 tests**, 0 failures, 0 errors,
  26 skipped (the journey steps without `e2e.baseUrl`), coverage gates met; the same 3,388 on JDK 25 on `jdk-25`
  (WP109). `flutter test` **1466 passed** (WP108, the last web WP; WP105: 1454). Mutation: core 925/926 (WP106); on JDK
  25 every module at its baseline (common 337/338, core 925/926, game 525/527, athlete 690/690; WP109); Dart tool
  430/430 unchanged. `just tofu-check`: 25 `tofu test` runs passed against a mocked provider, trivy config 0 findings,
  checkov 8 passed (WP104). Chart tests ALL CHART TESTS PASSED with the new `umbrella-cloud` snapshot, kubeconform
  350/350 (WP104). No kind proof this round (nobody used kind); `tilt ci` last ran on chart 0.9.0.
- Test academy: WP107 seeded the demo data into the compose database (services from its worktree; repeated runs
  "nothing to create"; `just events-drift` equal). The owner's own rows in the academy were left untouched.
- Security: unchanged (F-01..F-24: 22 fixed, F-11 and F-22 accepted by design; SD-03 accepted until 2027-05-07). The
  `images` Trivy gate fails on 14 HIGH `krb5-libs` findings in the base image (Pending 1).
- CI on `main` (`gh run list -b main`, 2026-11-14): on the last push f59c7f85 `ci` 43616396634, `e2e` 43616396516,
  `codeql` 43616396630 and `semgrep` 43616396569 green (no `images` run: docs only). On 3822faf2 (WP108
  merge): `ci` 43614386604, `e2e` 43614386742, `codeql` 43614386642, `semgrep` 43614386530 green, `images` 43614386564
  **red** (Trivy: 14 HIGH, all `krb5-libs`). Every `images` run of the round is red: d20faf34 (43602719552, 31
  findings before de481062), de481062 (43606468296), a499cad0 (43609166140), 061a6af7 (43612355787), 3822faf2; last
  green b56bab8e (42789825341). Every `ci` run of the round is green, from d20faf34 to f59c7f85.
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0), branch `main`; open pull requests #6 (bump-pins) and #7
  (`jdk-25`, draft). Repository variable `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secrets `NVD_API_KEY`
  (repository and Dependabot). The four ghcr.io packages are public and carry their SBOMs as OCI referrers. Dependabot:
  weekly grouped updates (Maven, pub, GitHub Actions as SHA + tag) with a 7-day cooldown; the `json-schema-validator`
  major is ignored (WP43). The weekly `bump-pins` PR covers image digests, chart tags and kind pins, but not pins inside
  workflow files (listed in the PR body for a manual bump).

## Pending user actions
1. **`images` is red on `main`**: 14 HIGH findings, all `krb5-libs` in `ubi9/openjdk-21-runtime` (the fixed package is
   not in the UBI repositories yet; the runtime stage already runs `microdnf -y update`). Wait for Red Hat and re-run
   `images`, or accept the findings with an expiry (ADR-0045). The JDK 25 image has the same 14. Not decided yet.
2. **First real `tofu apply`** (next round's first candidate; WP104 handover, `docs/runbooks/cloud.md` "Before the
   first apply"). The owner prepares: an Alibaba Cloud international account with a payment method; a RAM user
   `hoops-tofu` with programmatic access only and the runbook's regional ECS/VPC policy; its key in `.env`
   (`ALIBABA_CLOUD_ACCESS_KEY_ID` / `_SECRET`) or an aliyun profile; `TF_VAR_state_passphrase` (16+ characters, backed
   up); `terraform.tfvars` with their IP as /32 and their public key; a `main` commit whose images are on ghcr.io; strong
   fresh values everywhere in `.env` (`install.sh` refuses `change-me`).
3. **JDK 25, pull request #7** (draft, branch `jdk-25`): before merging, look at its CI (e2e, CodeQL and `images` were
   not run locally; `images` will be red for item 1), install `openjdk@25` on every machine and in every worktree
   (`scripts/bootstrap.sh`; env.sh then refuses a 21; branches cut before the merge keep selecting 21), and expect
   rebase conflicts in the runtime image line of `service.Containerfile` and its `bump_pins.py` pin, the
   `actions/setup-java` steps and the stack wording lines (WP109 handover).
4. **bump-pins PR #6** (mailpit v1.33.1, External Secrets Operator v2.15.0): close and reopen it so `ci` / `e2e`
   start (a `GITHUB_TOKEN` PR starts no checks); the ESO bump needs a kind proof (`up.sh --eso --deploy --from-host`,
   ExternalSecrets synced) before merging.
5. **Workflow-file pins by hand**: Trivy, Semgrep and the ZAP digest with `scripts/bump-pins.sh --apply`, then
   `actionlint`. Optional: a fine-grained PAT (contents + pull requests + workflows) so the weekly PR includes them and
   starts its own checks.
6. **Real-browser checks nobody ran**: sign in as `superadmin@hoops-academy.com` (a pure super admin; it should land on
   the application admin hub); the hub and the context switcher against the real stack; a calendar `.ics` imported
   into a calendar app; the server-side roster export downloaded from the web; the avatar menu (language, theme) and
   the families' catalogue (WP105, WP108: widget tests and goldens only); the WP107 demo data next to the landing
   screenshots. The compose nginx does not serve the web app: start it locally (`./start.sh` or `flutter run`,
   README) and sign in, e.g. as `testcoach1@hoops-academy.com` with `TEST_ACADEMY_PASSWORD`.
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
- **`git commit --no-verify` is refused in agent sessions** (seventh round, every agent): the session's permission
  check blocks it, although `wp-round` Mechanics 3 and the brief template still ask for it. Agents committed with a
  plain `git commit` and explicit paths after `gitleaks protect --staged`; the repository's pre-commit hooks then run,
  and their whitespace fixers can trim generated Dart files (WP106: discard those whitespace diffs at the next
  regeneration).
- **Flutter 3.50.0 / Dart 3.14** on this Mac: widgets come from the `material_ui` and `cupertino_ui` packages, not
  `package:flutter/material.dart` (deprecated in 3.50; 51f2dd0c). The repository does not pin Flutter and CI follows
  the stable channel, so a new stable can turn `flutter analyze` red without a commit of ours.
- **OpenTofu and JDK 25 installed with Homebrew** (`opentofu` 1.13.9, `openjdk@25` 25.0.5): `just tofu-check` needs
  OpenTofu; `scripts/bootstrap.sh` installs it, and a `tofu-fmt` pre-commit hook runs on
  `infra/tofu`. `openjdk@25` serves the `jdk-25` branch; `scripts/env.sh` on `main` still selects 21.
- **Wait for `ci` before stacking the next web merge**: the browser smoke (`web-browser`) runs only in `ci`; in the
  sixth round the WP97 merge broke it and four later pushes stayed red until 1ae09ed2.
- **Pass known gate rules to agents in their prompts**: constant SQL / JPQL with bound parameters (CodeQL
  `java/concatenated-sql-query`), the tenant-switch rule of Semgrep (a nil-tenant bind needs a dated acceptance), no
  environment-derived program names in scripts and tests (Semgrep taint).
- Claude Code hook (`.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude runs
  `git commit` it runs `just isolation-check` (~40 s); before `git push`, `just db-role-check`. Since WP93 it parses
  the command and gates only a real `git commit` / `git push` (wrappers, `git -C`, global options and line
  continuations included); by choice an unquoted `echo git commit` and a heredoc with unbalanced quotes still gate.
  It prints `tenancy-gate: isolation-check PASSED in N s` on stderr. `--no-verify` does not skip it; commits made in a
  terminal are not gated. `just test-hooks` runs its case table.
- **Load on the 2-CPU, 8 GB Podman VM.** Four parallel builds held in the sixth round, but once they OOM-killed Keycloak,
  Redpanda and MailHog (exit 137; `just up` restarts them, volumes untouched); the commit hook's isolation check then
  times out or fails, and a retry passes. On kind at load 13–66 liveness probes restarted services and the Gateway
  showed `Programmed=False` once. `ratelimit-check.sh` ends `RATE LIMIT CHECK INCOMPLETE` (exit 3) through the load
  guard (`HOOPS_LOAD_WAIT=<s>` waits). Retry once the load drops; never bypass the hook. Stop compose while proving on
  kind.
- **Podman API idle timeout**: the `--time=0` drop-in (WP87) is on the VM; `just doctor` checks it and rewrites it when
  missing (WP93), `infra/podman/machine-playbook.yml` restores it after a re-init. "localhost:2375 failed to respond"
  without it: `ContainerStarts` contains it in the test-jar resources and core (WP91).
- **Roster replicas are the default**: a service started without a broker in prod or dev mode needs
  `GAME_ROSTER_SOURCE=rest` / `ATHLETE_ROSTER_SOURCE=rest` (the test profile pins `rest`). After seeding or a manual
  change, `just events-drift` checks core against both replicas (`--kind` on the cluster); a replica lags 1–2 s.
- **Model diagrams**: after a Flyway migration or a `domain` / `application` type change run `just diagrams` and commit
  the pages; `just diagrams-check` (CI job `model-diagrams`) fails otherwise. Never edit between the generated markers.
- **Test academy**: `just seed-academy` (needs `just up`, `just seed-users`, `just services-up` and
  `TEST_ACADEMY_PASSWORD` in `.env`) is idempotent; it retries on the nginx `auth` limit; a withdrawn academy keeps its
  slug and its Keycloak logins, so a re-seed after a withdraw needs another slug.
  Since WP107 the same run adds the demo data (`SEED_ACADEMY_DEMO=0` skips it, `SEED_ACADEMY_DEMO_ONLY=1` runs only
  it); a full run takes 1.5–4 minutes.
- **Rate-limit pauses** (agent sessions): an agent may pause and resume in the same worktree; check the worktree's
  `git status` and log before trusting its last report.
- **Fresh Helm install with events on**: core's producer is created at the first send and recovers by itself; since
  WP100 `deploy/kind/up.sh` no longer restarts core and `smoke.sh` checks the producer login after the seed.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH.
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/baseline.conf` with `[alert=..][url=..]` scoping. The
  Actions token cannot push workflow files (bump-pins `--skip-workflows`).
- `.env` needs `RATELIMIT_REDIS_PASSWORD` and the `REDPANDA_*_PASSWORD` keys, otherwise `deploy/kind/secrets.sh` and
  `eso-store.sh` stop; the SMTP keys are optional locally (an `SMTP_PASSWORD` makes `secrets.sh` write `hoops-smtp`).
- Time-dependent tests: CI runs at any hour; derive dates from the test's "now", never a fixed weekday and local time.
- Realm changes need a Keycloak re-import (`just down && podman volume rm hoops_pgdata && just up && just seed-users`)
  or, for the settings it knows, `just seed-users` alone.
- Parallel worktrees share the compose database: a service started from a branch that lacks a migration another
  worktree already applied needs `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future,*:missing'` until both are merged.
- **Podman VM clock drift** after the host sleeps: the hook scripts (`scripts/hooks/_common.sh`) step the VM clock
  before each check; by hand: `podman machine ssh "sudo date -u -s @$(date +%s)"`.

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- **First candidate: the real `tofu apply` on Alibaba Cloud** once the owner has prepared the account and key
  (Pending 2): plan, apply, kubeconfig, `install.sh`, seed and smoke through `with-cloud.sh`, destroy, each step of
  `docs/runbooks/cloud.md` marked NOT YET RUN today; then check what WP104 could not (FOLLOW-UPS.md "Cloud slice:
  unproven until the first apply") and narrow the RAM policy. Later slices: TLS certificates, real SMTP, CNPG backups
  to object storage, External Secrets against a real store.
- **Observability backend** (owner's wish, not done this round): one Grafana pod with traces, logs and metrics instead
  of the in-memory Jaeger on kind (ADR-0046 leaves the backend to the environment).
- **Recapture the landing screenshots** (owner's wish, not done this round): `assets/landing/*` predate the sixth
  round's shell and the avatar menu (`flutter test test/golden/landing_screens_capture.dart`); the WP107 demo data can
  now be compared with them on a real backend.
- **JDK 25**: merge pull request #7 when the owner says so (Pending 3).
- Small: the avatar menu (language, theme) on the academy chooser (WP105); the seeded live match and measurement dates
  that keep the first run's values (WP107); `docs/domain/audit-events.md` wording for the roster export (WP106).
- **Users area depth**: e-mail change and a temporary password from the application admin's Users list.
- **Export follow-ups**: a team name for the audit `team` target (core), PDF where a printable sheet helps (decision
  67: later), compose nginx `limit_req` for the export paths and the public academy request.
- **Events leftovers**: game's start guard for `replica` without its consumer (athlete has one); `tilt ci` on chart
  0.10.0; Redpanda outside kind.
- **Billing** module on the existing seams (`billing.*`, `EntitlementService`, the published outbox events; the hub's
  placeholder) and the **purge job** for withdrawn tenants, old audit rows and decided academy requests.
- **Breached-password check** (ASVS 6.2.12; not now by decision 60) and an **optimised Keycloak image** (read-only
  root FS, KSV-0014; not now by decision 63).
- Smaller: the kit wishes of WP92 and training's own pickers / `fabClearance`, the demo mock's catalogue and template
  texts, the remaining 155 fitness-norm placeholders (`docs/domain/norms.md`).
