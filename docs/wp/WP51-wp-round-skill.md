# WP51 — `wp-round` skill: how a round of work packages is planned and run

Model: Opus. Wave 3 (2026-11-06, third round): starts after WP44 is merged; runs alongside WP47 (apps/web). You own
`.claude/skills/wp-round/*`, `.claude/skills/work-package/SKILL.md`, `CLAUDE.md` and the "Working conventions"
section of `docs/HANDOVER.md`; nothing else. Depends on: nothing. Skills: verification-before-completion. Worktree:
`~/code/hoops-wt/wp51-wp-round-skill`, branch `wp51-wp-round-skill`.

Decision 33 of 2026-11-06: the orchestration procedure (interview, briefs, waves, models, merge protocol, docs pass)
becomes a project skill, so a fresh session runs a round the same way. Split rule: CLAUDE.md holds facts and rules
true for every change (one line per skill saying when to invoke it); skills hold procedures; HANDOVER and FOLLOW-UPS
hold state; memory holds what is not derivable from the repo.

## Scope
1. **`.claude/skills/wp-round/SKILL.md`** (front matter `name`, `description` with the trigger: planning or running a
   round of work packages, or interviewing the owner about open items; body at most ~120 lines; procedures, not
   prose). Sections, in this order:
   - *Interview*: sources are the Open section of `docs/wp/FOLLOW-UPS.md` and the "Open points" of the latest
     handovers; one question per decision, recommended option first, at most four questions per call; answers are
     written as numbered, dated decisions in FOLLOW-UPS (continuing the numbering) before any brief exists; a wave
     plan table follows them (Wave, WP, Title, Model, Status).
   - *Briefs*: `docs/wp/WP<n>-<slug>.md` from `brief-template.md` (see 2); ADR numbers reserved in the brief
     (parallel WPs collided on 0025–0028 before this rule); explicit file ownership per WP; the known shared files and
     their append rule (`apps/web/lib/l10n/*.arb`: next to the feature's keys; `docs/adr/README.md`,
     `docs/domain/authz-matrix.md`, `libs/contracts/.../UpdateRequestClearListContractTest`: append at the end, one
     entry per line; `apps/web/pubspec.lock`: commit it with a generated-package version bump).
   - *Waves*: disjoint file areas per wave (service, contract+package, chart/kind, web feature, workflows); a WP that
     needs another's contract goes in the next wave; one kind user per wave; whole-tree passes (formatting,
     renames) run alone and last; a docs agent at the end owns README, HANDOVER, FOLLOW-UPS, conformance, roadmap,
     architecture, the ADR index.
   - *Models*: Opus for security, tenancy, contracts, production Java and infra proven on kind; Sonnet for routine
     web, docs, pins and mocks; never above Opus; the docs pass on Opus.
   - *Mechanics*: `git worktree add -b <wp> ~/code/hoops-wt/<wp> main` (under `$HOME`: the Podman machine cannot see
     `/tmp`); agent prompt = brief path + skills to apply + who else is running and what they own; on report: rebase
     onto main, re-verify only when the combined tree was never built (another WP of the same area landed meanwhile),
     `git merge --ff-only`, push, watch CI with a monitor, `git worktree remove --force` (agents copy the git-ignored
     `.env`), delete the branch. Push after every merge, not only per wave.
   - *Traps*: an OpenAPI-generator bump yields whitespace-only diffs that the pre-commit hooks strip (discard them);
     resolve index conflicts keep-both; never chain `git rebase … | tail` with `&&` (the pipe hides the conflict exit
     code); agents may not edit the orchestrator's files and must say so in their handover instead; the Podman VM
     clock drifts after host sleep (the hooks resync it; by hand `podman machine ssh "sudo date -u -s @$(date +%s)"`);
     agents' commit trailers name the model that did the work unless the brief fixes the line.
   - *Close-out*: the docs-pass checklist (FOLLOW-UPS plan statuses and resolved/open items; HANDOVER state, pending,
     lessons; README status; conformance; roadmap; architecture; ADR index links; CI state observed with `gh`), push,
     memory note.
2. **`.claude/skills/wp-round/brief-template.md`**: the brief skeleton used by WP38–WP50 (header line with model,
   wave, dependencies, skills, worktree and branch; the decision line; Scope; Acceptance checkboxes; the Working rules
   block verbatim from `docs/wp/WP44-core-clear-list.md`; empty Handover placeholder).
3. **`.claude/skills/work-package/SKILL.md`**: under "During" add the shared-file append rule and "do not reformat
   files you did not change"; under "Finish" add "final report to the orchestrator, at most 300 words".
4. **`CLAUDE.md`**: the "Work packages" convention bullet gains "execute one with `.claude/skills/work-package`;
   plan and run a round with `.claude/skills/wp-round`". No other addition; the file stays one page.
5. **`docs/HANDOVER.md`** "Working conventions learned the hard way": keep the environment facts a person needs
   (hook behaviour, `flutter drive` flag, realm re-import, clock drift, actionlint/goldens/ZAP lines); replace the
   three orchestration bullets (worktree wave flow, parallel-WP lessons, `--no-verify` reasoning) with one pointer
   line to the skill. Do not touch the State, Pending or Next sections (the docs pass owns them).
6. Read first: `docs/wp/WP38`…`WP50` briefs and handovers (what the Working rules looked like, what went wrong),
   `docs/wp/FOLLOW-UPS.md` decisions 12, 24–32, the memory rule is not in the repo so take the model rule from this
   brief.

## Acceptance
- [ ] Skill front matter valid (quoted description), body ≤ ~120 lines, template separate; `CLAUDE.md` diff is one
      bullet; HANDOVER section shorter than before with no fact lost (list what moved where in the handover)
- [ ] Every path and command named in the skill exists (`ls`/`grep` evidence in the handover)
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits (`docs(skills): …`). A Claude Code hook runs a ~40 s tenant-isolation test before every
  commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it. End every commit message
  with the line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/wp/FOLLOW-UPS.md, or any part of docs/HANDOVER.md outside the section named above.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built (commit 8805980):
  - `.claude/skills/wp-round/SKILL.md` (86 lines, body 82): front matter `name` + quoted `description` (trigger:
    planning or running a round, interviewing the owner); sections Interview, Briefs, Waves, Models, Mechanics, Traps,
    Close-out in the brief's order. Traps also carry this round's lessons: keep-both for the `ADOPTED` constant and
    ADR adoption bullets, `git worktree remove --force` because of the copied `.env`, re-verify (full verify plus
    `flutter test`) only when a merged tree combines two WPs of the same area. Added beyond the brief: `just gen-api`
    regenerates every package, commit only your own (WP39/WP44/WP45 handovers); briefs and decisions are committed on
    `main` before the worktrees (practice of 6042547 / 513f9ba).
  - `.claude/skills/wp-round/brief-template.md` (37 lines): header line, decision line, Scope, Acceptance, Working
    rules, Handover placeholder. Working rules are byte-identical to WP44 (`diff` of the two blocks: no output).
  - `work-package/SKILL.md` (34 → 39 lines): During gains the shared-file append rule and "do not reformat files you
    did not change"; Finish step 4 is "Final report to the orchestrator, at most 300 words".
  - `CLAUDE.md` (65 → 66 lines): only the "Work packages" bullet changed (pointer to both skills).
  - `docs/HANDOVER.md` "Working conventions" 30 → 20 lines (bullets 27 → 17); no other section touched.
- Moved from HANDOVER to the skill: bullet "Two Claude sessions…" (worktree under `$HOME`, `/tmp` invisible to
  Podman, `git push origin <branch>:main`, no branch switching) → Mechanics 1; "Commit with gitleaks…" (`--no-verify`
  because the pre-commit stash conflicts with concurrent edits, never `git add -A`) → Mechanics 3 and the template;
  "Worktree wave flow" (one worktree and branch per WP, rebase, rerun checks, `--ff-only`, shared docs owned by one
  agent) → Mechanics 4, Waves; "Parallel WPs, lessons of WP38–WP42" (ADR numbers up front, disjoint ownership,
  dependent contract in the next wave, index conflicts) → Briefs, Waves, Traps. Dropped as history only: the
  2026-11-02 incident date and "0032 and 0033 were fixed before the wave". Replaced by one pointer line. Kept: hook,
  `flutter drive`, actionlint/goldens/ZAP, realm re-import, clock drift (the clock command is also in Traps).
- Verified: every path in the skill exists (`ls -d` on FOLLOW-UPS, HANDOVER, the template, ADR README, authz matrix,
  `UpdateRequestClearListContractTest.java` (3 `ADOPTED` hits), `pubspec.lock`, three `.arb`, conformance, roadmap,
  architecture, `scripts/gen-api.sh`, `scripts/hooks/_common.sh`, `~/code/hoops-wt`); `just --summary` lists
  `gen-api`, `mutation`, `test`, `web-test`; `git worktree add -b`, `git merge --ff-only`, `git worktree remove
  --force`, `git branch -d`, `gh run list -b/-L`, `gh run watch --exit-status` confirmed from `-h`; front matter
  parses (Ruby YAML: keys name, description). Commit passed the isolation hook and gitleaks.
- Not run: `just test` / `flutter test` (no code, contract or web file changed). The Monitor tool is named as the
  orchestrator's tool, not checkable from a shell.
- Open points: the "Next candidates" and State sections of HANDOVER are left to the docs pass; FOLLOW-UPS plan row
  for WP51 needs its Status set by the orchestrator.
