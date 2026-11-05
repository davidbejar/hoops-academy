# Session handover (updated 2026-11-05 — CI green, wave 1 of the 2026-11-05 plan)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the plan of 2026-11-05, the product owner's decisions and the backlog are in
`docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder (`.../Code/Claude/projects/dummy-project2`) is archived and
must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20; WP19 events/Redpanda not built, v2) and WP21–WP25 (e-mail logins,
  super admin manages academy admins, temporary password at first sign-in, ADR-0023/0024). On 2026-11-05: an end-to-end
  isolation test (academy A cannot read academy B through real Keycloak, `CrossTenantAccessTest`), a database role check
  (`DatabaseRoleMetaTest`: no service connects as owner, superuser or BYPASSRLS) and the Claude Code hook that runs them
  (commits 67e6165, 70d860b).
- Decisions of 2026-11-05 (product interview, 14 answers): `docs/wp/FOLLOW-UPS.md` "Plan (2026-11-05)"; decisions 1–3
  and 6 are ADR-0025 (learning project; one login, many academies; F-11 and pre-account hijacking accepted by design).
- Local verification (WP26, 2026-11-05, on ec3360e): `./mvnw -B -ntp -T 1C verify` exit 0, coverage gates met; surefire
  common-quarkus 172, contracts 120, core 691, game 196, athlete 581 = **1,760 tests**, 0 failures. `flutter test`: 538
  tests, 537 passed, 1 failed — a date-dependent golden (`training_week_360x780.png`, fails on the days of the week of
  2026-11-02 only; FOLLOW-UPS "Date-dependent golden"); CI passes it with its golden tolerance. The e2e journey (21
  steps) and the browser checks were not re-run locally in WP26.
- Browser checks (not re-run since 2026-11-02): `apps/web/tool/web_smoke.sh` green in mock and `--real` modes (commit
  06ba5ac); `apps/web/tool/browser_login_check.py --set-new-password` signed a new admin in with the temporary password
  through the branded `hoops` update-password page (WP25 live check, commit e2a3916). Lighthouse, airplane-mode cold
  start and chromedriver in CI are still open.
- GitHub: `davidbejar/hoops-academy` (public), branch `main`. Repository variable `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`;
  secret `NVD_API_KEY` (valid since 2026-11-02; dependency-check green with it).
- CI on `origin/main` 70d860b (2026-11-05): **all three workflows green**, as every run on `main` since 5ab1f71
  (2026-11-02) — `ci` run 42038926658 (backend 1,760 tests, flutter 538, trivy-fs, zap-baseline, dependency-check,
  secrets-scan, helm-chart-tests), `e2e` run 42038926724 (`JourneyTest` 21 steps on the runner's Podman stack), `images`
  run 42038926785 (four images built, scanned and pushed to
  `ghcr.io/davidbejar/hoops-academy/{core-service,game-service,athlete-service,web}:<sha>`).
- The four ghcr.io packages are **public** (decision 9; checked by the product owner in GitHub and verified from a
  terminal on 2026-11-05: an anonymous registry token gets 200 on `/v2/davidbejar/hoops-academy/<name>/tags/list` for
  core-service, game-service, athlete-service and web, and fetches the `70d860b…` manifest). A cluster can pull them
  without `global.imagePullSecrets`. Package pages:
  https://github.com/davidbejar/hoops-academy/pkgs/container/hoops-academy%2Fcore-service,
  …%2Fgame-service, …%2Fathlete-service, …%2Fweb.

## Pending
1. **dependency-check NVD cache.** On 2026-11-05 the `ci` run on 70d860b restored the NVD cache `nvd-Linux-41422780377`,
   which the *failed* run 41422780377 (2026-11-02) had saved, and the dependency-check job ran 77 min (13:47–15:05 UTC)
   instead of ~2 min. That cache has been deleted (`gh cache list` no longer shows it); the newest cache is now
   `nvd-Linux-42038926658` from the green run. The workflow still saves on failure (`if: always()` on "Save NVD data"),
   so it can happen again: if the job takes > 40 min, look up which `nvd-Linux-*` key "Restore NVD data" restored and
   `gh cache delete` it (FOLLOW-UPS). Still to do once: download the `dependency-check-report` artifact of a `ci` run and
   review the findings below the CVSS 7 gate. Keep `quarkus.platform.version` on the latest 3.40.x patch; if NVD answers
   503, rerun the job.
2. **The 2026-11-05 work-package plan** (table in `docs/wp/FOLLOW-UPS.md`): wave 1 WP26–WP31 (briefs written, running
   in parallel worktrees), wave 2 WP32–WP33, wave 3 WP34–WP35, wave 4 WP36. Merge each wave before starting the next.

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

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- Keycloak CSP hardening via realm `browserSecurityHeaders` (removes the accepted ZAP alerts under `/auth/realms/`).
- Run the e2e journey on kind and `tilt ci` with core; Lighthouse installability and airplane-mode cold start for the PWA;
  chromedriver in CI.
- Save the NVD cache on success only; make the week-calendar golden independent of today's date.
- v2: outbox + Redpanda (WP19), billing module on the existing seams, purge job (also for old audit rows).
