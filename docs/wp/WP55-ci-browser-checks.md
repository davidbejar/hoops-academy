# WP55 — CI: browser smoke and login round trip on the runner

Model: Sonnet. Wave 2 (2026-11-06, fourth round): starts after WP64 is merged (it edits `ci.yml` too); runs
alongside WP53 (`apps/web/lib`), WP57, WP59, WP61, WP65. You own `.github/workflows/ci.yml` (flutter job only),
`.github/workflows/e2e.yml` if the login check fits there better, and `apps/web/tool/*`; nothing under
`apps/web/lib`. Depends on: WP35 (`web_smoke.sh`), WP25 (`browser_login_check.py`). Skills: verification-before-
completion, systematic-debugging. Worktree: `~/code/hoops-wt/wp55-ci-browser`, branch `wp55-ci-browser`.

Decision 37 of 2026-11-06: the browser-level checks run in CI, not only on the owner's Mac.

## Scope
1. **Mock-mode smoke in `ci.yml`**: a step in the flutter job (or a new `web-browser` job) that installs Chrome for
   Testing + matching chromedriver (pinned version; `browser-actions/setup-chrome` or a direct download with
   checksum, pinned to a SHA like the other actions), builds the web app and runs `apps/web/tool/web_smoke.sh` in
   mock mode headless. Runtime recorded.
2. **Login round trip in `e2e.yml`**: after the compose stack is up, `apps/web/tool/browser_login_check.py
   --set-new-password` against the stack (the first-sign-in flow); artifacts (screenshots/logs) uploaded on failure.
3. Both scripts headless-capable (`--headless` flag or env) without changing their local behaviour; `actionlint`
   clean; all new `uses:` pinned to a commit SHA with the version comment (WP50 rule).
4. `docs/runbooks/e2e.md` and the web runbook: the CI steps and how to reproduce locally.

## Acceptance
- [ ] `actionlint .github/workflows/*.yml` clean; workflows green after the orchestrator's push (note that it is the
      orchestrator's step; include the exact job names to watch)
- [ ] Local: `web_smoke.sh` and `browser_login_check.py` still green in headless mode (evidence)
- [ ] Handover appended with runtimes and the pinned Chrome/chromedriver versions

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits (`ci: …`). A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it
  resyncs the Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the
  line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- No Node on the host or in CI steps you add.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built: `ci.yml` job `web-browser` (flutter-action + setup-chrome v2.2.0 pinned SHA, Chrome for Testing and chromedriver
  157.0.8103.38, `web_smoke.sh` mock mode headless, runtime written to the step summary). `e2e.yml` job `journeys`: flutter
  + Chrome steps and "Browser login round trip" running new `apps/web/tool/ci_login_check.sh` (temporary-password user via
  kcadm, release build on :5173, `browser_login_check.py --set-new-password`); screenshot/URL saved by the check to
  `HOOPS_E2E_ARTIFACT_DIR` and uploaded with `e2e-reports`. Both scripts were already headless (`flutter drive` defaults to
  headless, the login check only opens a window with `--headed`), so no flag was needed. Runbook section in `docs/runbooks/e2e.md`
  (the web runbook is that file's "Browser smoke" section).
- Verified: `actionlint .github/workflows/*.yml` clean. Local `tool/web_smoke.sh` (mock, headless default, chromedriver 156):
  "All tests passed", about 78 s. `browser_login_check.py` only syntax/`--help` checked: the compose stack was down (WP56 owns
  it), so `ci_login_check.sh` and the login check were NOT run live.
- Decisions/ADRs: none. CI Chrome 157.0.8103.38 (stable at 2026-11-05) differs from the local chromedriver 156; pin is per workflow.
- Open points: orchestrator to push and watch jobs `web-browser` (ci.yml) and `journeys` (e2e.yml, step "Browser login round
  trip"); the login step is unproven (build served by python http.server on :5173, API CORS to :8080 untested, `kc` quoting).
  CI runtimes to be read from the step summaries after the first run.
