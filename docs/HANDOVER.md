# Session handover (updated 2026-11-02, afternoon)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the prioritised backlog is `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning
folder (`.../Code/Claude/projects/dummy-project2`) is archived and must not be written to.

## State
- All v1 work packages are built, tested and committed. Local verification: 1,467 JVM tests, 477 Flutter tests, 20-step e2e
  journey on the compose stack, browser smoke (`apps/web/tool/web_smoke.sh`, mock and `--real`), Helm chart tests.
- GitHub: `davidbejar/hoops-academy` (public), branch `main`. Repository variable `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`;
  secret `NVD_API_KEY` (currently rejected by NVD as invalid, see below).
- CI on `origin/main`: `ci` green except `dependency-check` (see below); `e2e` green on the runner's Podman stack; `images`
  green end to end — the four images are published to `ghcr.io/davidbejar/hoops-academy/{core-service,game-service,athlete-service,web}:<sha>`
  (verified 2026-11-02 after the orphan `REGISTRY_USERNAME` secret was removed). Packages are created private: make them
  public in the package settings or set `global.imagePullSecrets` (runbook release.md §3) before a cluster pulls them.

## Pending
1. `dependency-check`: the NVD key is valid since 2026-11-02 (first full NVD download ran ~3 h; the job now caches the NVD data
   with split restore/save steps so later runs take minutes). The first real scan flagged `quarkus-flyway-postgresql` against
   PostgreSQL *server* CVEs, a CPE false positive, suppressed in `.dependency-check-suppressions.xml` (until 2027-05-01).
   Verify that the next `ci` run's dependency-check job is green; if NVD answers 503 again, rerun the job (data is cached).
2. Make the ghcr.io packages public (or configure a pull secret) before deploying to a cluster that pulls from ghcr.io.
3. Decide security finding F-01 (parents/players reading the full match event feed), `docs/security/review-2026-11.md`.

## Working conventions learned the hard way
- Two Claude sessions worked in this checkout at once on 2026-11-02 and one switched branches under the other. If more than one
  session works on the repo, give each its own `git worktree` **under `$HOME`** (the Podman machine cannot see `/tmp`), and push
  with `git push origin <branch>:main` instead of switching branches in a shared checkout.
- Commit with `gitleaks protect --staged` first and `git commit --no-verify` (the pre-commit stash conflicts with concurrent
  edits); never `git add -A` when another session may have files in flight.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH
  (Homebrew cask is disabled; download from Chrome for Testing and `xattr -d com.apple.quarantine`).
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/baseline.conf` with `[alert=..][url=..]` scoping (`scripts/zap-gate.py`).
- Realm changes need a Keycloak re-import: `just down && podman volume rm hoops_pgdata && just up && just seed-users`.

## Next candidates (see FOLLOW-UPS.md for the full list)
- Keycloak CSP hardening via realm `browserSecurityHeaders` (removes the accepted ZAP alerts under `/auth/realms/`).
- Run the e2e journey on kind; Lighthouse installability and airplane-mode cold start for the PWA; chromedriver in CI.
- Source the remaining fitness norms (120 of 628 rows cited); PLAYER's own box-score line; REJECTED player label.
- v2: outbox + Redpanda (WP19), billing module on the existing seams, data purge job.
