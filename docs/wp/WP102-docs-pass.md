# WP102 — Docs pass of the sixth round

Model: Opus · effort medium. Wave 5 (2026-11-10, sixth round): runs alone, last, after WP91–WP101 and WP103 are
merged. You own README.md, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`,
`docs/architecture.md`, `docs/adr/README.md` (order and links), `docs/guides/*` (es / en / id). You change no code.
Depends on: every handover of this round (`docs/wp/WP91-*.md` … `WP103-*.md`), the close-out checklist of the
`wp-round` skill. Skills: wp-round (Close-out), verification-before-completion. Worktree:
`~/code/hoops-wt/wp102-docs-pass`, branch `wp102-docs-pass`.

## Scope
1. **FOLLOW-UPS**: the sixth-round plan table statuses (ask the orchestrator for merge commits you cannot derive
   from `git log`); every resolved Open item moved to Resolved with its WP; new Open items from the handovers' open
   points, grouped as the file groups them; the header paragraph mentions the sixth round.
2. **HANDOVER**: State (merge order with commits, contract and chart versions, test totals from the last full
   verify, mutation scores), Pending user actions (still true ones only), Working conventions (environment facts
   only, including the test academy and `just seed-academy`, `just events-drift`, `just diagrams`, `just
   test-hooks`), Next candidates.
3. **README, conformance, roadmap, architecture**: replica as the default roster source (diagram and text),
   exports, the exercise catalogue, the application admin hub and context switcher, jersey numbers; links to the
   three `docs/domain/*-model.md` pages; ADR index 0047–0049 and the amendments in order.
4. **User guides** (`docs/guides`, three languages each): super admin (hub, Users, contexts), admin (exports,
   jersey numbers, own name), coach (exercise catalogue, quick-add, exports, jersey), parent and player (jersey
   wish, own name, calendar export). Use the handovers; do not describe what was not built.
5. **CI state**: `gh run list -b main -L 10` with the run ids of the last push in HANDOVER.

## Acceptance
- [ ] Every item of the skill's close-out list that is a document is done; the orchestrator does the push, the
      memory note and `caffeinate`
- [ ] No broken relative link in the files you touched (check them with a script)
- [ ] Final report: what you could not confirm from the handovers

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
