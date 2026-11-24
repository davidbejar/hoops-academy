# WP147 — Docs: docs pass of the tenth round

Model: Opus · medium. Wave 4 (2026-11-24, tenth round): starts after every other package is merged and runs alone. You
own README, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`,
`docs/architecture.md`, the ADR index, `CLAUDE.md` and the skills where the round made them wrong. Depends on:
WP142–WP146. Skills: work-package, wp-round (Close-out), verification-before-completion. Worktree:
`~/code/hoops-wt/wp147-docs-pass`, branch `wp147-docs-pass`.

Decisions 114–118 of 2026-11-24. No ADR.

## Scope
1. **Close-out**: the `wp-round` skill's checklist: FOLLOW-UPS (plan statuses, the round's resolved items moved to
   Resolved with their package: PostgreSQL 19, the fresh-volume bootstrap, the trigram index, database spans, the kind
   install under load, the shell tests outside CI, the outdated pins; new open items from the handovers), HANDOVER
   (state, versions, totals labelled with their source, environment facts), README, conformance, roadmap,
   architecture, ADR index.
2. **Version lines**: every doc, skill and runbook that says PostgreSQL 17 as the current version says what was
   adopted (historic mentions in `docs/PLAN.md`, old briefs and ADRs stay).
3. **CI**: record the runs you observe with `gh run list -b main`; claim green only for what you saw.

## Acceptance
- [ ] `just docs-build` (strict) and `python3 -I -m unittest discover -s scripts/tests` green
- [ ] Every factual line comes from a handover, the code, `git log` or `gh`; unverifiable numbers are attributed
- [ ] Red tests committed before each change
- [ ] Handover appended: what was built, fresh verification with totals, what was not run, open points

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
- Do not read, copy or print any `.env`. The compose stack that is running is the owner's: do not `just down` it, do
  not remove or recreate its volumes. What needs the real stack or the owner's database comes back "not run" in the
  handover; the orchestrator runs it from the main checkout at merge time.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
