# WP64 — CI: NVD cache saved on success only, dependency-check findings reviewed

Model: Sonnet. Wave 1 (2026-11-06, fourth round): runs alongside WP52, WP56, WP58, WP60, WP63. You own the
`dependency-check` job of `.github/workflows/ci.yml` (nothing else in the file; WP55 edits the flutter job in
wave 2), `.dependency-check-suppressions.xml`, `docs/security/review-2026-11.md` dependency rows. Depends on: the
HANDOVER note on the NVD cache. Skills: owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp64-ci-nvd`, branch `wp64-ci-nvd`.

Decision 46 of 2026-11-06: a failed or cancelled dependency-check run must not poison the NVD cache; the findings
below the CVSS 7 gate are reviewed once and either suppressed with a reason and expiry or listed as accepted.

## Scope
1. `Save NVD data` runs only when the dependency-check step succeeded (`if: success()` or a step outcome check),
   while the report upload keeps `if: always()`; the restore keys unchanged. `actionlint` clean.
2. Download the latest `dependency-check-report` artifact from a green `ci` run on `main` (`gh run download`), read
   the JSON, list every finding (CVE, CVSS, dependency, path); for each one: false positive (CPE mismatch →
   suppression with `<notes>` reason and `until` ≤ 6 months) or real but below the gate (record in the review file
   with the upgrade path, no suppression). No suppression for a real vulnerability.
3. `docs/security/review-2026-11.md`: a "Dependency findings 2026-11-06" table (you own it).

## Acceptance
- [ ] `actionlint .github/workflows/ci.yml` clean; the cache step condition proven by reading the workflow logic (the
      run itself happens after the orchestrator's push; name the job to watch)
- [ ] Findings table complete; suppressions validated by a local `./mvnw -Psecurity-scan dependency-check:aggregate`
      if the NVD key is available locally (`NVD_API_KEY` in `.env`?), else say it was not run
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits (`ci: …`, `chore(security): …`). A Claude Code hook runs a ~40 s tenant-isolation test
  before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it. End every
  commit message with the line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
