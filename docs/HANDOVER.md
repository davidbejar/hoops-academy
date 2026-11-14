# Session handover (updated 2026-11-10 — sixth round WP91–WP103 merged, `main` green)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05, the four rounds of 2026-11-06/07 and the sixth round
of 2026-11-10, the product owner's decisions 1–74 and the backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive
planning folder (`.../Code/Claude/projects/dummy-project2`) is archived and must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20), WP21–WP25, the twelve WPs of 2026-11-05 (WP26–WP37), the
  rounds of 2026-11-06/07 (WP38–WP90, no WP79; details in FOLLOW-UPS "Resolved") and the thirteen of the sixth round
  (WP91–WP103), merged into `main` on 2026-11-10 in this order (handover or last commit of each):
  - WP93 (b6e01945) tooling: bump-pins pins the skopeo multi-arch index, the tenancy-gate hook parses real
    `git commit` / `git push` (`just test-hooks`), Podman machine playbook and a self-healing `just doctor` step.
  - WP95 (805e4cec) web leftovers: kit follow-ups (ADR-0040 amendment), Indonesian bottom bar "Laga", audit labels,
    only the English landing screenshots precached.
  - WP92 (f78c6b20) exercise catalogue, athlete 3.0.0 (V10, ADR-0047) with its web part (catalogue tab, editor,
    quick-add in session, new-session dialog and plan editor).
  - WP91 (3ff97397) core 3.4.0 (V18): `GET /platform/users`, own name through `PATCH /me`, events-off switch
    `CORE_OUTBOX_ENABLED`, `ContainerStarts` in core (ADR-0029 amendment).
  - WP94 (fc3f7c71, regenerated db0aaff4) ER and class diagrams per service in `docs/domain/{core,game,athlete}-model.md`,
    `just diagrams` / `just diagrams-check`, CI job `model-diagrams`.
  - WP99 (d818e603) web contexts, application admin hub at `/app-admin`, Users screen, context switcher, own-name edit
    (ADR-0049).
  - WP97 (d7474168) web exports built in the browser: CSV, deferred Excel (`excel_community` 2.6.2, not precached),
    ICS team calendar.
  - WP96 (302be255) core 3.5.0 (V19): preferred jersey number with carry-over, taken numbers, CSV exports of the team
    roster and the audit trails (ADR-0048).
  - WP98 (b9ee126b) events flip: `replica` the default roster source of game and athlete, `just events-drift`, shared
    replica code in common-quarkus, e2e awaits (ADR-0037 amendment).
  - WP101 (b56bab8e) web jersey dialogs, preferred number and wish, roster and audit export buttons (core Dart package
    3.5.0).
  - WP100 (2274eb40) chart 0.10.0: replica with events, quiet core without events, core SMTP, export rate limits, Envoy
    Gateway v1.10.0, kind proofs (ADR-0031 and ADR-0033 amendments).
  - WP103 (bc611ff0) `just seed-academy`: "Test Academy" with 23 logins through the real API.
  Orchestrator fixes in between: the tenancy-gate hook hardened after review (ee5f64cc: wrappers such as `timeout` /
  `nice` / `env -u`, backslash continuation; 778ea6ab: no negative array index on bash 3.2), a Semgrep taint finding
  in the pins test (8a989aa8), the exercise search as constant JPQL with bound switch parameters (3435a31d, then
  744129f9 for CodeQL `java/concatenated-sql-query`), dated Semgrep acceptances for the platform users nil-tenant bind
  (744129f9) and the Excel on-demand check tool (6d07a4e4), the matches export button that pushed the first match under
  the bottom bar (1ae09ed2, WP97), and `bump-pins --skip-workflows` (f96389a3). Plan table closed by this docs pass.
  Contract versions now: **core 3.5.0, game 2.3.0, athlete 3.0.0, common 1.1.1**; event schemas in
  `libs/contracts/events` (unchanged this round). Helm chart **0.10.0** (`keycloak` 0.6.0, `hoops-service` 0.8.0,
  `databases` 0.1.0, `web` 0.2.0); Envoy Gateway **v1.10.0** with Gateway API v1.6.1. New ADRs 0047–0049; amendments to
  ADR-0029, 0031, 0033, 0037, 0040.
- Tests (last full verify of the round, WP98 after its rebase): common-quarkus 403, contracts 315, core 1163, game 467,
  athlete 999 = **3,347 JVM tests**, 0 failures, every coverage and SpotBugs gate met; `e2e` module 32 (6 `MailSinkTest`
  run, 26 journey steps skipped without `e2e.baseUrl`). `flutter test` on the combined tree at the WP101 merge: **1436
  passed** (WP101's own last run: 1435). Mutation (PIT): common 337/338, core 925/926, game 525/527, athlete 690/690;
  Dart tool 430/430 (WP88); baselines unchanged 99 / 99 / 99 / 100 and web 100 (`docs/quality/mutation.md` agrees).
  Chart tests 182 checks, kubeconform 278/278 (WP100). `just test-hooks`: matcher cases, doctor stubs, pins tests
  (WP93); `just events-drift-test` 49/49 (WP98).
- e2e: `JourneyTest` **26/26** on compose with the replica as the default roster source and no override (WP98); CI
  `e2e` on every push. kind (chart 0.10.0, WP100, fresh cluster): `up.sh --eso --deploy --from-host` without the core
  restart, 18/18 ExternalSecrets, `smoke.sh` 47 checks ("roster source: game replica, athlete replica"), events off
  with no Kafka lines in core, producer recovery after a deleted broker user, core's decision mail in Mailpit, export
  rate limits, a `RATELIMIT_REDIS_PASSWORD` rotation rolled by Reloader, `just events-drift --kind` equal. Not re-run on
  0.10.0: `tilt ci`.
- Events: **`replica` is the default** in game and athlete (services, compose, chart with events; decision 66, ADR-0037
  "Flip of 2026-11-10"); `rest` is the fallback (`GAME_ROSTER_SOURCE` / `ATHLETE_ROSTER_SOURCE=rest`, chart
  `<service>.rosterSource: rest`; runbook `events.md` "Rollback to rest"). `just events-drift [--kind]` compares core's
  rows with both replicas.
- Test academy: `just seed-academy` ran in the main checkout on 2026-11-10 (23 logins verified, `just events-drift`
  equal). `TEST_ACADEMY_PASSWORD` (generated) and `TEST_ACADEMY_USERS` are in the owner's git-ignored `.env`; runbook
  `local-stack.md` "Test academy". The three services were left running from `just services-up`.
- Security: SAST/DAST gate every push (ADR-0045); two dated Semgrep acceptances added this round (platform users
  nil-tenant bind, WP91; Excel on-demand check tool, WP97); F-01..F-24: 22 fixed, F-11 and F-22 accepted by design;
  SD-03 accepted until 2027-05-07 (`docs/security/review-2026-11.md`).
- CI on `main`: `ci`, `e2e`, `codeql` and `semgrep` green on the last push bc611ff0 (WP103): `ci` 42798899530, `e2e`
  42798899592, `codeql` 42798899552, `semgrep` 42798899561; `images` (runs on code paths only) green on b56bab8e, run
  42789825341. Red during the round, each fixed by a later commit: `bump-pins` on 805e4ce (quay.io / Red Hat registry
  504s, run 42761736572) and on 8a989aa8 (the Actions token may not push workflow files, run 42763663153; f96389a3);
  `semgrep` on 805e4ce (WP93's pins test, 8a989aa8), on 3ff97397 / d544ebec (WP91's nil-tenant bind) and on
  d7474168 / 302be255 (WP97's check tool, 6d07a4e4); `codeql` on f78c6b20, 3435a31d, 3ff97397 and d544ebec (WP92's
  exercise search, fixed in 744129f9); `ci` from d7474168 to b9ee126b (the `web-browser` smoke after the WP97 merge,
  e.g. run 42783150680; fixed 1ae09ed2). `bump-pins` succeeded on 2274eb4 (run 42796164975) and opened PR #6.
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0), branch `main`. Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secrets `NVD_API_KEY` (repository and Dependabot). The four
  ghcr.io packages are public and carry their SBOMs as OCI referrers. Dependabot: weekly grouped updates (Maven, pub,
  GitHub Actions as SHA + tag) with a 7-day cooldown; the `json-schema-validator` major is ignored (WP43). The weekly
  `bump-pins` PR covers image digests, chart tags and kind pins, but not pins inside workflow files (listed in the PR
  body for a manual bump).

## Pending user actions
1. **bump-pins PR #6** (mailpit v1.33.1, External Secrets Operator v2.15.0): close and reopen it so `ci` / `e2e`
   start (a `GITHUB_TOKEN` PR starts no checks); the ESO bump needs a kind proof (`up.sh --eso --deploy --from-host`,
   ExternalSecrets synced) before merging.
2. **Workflow-file pins by hand**: Trivy, Semgrep and the ZAP digest with `scripts/bump-pins.sh --apply`, then
   `actionlint`. Optional: a fine-grained PAT (contents + pull requests + workflows) so the weekly PR includes them and
   starts its own checks.
3. **Real-browser checks nobody ran**: sign in as `superadmin@hoops-academy.com` (no academy membership, so a pure
   super admin; it should land on the application admin hub, decision 71: no code path to the audit trail was found);
   the hub and the context switcher against the real stack; a calendar `.ics` imported into a calendar app; the
   server-side roster export downloaded from the web. The compose nginx does not serve the web app: start it locally
   (`./start.sh` or `flutter run`, README) and sign in, e.g. as `testadmin1@hoops-academy.com` with
   `TEST_ACADEMY_PASSWORD`.
4. **Owner decisions** (FOLLOW-UPS "Product / contract decisions"): the roster export (guardians' contact data) is
   allowed for a former coach of the team through the season-history rule (`wasStaffOf`): keep or restrict; PARENT and
   PLAYER cannot reach the exercise catalogue in the web (the plan library is staff-only) although the API lets every
   role read it; recapture the landing-page screenshots in `assets/landing` (not done after WP95, WP97, WP99, WP101).
5. **File the Envoy Gateway issue** from `docs/upstream/envoy-gateway-global-ratelimit-descriptor-collision.md`
   (decision 49; WP100 re-tested on v1.10.0: still collides, add that to the draft); drop the `path: /` selector once
   fixed upstream.
6. **Podman machine, in a quiet window (optional)**: `just doctor`'s real write-and-restart path for the drop-in ran only
   against stubs, and `podman machine init --playbook infra/podman/machine-playbook.yml` was never run (WP93); the
   drop-in is present on the current machine.
7. **Local chromedriver** is 156, CI pins Chrome for Testing + chromedriver 157.0.8103.38; update the local one when the
   local Chrome moves.
8. Review the Dependabot and `bump-pins` PRs as they arrive (weekly, Monday).

## Working conventions learned the hard way
- **Parallel sessions and rounds of work packages:** follow `.claude/skills/wp-round` (one worktree per session or WP
  under `$HOME`, never switch branches in a shared checkout; `gitleaks protect --staged` + `git commit --no-verify` with
  explicit paths; waves of at most four building agents, ownership, ADR numbers, merge protocol and traps).
- **Wait for `ci` before stacking the next web merge**: the browser smoke (`web-browser`) runs only in `ci`; in this
  round the WP97 merge broke it and four later pushes stayed red until 1ae09ed2.
- **Pass known gate rules to agents in their prompts**: constant SQL / JPQL with bound parameters (CodeQL
  `java/concatenated-sql-query`), the tenant-switch rule of Semgrep (a nil-tenant bind needs a dated acceptance), no
  environment-derived program names in scripts and tests (Semgrep taint).
- Claude Code hook (`.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude runs
  `git commit` it runs `just isolation-check` (~40 s); before `git push`, `just db-role-check`. Since WP93 it parses
  the command and gates only a real `git commit` / `git push` (wrappers, `git -C`, global options and line
  continuations included); by choice an unquoted `echo git commit` and a heredoc with unbalanced quotes still gate.
  It prints `tenancy-gate: isolation-check PASSED in N s` on stderr. `--no-verify` does not skip it; commits made in a
  terminal are not gated. `just test-hooks` runs its case table.
- **Load on the 2-CPU, 8 GB Podman VM.** Four parallel builds held this round, but once they OOM-killed Keycloak,
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
- **Chosen for the next round (owner, 2026-11-14): cloud deployment, first slice**: an OpenTofu module for one cheap
  cloud VM with k3s, the existing chart installed on it under a test domain. Scope, what stays out and the questions
  for the interview: FOLLOW-UPS.md, "Infra, CI, e2e". Not started, no brief yet.
- **Owner's to-dos of 2026-11-14 (web)**: a light / dark / system theme switch next to the language choice, and demo
  data in the database that looks like the landing screenshots (a seed through the API). Both in FOLLOW-UPS.md, "Web
  app". Not started. Also from that day: **upgrade to JDK 25** (FOLLOW-UPS.md, "Backend"; the places that pin 21 are
  listed there).
- **Owner decisions first** (Pending 4): former coaches and the roster export, the catalogue for families, the landing
  screenshots.
- **Users area depth**: e-mail change and a temporary password from the application admin's Users list; `/me` with
  given and family name per membership (core minor) so the own-name form need not split the display name.
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
