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
2026-11-14, Opus · medium. Documentation only (81934697).

- **Built.** `docs/HANDOVER.md`: State (pre-round commits c8ae9580, 51f2dd0c, 28a02264, de481062; merge order WP105,
  WP107, WP104, WP106, WP108 with their commits; WP109 on `jdk-25` at 83024d44 / 36e2abbf / 77fe32fe, draft PR #7;
  core 3.6.0, game 2.3.0, athlete 3.0.0, common 1.1.1; chart 0.10.0; test totals from the handovers; CI run ids),
  Pending (images red on `krb5-libs`, the first `tofu apply` and what the owner prepares, PR #7, the older items),
  Working conventions (`--no-verify` refused, Flutter 3.50 / `material_ui`, OpenTofu and `openjdk@25` from Homebrew,
  the demo-seed switches), Next candidates (apply, observability backend, landing screenshots). `docs/wp/FOLLOW-UPS.md`:
  header, plan intro, WP110 Done; theme, demo data, former-coach export, families' catalogue, `/me` names and the cloud
  first slice moved to Resolved (seventh round); new open items: images red, tofu apply, PR #7, cloud slice unproven,
  observability backend, demo-data leftovers, chooser without avatar menu, audit-events wording, landing screenshots
  extended. README status, `docs/conformance.md` (reconciliation paragraph, S-02, S-04, S-37, U-01, R-14, baseline;
  count unchanged 55/7/5/0/2), `docs/roadmap.md`, `docs/architecture.md` (cloud in section 2, ADR-0050 in section 8,
  counts in 11, section 13; 13 sections kept), ADR index (0048 amendment). Guides es/en/id for all five roles: avatar
  menu with language and theme, profile with name and sign-out, catalogue for parents and players, roster export for
  the current coach only, the name form from `/me`.
- **Verified.** Facts from the WP104–WP109 handovers and `git log` / `git show` on `main` (commit messages of the
  pre-round commits; 189 Dart files in 51f2dd0c), versions from `core.yaml` etc., `Chart.yaml`, `pom.xml`, the ARB
  files and `seed-academy.sh` (24 logins: 2 admins, coach, assistant, 10 players, 10 parents); PR #7 head and draft
  state with `gh pr view`; local `flutter --version` 3.50.0, `tofu version` 1.13.9, `brew list` openjdk@25 25.0.5.0.2.
  CI: `gh run list -b main`: f59c7f85 `ci` 43616396634, `e2e` 43616396516, `codeql` 43616396630, `semgrep` 43616396569
  green; `images` 43614386564 on 3822faf2 red, its log "Total: 14 (HIGH: 14, CRITICAL: 0)", `krb5-libs`.
  `just diagrams-check`: "model-diagrams: pages up to date". Relative links in every changed page resolve (script).
- **Decisions/ADRs.** None.
- **Open points.** Not confirmed: the orchestrator's 3,379 tests for the Quarkus bump (no log in the repository; taken
  as given); per-module JVM counts of this round (the handovers report totals only). The guides were written from the
  ARB files and the code, not a browser walk-through. `docs/domain/audit-events.md` wording (WP106) and the skill
  files' `--no-verify` instruction were left as they are (not mine to edit). The commit ran the pre-commit hooks (plain
  `git commit`, `--no-verify` not used).
