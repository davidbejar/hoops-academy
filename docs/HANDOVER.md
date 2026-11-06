# Session handover (updated 2026-11-06 night — fourth round WP52–WP71 merged, `main` green)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05 and the three rounds of 2026-11-06, the product
owner's decisions 1–51 and the backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder
(`.../Code/Claude/projects/dummy-project2`) is archived and must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20), WP21–WP25, the twelve WPs of 2026-11-05 (WP26–WP37), the
  rounds of 2026-11-06 (WP38–WP42, WP43–WP51; details in FOLLOW-UPS "Resolved") and the twenty of the fourth round,
  merged into `main` on 2026-11-06 in this order (handover or last commit of each):
  - WP64 (c6d7167) NVD cache saved on success only; dependency-check findings reviewed (2 CPE false positives suppressed).
  - WP55 (a82a3f2, runner fixes cc01e49, a214ced, 87a5a6d) `ci` job `web-browser` (mock-mode smoke) and the browser
    login round trip in `e2e`, on pinned Chrome for Testing 157.
  - WP52 (8da29cd) web: match edit, jersey removal, member personal data, academy contact e-mail / website.
  - WP60 (6a0d304) game: feed visibility filter in SQL (ADR-0030 amendment).
  - WP63 (06962d1) kind proofs on chart 0.4.0: 2 Envoy replicas, `tilt ci`, controller restart, journey 21/21.
  - WP56 (1bd8ee5) token audience per service, refresh-token rotation, `SerialRefresh` in the web (ADR-0034; common 1.1.1).
  - WP58 (9145535) core: no-op PATCH writes nothing, ended seasons leave the team ids, guardian logins (core 2.8.0).
  - WP53 (a99f330) demo mock: role-filtered core reads, COACH on staff, persistence and reset.
  - WP70 (04cfed5) public landing page at the anonymous root (es/en/id; decisions 50–51 in 2899170).
  - WP59 (5264ac3) core 3.0.0 removes `resendTenantAdminInvitation` (ADR-0035).
  - WP65 (276977b, snapshot e5523ec) chart 0.5.0: Secrets from the External Secrets Operator (ADR-0012 amendment).
  - WP61 (608ca44) athlete 2.2.0: template texts in es/en/id from `Accept-Language` (ADR-0039, written in the docs pass).
  - WP57 (64fc551) Keycloak realm CSP, password blocklist, optional OTP (ADR-0038).
  - WP54 (d775bd7) Lighthouse and airplane-mode scripts, F-07 cache keys by tenant + person.
  - WP62 (c9a5af7) fitness norms 370 → 475 of 630 cited.
  - WP66 (107d86d) Redpanda in compose, chart 0.6.0 and Dev Services (ADR-0036).
  - WP67 (1d2a252) core outbox publisher and the seven event schemas (ADR-0008 amendment).
  - WP69 (e058aff) athlete roster replica behind `hoops.roster.source`.
  - WP68 (cbb19d3) game roster replica behind `hoops.roster.source` (ADR-0037).
  - WP71 (6bbf58e) chart 0.7.0: services wired to the broker behind `events.enabled` + `global.events.enabled`.
  Also today: the Envoy Gateway issue draft (7b21a48, decision 49).
  Contract versions now: **core 3.0.0, game 2.2.0, athlete 2.2.0, common 1.1.1**; event schemas in
  `libs/contracts/events`. Helm chart **0.7.0** (`hoops-service` subchart 0.5.0).
- Tests (last full local builds): contracts 223, common-quarkus 186, core 871, game 411, athlete 790 = **2,481 JVM
  tests**, 0 failures, every coverage gate met; `e2e` module 27 (4 `MailSinkTest` run, 23 journey steps skipped without
  `e2e.baseUrl`). `flutter test` on `main` after the round: **778 passed**. Mutation: core 558/560 (99.6 %), game
  438/440 (99.5 %), athlete 471/471 (100 %); baselines 95/95/95/100. Chart tests: 134 checks, kubeconform 230/230.
- e2e: `JourneyTest` 23/23 on compose (CI on every push, with the browser login round trip; locally also with
  `GAME_ROSTER_SOURCE=replica` and `ATHLETE_ROSTER_SOURCE=replica`). kind: journey 21/21 on chart 0.4.0 (WP63);
  `smoke.sh core game athlete` 46 checks on chart 0.7.0 with events end to end and the athlete replica flip (WP71).
- Events: built behind the default `hoops.roster.source=rest`; the flip to `replica` waits for the ADR-0037 cutover
  list (core backfill, producer recovery fix, shadow period). `just events-topics` (run by `just up`) and
  `just events-replay game|athlete` on compose; `docs/runbooks/events.md`.
- CI on `main`: `ci`, `e2e` and `images` green through the round; latest `gh run list -b main -L 6`: 6bbf58e (WP71)
  `ci` 42243321711 and `e2e` 42243321817 success; cbb19d3 (WP68) `e2e` 42234657458, `ci` 42234657432, `images`
  42234657477 success; e058aff (WP69) `ci` 42232026262 success.
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0), branch `main`. Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secret `NVD_API_KEY`. The four ghcr.io packages are public.
  Dependabot: weekly grouped updates (Maven, pub, GitHub Actions as SHA + tag), automated security fixes; the
  `json-schema-validator` major is ignored (WP43).

## Pending user actions
1. **File the Envoy Gateway issue** from `docs/upstream/envoy-gateway-global-ratelimit-descriptor-collision.md`
   (decision 49); when it is fixed upstream, drop the `path: /` selector (ADR-0033 amendment).
2. **`.env` needs the four `REDPANDA_*_PASSWORD` keys** (admin, core-service, game-service, athlete-service; see
   `.env.example`), otherwise `deploy/kind/secrets.sh` and `eso-store.sh` stop.
3. **Compose realm after WP57**: `just up` (new blocklist mount) then `just seed-users` (patches CSP, password and OTP
   policy into the existing realm). A kind realm keeps the old settings until its Keycloak database is recreated.
4. **Local chromedriver** is 156, CI pins Chrome for Testing + chromedriver 157.0.8103.38; update the local one
   (Chrome for Testing download, `xattr -d com.apple.quarantine`) when the local Chrome moves.
5. Review the Dependabot PRs as they arrive (weekly, Monday).

## Working conventions learned the hard way
- **Parallel sessions and rounds of work packages:** follow `.claude/skills/wp-round` (one worktree per session or WP
  under `$HOME`, never switch branches in a shared checkout; `gitleaks protect --staged` + `git commit --no-verify` with
  explicit paths; waves, ownership, ADR numbers, merge protocol and traps).
- Claude Code hook (`.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude
  runs `git commit` it runs `just isolation-check` (~40 s); before `git push`, `just db-role-check` (~40 s). A failure
  blocks the git command; `--no-verify` does not skip it. Both need Podman. Commits made in a terminal are not gated.
- **Load on the 2-CPU Podman VM.** Five or six parallel builds (or a kind cluster plus builds) push the VM's load
  average far above 5: the isolation hook then times out starting Keycloak, Testcontainers fails with
  "localhost:2375 failed to respond" on a Quarkus restart (athlete `AthleteDatabaseRoleTest`, `ReplicaAuthzRulesTest`),
  `ratelimit-check.sh` gives early 429s and the kind control plane may restart. Retry once the load drops; never
  bypass the hook. Stop compose (`just down`) while proving on kind.
- **Fresh Helm install with events on**: the bootstrap Job runs after `--wait`, so restart core once afterwards
  (`kubectl rollout restart deploy/core-service`; `deploy/kind/up.sh` and Tilt do it) until core's producer recovers by
  itself.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH.
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/baseline.conf` with `[alert=..][url=..]` scoping.
- `.env` needs `RATELIMIT_REDIS_PASSWORD` (chart 0.4.0) and the `REDPANDA_*_PASSWORD` keys (chart 0.6.0).
- Realm changes need a Keycloak re-import (`just down && podman volume rm hoops_pgdata && just up && just seed-users`)
  or, for the settings it knows, `just seed-users` alone.
- Parallel worktrees share the compose database: a service started from a branch that lacks a migration another
  worktree already applied needs `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future'` until both are merged.
- **Podman VM clock drift** after the host sleeps: the hook scripts (`scripts/hooks/_common.sh`) step the VM clock
  before each check; by hand: `podman machine ssh "sudo date -u -s @$(date +%s)"`.

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- Events cutover: core backfill of pre-WP67 aggregates, core producer recovery after a failed first SASL login, a
  shadow period, the game flip on kind, then `replica` by default; `applied_event` pruning.
- Invitation-only sign-up (decision 51) behind the landing form; decide who becomes ADMIN when a parent or coach asks.
- Web: account-console link in the profile menu, plan refetch on a language switch, match edit from the list tile,
  guardian first login from the member page, landing contrast; Lighthouse and airplane-mode scripts in CI.
- Infra: Reloader (or similar) for rotated secrets, nginx's double Referrer-Policy, a load guard in
  `ratelimit-check.sh`, `tilt ci` and `--eso` on chart 0.7.0.
- Fitness norms: the remaining 155 placeholder rows (`docs/domain/norms.md`).
- v2: billing module on the existing seams, purge job (also for old audit rows).
