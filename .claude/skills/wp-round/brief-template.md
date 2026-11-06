# WP<n> — <Area>: <title>

Model: <Opus|Sonnet>. Wave <w> (<yyyy-mm-dd>, <round>): <runs alongside WP<a> (<area>) | starts after WP<b> is
merged>. You own <paths>; <nobody else touches them | the shared file X: append at the end, one entry per line>.
`apps/web/lib/l10n/*.arb`: add keys next to the related feature's keys, never at the end of the file. Depends on:
<WPs, ADRs | nothing>. Skills: <skill, skill, verification-before-completion>. Worktree:
`~/code/hoops-wt/<wp-slug>`, branch `<wp-slug>`.

Decision <N> of <yyyy-mm-dd>: <the owner's decision in one or two sentences; ADR-<nnnn> reserved for you if one is
needed>.

## Scope
1. **<Part>** (<files>): <what to build; the version bump; which tests come first>.
2. **<Part>**: <…>.
3. **Docs**: <ADR line, runbook, authz matrix row; only files you own>.

## Acceptance
- [ ] <Contract x.y.z validated; Dart package regenerated and committed (only yours)>
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [ ] <`just mutation <module>` at or above baseline (record the score)>
- [ ] Handover appended with <what the orchestrator needs to know>

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
