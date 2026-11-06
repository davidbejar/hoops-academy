# Session handover (updated 2026-11-06 — WP26–WP37 merged, e2e green on kind)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plan of 2026-11-05, the product owner's decisions and the backlog are in
`docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder (`.../Code/Claude/projects/dummy-project2`) is archived and
must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20; WP19 events/Redpanda not built, v2), WP21–WP25 (e-mail logins,
  super admin manages academy admins, temporary password at first sign-in, ADR-0023/0024), the end-to-end isolation
  test and database role check with their Claude Code hook (2026-11-05), and the twelve WPs of the 2026-11-05 plan,
  merged into `main` on 2026-11-05/06 (WP37 before WP36 at the end):
  - WP26 docs reconciliation and the 14 decisions of 2026-11-05 (ADR-0025).
  - WP27 fitness norms: 370 of 630 rows cited.
  - WP28 web: a PLAYER's own box-score line, REJECTED label.
  - WP29 contracts without `allOf`, strict validation everywhere (ADR-0027; core 2.3.1, game 2.0.1, athlete 2.0.1).
  - WP30 infra hygiene: e2e readiness on `status == UP`, Tiltfile chart sync, runtime image pinned by digest.
  - WP31 a shared login's e-mail reaches every academy (ADR-0026).
  - WP32 temporary passwords expire after 3 days, event-triggered sweep (ADR-0028; core 2.4.0).
  - WP33 match event feed filtered for parents and players, F-01 fixed (ADR-0030; game 2.1.0).
  - WP34 audit trail read API and Activity screens (ADR-0029; core 2.5.0).
  - WP35 web UX gaps (not-a-member state, academy time zone, usage trend, session/measurement/result/absence editing,
    availability badge).
  - WP36 Gateway API with Envoy Gateway v1.9.3 replaces ingress-nginx, chart 0.2.0 (ADR-0031).
  - WP37 mutation testing on demand (`just mutation`, `mutation.yml` manual + monthly): common 99.1 %, core 99.6 %,
    game 99.5 %, athlete 100 %; baselines 95/95/95/100.
  Contract versions now: **core 2.5.0, game 2.1.0, athlete 2.0.1**.
- Tests on 3b59360 (CI `ci` run 42112940234): JVM common-quarkus 186, contracts 146, core 770, game 255, athlete 613 =
  **1,970 tests**, 0 failures (equals the fresh local `verify` in the WP37 handover); `flutter test` **608 passed**
  (unchanged since WP35; the date-dependent week golden was fixed in 7e13cec).
- e2e: `JourneyTest` 21 tests green on compose in CI (run 42112940232 on 3b59360, 71.7 s) and **green on kind for the
  first time** in WP36 (21 tests, 159 s, through the Envoy Gateway on :8090; the MailHog checks are skipped on kind).
- CI on `origin/main` 3b59360 (2026-11-05 21:28 UTC): `e2e` and `images` green, manual `mutation` run 42112955113 green
  for all four modules; `ci` failed in `trivy-fs` only: KSV-0014 (Keycloak without a read-only root FS, accepted
  until 2027-03-31) fired on WP36's new snapshot `deploy/helm/tests/snapshots/umbrella-tls.yaml`, which
  `.trivyignore.yaml` did not list. Fixed on 2026-11-06 (the TLS snapshot added to the accepted paths; `trivy fs
  --scanners misconfig` from the repo root reports 0 findings on every snapshot); the docs reconciliation commits and
  that fix were pushed together. Every earlier run on `main` since 5ab1f71 (2026-11-02) was green.
- Browser checks: `apps/web/tool/web_smoke.sh` green in mock mode in WP35; `--real` mode and
  `browser_login_check.py --set-new-password` last green on 2026-11-02 / WP25. Lighthouse, airplane-mode cold start and
  chromedriver in CI are still open.
- GitHub: `davidbejar/hoops-academy` (public), branch `main`. Repository variable `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`;
  secret `NVD_API_KEY` (valid since 2026-11-02). The four ghcr.io packages (core-service, game-service,
  athlete-service, web) are **public** (decision 9, verified 2026-11-05); a cluster pulls them without
  `global.imagePullSecrets`.

## Pending
1. **Product owner decisions** (FOLLOW-UPS):
   - WP34: `tenant.suspended` / `tenant.withdrawn` audit rows keep the super admin's free-text `reason`, which academy
     admins now read (keep, or move it out of the audit row); PLATFORM rows show the super admin's Keycloak `sub` to
     academy admins (keep, or show "platform administrator").
   - WP35: update requests cannot clear a field (null = unchanged; needs a contract convention: explicit null or a
     `clear` list); `/me` memberships carry no tenant `timezone` (add it to `TenantSummary`?).
   - WP36: Envoy local rate limits are per replica with burst = rpm (global rate limiting with Redis if the proxy
     scales out?); no gateway body-size limit (the services enforce 2 MB).
2. **Mutation workflow**: `gh workflow run mutation.yml` was run once (run 42112955113, green); nothing left but the
   monthly schedule.
4. **dependency-check NVD cache**: the workflow still saves the cache `if: always()`; if the job takes > 40 min, find the
   `nvd-Linux-*` key "Restore NVD data" restored and `gh cache delete` it. Still to do once: review the
   `dependency-check-report` findings below the CVSS 7 gate. If NVD answers 503, rerun the job.

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
  falls behind or stalls (16–59 min behind on 2026-11-06), so Keycloak tokens look expired: the commit/push hooks fail
  with 401 or time out after 15 min. Fix: `podman machine ssh "sudo date -u -s @$(date +%s)"` right before the commit
  (or in a background loop during a long session). A host-level fix is still open (FOLLOW-UPS).
- **Worktree wave flow** (used for WP26–WP37): one worktree per WP under `~/code/hoops-wt` (under `$HOME`, so the
  Podman machine sees it), one branch per WP; when a WP is done, rebase it onto `main`, rerun its checks, merge with
  `git merge --ff-only`, then the next WP rebases. Shared docs (`HANDOVER.md`, `FOLLOW-UPS.md`, `README.md`, the ADR
  index) are owned by one agent; the others note their follow-ups in their own handover. ADR numbers are assigned at
  merge time (renumber on rebase).

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- Keycloak CSP hardening via realm `browserSecurityHeaders` (removes the accepted ZAP alerts under `/auth/realms/`).
- `tilt ci` with core-service; the e2e MailHog checks on kind (Mailpit's API is `/api/v1`); Lighthouse installability
  and airplane-mode cold start for the PWA; chromedriver in CI.
- Contract WP for the WP35 gaps once decided; delete or use core `ApprovalPayload.empty()` (dead code, WP37).
- Save the NVD cache on success only.
- v2: outbox + Redpanda (WP19), billing module on the existing seams, purge job (also for old audit rows).
