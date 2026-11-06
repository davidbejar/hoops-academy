# WP50 — GitHub Actions pinned to commit SHAs

Model: Sonnet. Wave 1 (2026-11-06, third round): runs alongside WP43 (Java), WP46 (deploy/) and WP48 (web); you own
`.github/workflows/*.yml`, `.github/dependabot.yml` and `docs/security/*` lines about the pipeline. Depends on:
Dependabot PR #1 (merged: the actions are at their current majors). Skills: owasp-security,
verification-before-completion. Worktree: `~/code/hoops-wt/wp50-actions-sha`, branch `wp50-actions-sha`.

Decision 31 of 2026-11-06: every third-party action is pinned to a full commit SHA with the version as a comment
(`uses: actions/checkout@<40-hex> # v7.0.0`), so a moved tag cannot change what CI runs. Dependabot keeps the SHAs
current (it updates the SHA and the comment together).

## Scope
1. Resolve each `uses:` in `ci.yml`, `e2e.yml`, `images.yml`, `mutation.yml` to the commit of its current release
   tag with the GitHub API (`gh api repos/<owner>/<repo>/git/ref/tags/<tag>`; dereference annotated tags with
   `git/tags/<sha>` to the commit), never from memory; record the tag → SHA table in the handover.
2. Replace `@vN` with `@<sha> # <exact tag>`; keep container image refs (`aquasec/trivy:0.76.1`) as they are.
3. `actionlint` clean; `zizmor` if installed (say if not). Push nothing: the orchestrator's push runs the workflows;
   check nothing in the workflows depends on the major tag (e.g. `cache` restore keys).
4. Docs: `docs/security/asvs-checklist.md` / `review-2026-11.md` supply-chain row; release runbook one line;
   `.github/dependabot.yml` comment that it maintains the SHAs.

## Acceptance
- [ ] Every `uses:` is a 40-hex SHA with a version comment; table in the handover
- [ ] `actionlint .github/workflows/*.yml` clean
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits (`chore(ci): …`). A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the
  line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
