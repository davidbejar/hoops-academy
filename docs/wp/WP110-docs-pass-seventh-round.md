# WP110 — Docs pass (seventh round)

Model: Opus · effort medium. Wave 3 (2026-11-14, seventh round): starts after WP104–WP108 are merged and the
`jdk-25` pull request is open; runs alone, in the main checkout's line of history (worktree
`~/code/hoops-wt/wp110-docs-pass`, branch `wp110-docs-pass`). You alone own `README.md`, `docs/HANDOVER.md`,
`docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`, `docs/architecture.md`, `docs/adr/README.md`
(links and order) and `docs/guides/*`. You change no code. Depends on: the handovers of WP104–WP109, decisions
75–85, the `wp-round` skill's close-out list. Skills: verification-before-completion.

## Scope
1. **FOLLOW-UPS**: the plan table statuses as the orchestrator left them; the items closed by this round moved to
   Resolved with their WP; the new open items from each handover's Open points; the header paragraph names the round.
2. **HANDOVER**: State (merge order with commits, contract and chart versions, test totals as the handovers report
   them), Pending user actions (the real `tofu apply` and what the owner prepares for it; the `jdk-25` pull request
   and what to look at before merging), Working conventions (environment facts only: Flutter 3.50 and `material_ui`,
   OpenTofu), Next candidates (the cloud slice's next steps, the observability backend, the landing screenshots).
3. **README, conformance, roadmap, architecture**: the cloud module and its limits (code only, not applied), the
   theme choice, the Test Academy's demo data, the export rule, `/me` names, the catalogue for families.
   `docs/architecture.md`: section 10 (domain model) stays; add what the round changed.
4. **User guides** (`docs/guides/*.{es,en,id}.md`): where language and theme are chosen now; the catalogue for
   parents and players; what the WP105 and WP108 handovers ask for.
5. **Diagrams**: `just diagrams-check`; regenerate only if a handover says a model changed.

## Acceptance
- [ ] Every statement about a version, a count or a commit is taken from a handover or checked in the repository
- [ ] `just diagrams-check` green; links in the changed pages resolve
- [ ] CI state on `main` observed with `gh run list -b main` (run ids in HANDOVER)
- [ ] Handover appended with what could not be confirmed

## Working rules
- Work only in your worktree on your branch; do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected.
  End every commit message with a `Co-Authored-By:` line that names the model you are.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
