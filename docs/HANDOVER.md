# Session handover (updated 2026-11-07 — fifth round WP72–WP90 merged, `main` green)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05 and the four rounds of 2026-11-06/07, the product
owner's decisions 1–63 and the backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder
(`.../Code/Claude/projects/dummy-project2`) is archived and must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20), WP21–WP25, the twelve WPs of 2026-11-05 (WP26–WP37), the
  rounds of 2026-11-06 (WP38–WP42, WP43–WP51, WP52–WP71; details in FOLLOW-UPS "Resolved") and the eighteen of the
  fifth round (WP72–WP90, no WP79), merged into `main` on 2026-11-06/07 in this order (handover or last commit of each):
  - WP72 (fd918c2) web design system: tokens, theme, shared kit, shell (ADR-0040).
  - WP75 (81a595a) web redesign: admin, platform, audit, profile and shell screens.
  - WP87 (f6cdb9f) chart 0.8.0 Reloader on Secret rotation (ADR-0012 amendment), kind load guard, the Testcontainers
    flake's root cause and `ContainerStarts`.
  - WP78 (2cfb54e) athlete 2.3.0: sessions reference any plan, item search, quick-add (ADR-0041).
  - WP74 (35bd15e) web redesign: live match, match list, box score, season stats.
  - WP83 (af70a6f) SAST/DAST gates: SpotBugs in `verify`, CodeQL, Semgrep, ZAP API scans (ADR-0045; findings SD-01..08).
  - WP81 (3eefea7, handover 992ef82) core producer recovery, `.removed` events, backfill (core 3.1.0; ADR-0008
    amendment; the core 3.1.0 bump by the orchestrator).
  - WP73 (a94a780) web redesign: training, plans, sessions, health, roster.
  - WP89 (7675d30) weekly `bump-pins` PR for image digests, chart tags and kind pins.
  - WP86 (6adcae2) chart 0.9.0 OpenTelemetry collector, Jaeger on kind, WP87's kind proofs (ADR-0046).
  - WP80 (f6f59da) season history read-only for former staff (ADR-0042; core 3.2.0, game 2.3.0, athlete 2.4.0).
  - WP76 (f576528) web gaps: account console, template refetch, match edit from the list, guardian password,
    sit-and-reach hint, past-seasons selector.
  - WP82 (f09499e) replica soft removals and retention jobs (ADR-0037 amendment; game V6, athlete V9).
  - WP85 (6e0f7e8) security events, Keycloak login events, SBOM per image (ADR-0043).
  - WP90 (0fa175b) invitation-only sign-up (ADR-0044; core 3.3.0, V17).
  - WP77 (d7fdfb1) landing language switch in the header, screenshots per locale.
  - WP88 (91c1e4f) mutation round: wider PIT scope, baselines = scores, Dart mutation tool.
  - WP84 (49ba555) security fixes: SD-01..SD-08 (7 fixed, SD-03 accepted).
  Orchestrator fixes in between: Semgrep acceptances (483d595, 94b755b), SpotBugs exclusion for `KafkaEventBroker`
  (7cdded2), offline cold-start marker (599d38a), SBOM attach on the rootless runner (054b629), weekday-dependent
  schedule test (b520476). Plan table closed in 6d4524d.
  Contract versions now: **core 3.3.0, game 2.3.0, athlete 2.4.0, common 1.1.1**; event schemas in
  `libs/contracts/events` (12 types since WP81's `.removed`). Helm chart **0.9.0** (`hoops-service` 0.7.0, `keycloak`
  0.5.0); switches `events.enabled` + `global.events.enabled`, `global.reloader.enabled`, `global.observability.enabled`
  (all on in `values-kind.yaml`).
- Tests (final full verify of WP84 at 49ba555): common-quarkus 392, contracts 279, core 914, game 468, athlete 994 =
  **3,047 JVM tests**, 0 failures, every coverage and SpotBugs gate met; `e2e` module 32 (6 `MailSinkTest` run, 26
  journey steps skipped without `e2e.baseUrl`). `flutter test` on `main` after the round: **1077 passed** (fresh run in
  the docs pass). Mutation (PIT): common 312/313, core 777/778, game 548/550, athlete 687/687; Dart tool 430/430;
  baselines 99 / 99 / 99 / 100 and web 100 (`docs/quality/mutation.md`). Chart tests green (176 checks at WP90,
  kubeconform 254/254 at WP84).
- e2e: `JourneyTest` **26/26** on compose (WP84; CI on every push, with the browser login round trip and, since WP83,
  the ZAP API scans; sign-up steps with MailHog since WP90). Locally also 23/23 with `replica` in both services (WP81).
  kind (chart 0.9.0, WP86): `up.sh --eso --deploy --from-host`, `smoke.sh`, a Secret rotation rolled by Reloader, the
  game replica flip, `events.enabled=false`, `tilt ci -- --eso --from-host` and a trace Envoy → core → game/athlete.
- Events: still behind the default `hoops.roster.source=rest`. Done: backfill (`just events-backfill`), producer
  recovery, `.removed` everywhere with soft removals and retention, the game flip on kind. Left before the flip: a
  shadow period over days in a shared environment, then the owner's decision (ADR-0037 "When rest flips").
- Security: SAST/DAST gate every push (ADR-0045); round 5 findings SD-01..SD-08 closed (7 fixed, SD-03 accepted until
  2027-05-07); F-01..F-24: 22 fixed, F-11 and F-22 accepted by design (`docs/security/review-2026-11.md`).
- CI on `main`: `ci`, `e2e`, `images`, `codeql` and `semgrep` green at the end of the round. Red during the round, each
  fixed by the next orchestrator or WP commit: `ci` on 81a595a and f6cdb9f (athlete schedule test on a Friday evening,
  fixed 710b18f), on 3eefea7 and 483d595 (SpotBugs on WP81's `KafkaEventBroker` under WP83's gate, 7cdded2) and on
  91c1e4f (run 42361107787, the Saturday schedule test, b520476); `semgrep` on 3eefea7 and 7cdded2 (acceptances
  483d595, 94b755b); `images` on 6e0f7e8 (run 42353594529, the SBOM attach on the rootless runner, 054b629). Latest `gh run list -b main -L 8` (2026-11-07, 49ba555, WP84): `ci` 42367239213,
  `e2e` 42367239185, `images` 42367239187, `codeql` 42367239191, `semgrep` 42367239197, all success (the other rows
  are Dependabot update jobs, success; Dependabot PR #5, `browser-actions/setup-chrome`, is open). Previous push
  b520476: `ci` 42362440951, `e2e` 42362440949, `images` 42362440994, `codeql` 42362440995, `semgrep` 42362441013.
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0), branch `main`. Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secret `NVD_API_KEY`. The four ghcr.io packages are public and
  carry their SBOMs as OCI referrers. Dependabot: weekly grouped updates (Maven, pub, GitHub Actions as SHA + tag) with
  a 7-day cooldown, automated security fixes; the `json-schema-validator` major is ignored (WP43). The weekly
  `bump-pins` workflow covers the rest (WP89).

## Pending user actions
1. **Podman API without the idle timeout** (WP87): **done 2026-11-07** (drop-in `no-timeout.conf` in the VM, service
   running with `--time=0`). Survives stop/start and reboots; lost on `podman machine rm` / `reset`. Follow-up in
   FOLLOW-UPS "Infra": a repo playbook for `podman machine init --playbook` plus a self-healing `just doctor` step.
   Also new there: `NVD_API_KEY` must exist as a *Dependabot* secret too (dependency-check is red on Dependabot PRs).
2. **GitHub for `bump-pins`** (WP89): settings **done 2026-11-07** (Actions may create PRs, token read-only, label
   `dependencies`). No run yet; first schedule Monday 2026-11-09 05:17 UTC. When the PR arrives: close and reopen it
   (a `GITHUB_TOKEN` PR does not start `ci` / `e2e`); its Envoy Gateway v1.10.0 bump needs the Gateway API matrix
   check and a kind proof before merging.
3. **File the Envoy Gateway issue** from `docs/upstream/envoy-gateway-global-ratelimit-descriptor-collision.md`
   (decision 49); when it is fixed upstream, drop the `path: /` selector (ADR-0033 amendment).
4. **Local chromedriver** is 156, CI pins Chrome for Testing + chromedriver 157.0.8103.38; update the local one
   (Chrome for Testing download, `xattr -d com.apple.quarantine`) when the local Chrome moves.
5. **Compose stack after the round**: `just up` (nginx edge headers of WP84, Keycloak event log level of WP85) and
   `just seed-users` (patches the realm's event settings). The SMTP keys of `.env.example` are optional locally (the
   defaults reach MailHog).
6. **Events default flip**: run a shadow period (ADR-0037, `runbooks/events.md` "Backfill and shadow period"), then
   decide.
7. Review the Dependabot and `bump-pins` PRs as they arrive (weekly, Monday).

## Working conventions learned the hard way
- **Parallel sessions and rounds of work packages:** follow `.claude/skills/wp-round` (one worktree per session or WP
  under `$HOME`, never switch branches in a shared checkout; `gitleaks protect --staged` + `git commit --no-verify` with
  explicit paths; waves, ownership, ADR numbers, merge protocol and traps).
- Claude Code hook (`.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude
  runs `git commit` it runs `just isolation-check` (~40 s); before `git push`, `just db-role-check` (~40 s). A failure
  blocks the git command; `--no-verify` does not skip it. Both need Podman. Commits made in a terminal are not gated.
- **Load on the 2-CPU Podman VM.** Five or six parallel builds (or a kind cluster plus builds) push the VM's load
  average far above 5: the commit hook's isolation check then times out waiting for Keycloak (`/health/ready` not up
  within 5 min; it happened several times in the fifth round, the retry passed), `ratelimit-check.sh` ends
  `RATE LIMIT CHECK INCOMPLETE` (exit 3) through the load guard (`deploy/kind/load-guard.sh`, 2 per CPU;
  `HOOPS_LOAD_WAIT=<s>` waits) and the kind control plane may lose its API server (leader election is off on kind's
  single control plane and the CNPG operator since WP86/WP87). Retry once the load drops; never bypass the hook. Stop
  compose (`just down`) while proving on kind.
- **"localhost:2375 failed to respond"** (Testcontainers / Dev Services): the Podman API service (`--time 5`) closes
  keep-alive connections idle for 10 s and docker-java never re-validates them, so a container start after a long
  Quarkus restart meets a dead connection (WP87). `ContainerStarts` contains it for the test-jar resources and Kafka
  Dev Services are off in tests (WP82); the root fix is the `--time=0` drop-in (applied 2026-11-07, user action 1).
- **Rate-limit pauses** (agent sessions): long rounds hit the account's rate limit; an agent pauses and later resumes
  in the same worktree and branch. After a resume, check the worktree's `git status` and log before trusting the
  agent's last report.
- **Fresh Helm install with events on**: since WP81 core's producer recovers by itself once the bootstrap Job has
  created its broker user; `deploy/kind/up.sh` still restarts core after `SASL authentication failed` (harmless, can
  go).
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH.
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/baseline.conf` with `[alert=..][url=..]` scoping.
- `.env` needs `RATELIMIT_REDIS_PASSWORD` (chart 0.4.0) and the `REDPANDA_*_PASSWORD` keys (chart 0.6.0), otherwise
  `deploy/kind/secrets.sh` and `eso-store.sh` stop; the SMTP keys (WP90) are optional locally.
- Time-dependent tests: CI runs at any hour; a test that fixes a weekday and a local time (Europe/Madrid) fails on that
  weekday after that hour (two athlete schedule tests in this round). Derive dates from the test's "now".
- Realm changes need a Keycloak re-import (`just down && podman volume rm hoops_pgdata && just up && just seed-users`)
  or, for the settings it knows, `just seed-users` alone.
- Parallel worktrees share the compose database: a service started from a branch that lacks a migration another
  worktree already applied needs `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future,*:missing'` until both are merged.
- **Podman VM clock drift** after the host sleeps: the hook scripts (`scripts/hooks/_common.sh`) step the VM clock
  before each check; by hand: `podman machine ssh "sudo date -u -s @$(date +%s)"`.

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- **Exercise catalogue** (decision 54): exercises as an entity (global localised plus tenant-defined), templates
  referencing them, searchable and quick-addable on their own; athlete 3.0.0.
- **Events default flip**: a shadow period over days on kind or staging (parked 0, lag in seconds), then `replica` by
  default (ADR-0037); drop the core restart from `up.sh`.
- **Billing** module on the existing seams (`billing.*`, `EntitlementService`, the published outbox events).
- **Purge job** for withdrawn tenants, old audit rows and decided academy requests (WP90).
- **Breached-password check** (ASVS 6.2.12; not now by decision 60) and an **optimised Keycloak image** (read-only
  root FS, KSV-0014; not now by decision 63).
- Smaller: the chart's SMTP settings for core and a chart bump (WP90, WP85), the kit follow-ups and the Indonesian
  bottom nav (WP72–WP77), the sign-up leftovers (audit label, compose `limit_req`), self-service name edit (core
  contract), the Envoy Gateway v1.10.0 bump, the remaining 155 fitness-norm placeholders (`docs/domain/norms.md`).
