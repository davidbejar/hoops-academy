# Session handover (updated 2026-11-06 evening — WP38–WP42 merged, e2e green on kind with mail checks)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plans of 2026-11-05 and 2026-11-06, the product owner's decisions 1–23 and
the backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder (`.../Code/Claude/projects/dummy-project2`)
is archived and must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20; WP19 events/Redpanda not built, v2), WP21–WP25 (e-mail logins,
  super admin manages academy admins, temporary password at first sign-in), the twelve WPs of the 2026-11-05 plan
  (WP26–WP37: decisions, cited norms, contract validation, temporary-password expiry, feed filter F-01, audit trail
  read API, web UX gaps, Gateway API, mutation testing; details in FOLLOW-UPS "Resolved") and the five WPs of the
  2026-11-06 plan, merged into `main` on 2026-11-06 in the order WP38, WP40, WP39, WP42, WP41:
  - WP38 (2b0f33b) the super admin is masked as "Platform administrator" on the academy audit path, the `reason`
    stays readable; `ApprovalPayload.empty()` deleted (ADR-0029 amendment; core 2.6.0).
  - WP40 (5b020c2) global gateway rate limits: Envoy Gateway's rate limit service + Redis `ratelimit-redis`, shared by
    every Envoy replica, fail open (ADR-0033; chart 0.3.0). `ratelimit-check.sh` passed on kind with 1 and 2 replicas
    and with Redis down.
  - WP39 (bb68194) athlete update requests carry a `clear` list (absent or null = unchanged), the web edit forms send
    it; a test type's code can be changed and the type deleted unless results use it (ADR-0032; athlete 2.1.0).
  - WP42 (ba4e948) e2e `MailSink` reads MailHog v2 or Mailpit v1, so the mail checks run on kind too; `tilt ci` on the
    Gateway API chart green; the e2e module's unit tests now run in every `verify`.
  - WP41 (33441be) demo mock serves `/platform/*` and `/api/athlete/*` (the demo user is a super admin by default),
    the academy time zone comes from `/me` (`authz.timezone`); browser smoke walks training and the platform console.
  Also today: AGPL-3.0 `LICENSE` and README License section (20f1921), trivy ignore for `umbrella-tls.yaml` (5ee9be5),
  hooks resync the Podman VM clock (e6a8847), Dependabot (625a5f9).
  Contract versions now: **core 2.6.0, game 2.1.0, athlete 2.1.0, common 1.1.0**; Helm chart **0.3.0**.
- Tests (fresh local `./mvnw -B -ntp -T 1C clean verify` after WP39 rebased on WP38): JVM contracts 152, common-quarkus
  186, core 773, game 255, athlete 653 = **2,019 tests**, 0 failures, every coverage gate met; since WP42 the `e2e`
  module adds 4 `MailSinkTest` runs and reports the 21 journey tests as skipped (no `e2e.baseUrl` in `verify`).
  `flutter test` after WP41: **646 passed**, analyze clean. Mutation: athlete 430/430 killed after WP39 (the other
  modules were not re-run; baselines 95/95/95/100 from WP37).
- e2e: `JourneyTest` 21/21 on compose (CI `e2e` on every push; WP42 locally 25/25 incl. `MailSinkTest`) and **21/21 on
  kind with the mail checks** through the Envoy Gateway on :8090 (Mailpit's `/api/v1`, WP42). `just tilt ci -- --from-host`
  on a fresh kind cluster: "All workloads are healthy" in 5 min 55 s (WP42).
- CI on `main`: `ci`, `e2e`, `images` green on bb68194 (WP39); `ci` and `e2e` green on ba4e948 (WP42) and 625a5f9
  (Dependabot; `images` did not run, path filter); `ci`, `e2e` and `images` green on 33441be (WP41, runs 42157371199,
  42157371253, 42157371230): `main` is green end to end.
- Dependabot: weekly grouped version updates (Maven with Quarkus in its own group, pub, GitHub Actions; Monday 06:00
  Europe/Madrid) and automated security fixes. The first four PRs: #1 actions group and #2 Maven minor/patch group
  green, #4 `cupertino_icons` 2.0.0 green, #3 `json-schema-validator` 3.0.8 red (API change, FOLLOW-UPS).
- Browser checks: `apps/web/tool/web_smoke.sh` green in mock mode in WP41 (now through training and the platform
  console); `--real` mode and `browser_login_check.py --set-new-password` last green on 2026-11-02 / WP25. Lighthouse,
  airplane-mode cold start and chromedriver in CI are still open.
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0, description and topics set), branch `main`. Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secret `NVD_API_KEY` (valid since 2026-11-02). The four ghcr.io
  packages (core-service, game-service, athlete-service, web) are **public** (decision 9); a cluster pulls them without
  `global.imagePullSecrets`.

## Pending
1. **Review the Dependabot PRs as they arrive** (weekly, Monday). Today: merge #1, #2 and #4 if you agree (green);
   #3 (`json-schema-validator` 3.x) needs a code change in `libs/contracts` tests or should be closed / ignored for 3.x.
2. Nothing else is blocking. Non-blocking: the dependency-check NVD cache is still saved `if: always()` (if the job takes
   more than 40 min, `gh cache delete` the `nvd-Linux-*` key it restored; rerun on NVD 503); the `dependency-check-report`
   findings below the CVSS 7 gate were never reviewed.

## Working conventions learned the hard way
- Two Claude sessions worked in this checkout at once on 2026-11-02 and one switched branches under the other. If more than one
  session works on the repo, give each its own `git worktree` **under `$HOME`** (the Podman machine cannot see `/tmp`), and push
  with `git push origin <branch>:main` instead of switching branches in a shared checkout.
- Commit with `gitleaks protect --staged` first and `git commit --no-verify` (the pre-commit stash conflicts with concurrent
  edits); never `git add -A` when another session may have files in flight.
- Claude Code hook (`.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude
  runs `git commit` it runs `just isolation-check` (academy A logs in through real Keycloak and cannot read academy B,
  ~40 s); before `git push`, `just db-role-check` (no service connects as a table owner, superuser or BYPASSRLS role,
  ~40 s). A failure blocks the git command; `--no-verify` does not skip it. Both need Podman. Commits a person makes in a
  terminal are not gated: run the two `just` recipes yourself. Review or disable the hook with `/hooks`.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH
  (Homebrew cask is disabled; download from Chrome for Testing and `xattr -d com.apple.quarantine`).
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/baseline.conf` with `[alert=..][url=..]` scoping (`scripts/zap-gate.py`).
- Realm changes need a Keycloak re-import: `just down && podman volume rm hoops_pgdata && just up && just seed-users`.
- **Podman VM clock drift.** After the host sleeps (also in maintenance sleep / dark wake), the Podman machine's clock
  falls behind or stalls (16–59 min behind on 2026-11-06), so Keycloak tokens look expired. Since e6a8847 the hook
  scripts (`scripts/hooks/_common.sh`) step the VM clock before each check; by hand outside the hooks:
  `podman machine ssh "sudo date -u -s @$(date +%s)"`.
- **Worktree wave flow** (used for WP26–WP37): one worktree per WP under `~/code/hoops-wt` (under `$HOME`, so the
  Podman machine sees it), one branch per WP; when a WP is done, rebase it onto `main`, rerun its checks, merge with
  `git merge --ff-only`, then the next WP rebases. Shared docs (`HANDOVER.md`, `FOLLOW-UPS.md`, `README.md`, the ADR
  index) are owned by one agent; the others note their follow-ups in their own handover.
- **Parallel WPs, lessons of WP38–WP42.** Assign ADR numbers in the briefs up front (0032 and 0033 were fixed before the
  wave, so nothing was renumbered on rebase). Give each WP of a wave disjoint file ownership (service, chart, web, e2e);
  a WP that depends on another's contract goes in the next wave (WP41 after WP38/WP39). The only conflicts in the round
  were shared doc indexes (ADR README, roadmap, runbook lists); keep those to the docs pass or append-only.

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- Adopt the ADR-0032 `clear` list in core (still merge patch: `null` clears) and game when they need it; an injury edit
  dialog in the web app.
- Redis ACL for `ratelimit-redis` (defense in depth beyond the NetworkPolicy); exercise the controller-restart branch of
  `deploy/kind/up.sh`.
- Keycloak CSP hardening via realm `browserSecurityHeaders` (removes the accepted ZAP alerts under `/auth/realms/`).
- Lighthouse installability and airplane-mode cold start for the PWA; chromedriver in CI.
- Demo mock: athlete data for the second academy, rosters shared with the core mock, role checks; a repo-wide
  `dart format` policy.
- Save the NVD cache on success only.
- v2: outbox + Redpanda (WP19), billing module on the existing seams, purge job (also for old audit rows).
