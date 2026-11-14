---
name: wp-round
description: "How the orchestrator plans and runs a round of Hoops Academy work packages: owner interview, numbered decisions, briefs, waves, model choice, worktree and merge protocol, docs pass. Use when planning or running a round of work packages, or when interviewing the owner about open items."
---

# Running a round of work packages

The orchestrator plans, briefs, merges and pushes; agents execute one WP each with the `work-package` skill.
State lives in `docs/wp/FOLLOW-UPS.md` and `docs/HANDOVER.md`; this skill is only the procedure.

## Interview
1. Sources: the Open section of `docs/wp/FOLLOW-UPS.md` and the "Open points" of the latest handovers
   (`docs/wp/WP<n>-*.md`).
2. One question per decision, recommended option first; at most four questions per call.
3. Before any brief exists, write the answers into FOLLOW-UPS as numbered, dated decisions, continuing the numbering
   (`### Decisions of <date>, <interview>`; `<N>. **<Topic>** → WP<n>: …`).
4. Below them a `## Plan (<date>, <round>)` paragraph and a table `| Wave | WP | Title | Model | Status |`
   (Status: Running, After wave <w>, Last alone, Done (<ADR; versions>)).

## Briefs
- One file `docs/wp/WP<n>-<slug>.md` per WP, from `brief-template.md` next to this skill. Keep the Working rules
  block as it is; add a rule only for the WP's own risk (kind cluster size, no `dart format`).
- Reserve ADR numbers in the briefs (parallel WPs collided on 0025–0028 before this rule).
- Name the file ownership explicitly: what the WP owns, what nobody else touches, which shared file it appends to.
- Shared files and their append rule (write it into every brief that touches one):
  - `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
  - `docs/adr/README.md`, `docs/domain/authz-matrix.md`,
    `libs/contracts/src/test/java/com/hoopsacademy/contracts/UpdateRequestClearListContractTest.java`: append at the
    end, one entry per line; the owner of the file says where the other WP's line goes.
  - `apps/web/pubspec.lock`: commit it only with a generated-package version bump; revert other drift.
- Commit the briefs, the decisions and the plan table on `main` before creating any worktree.

## Waves
- One wave = disjoint file areas: a service, a contract plus its Dart package, the chart / kind, one web feature,
  the workflows. Two WPs never own the same file.
- A WP that needs another WP's contract or mock goes in the next wave.
- At most one kind (cluster) user per wave.
- Whole-tree passes (formatting, renames) run alone, last, after every other change in their area.
- The docs agent runs at the end and alone owns README, HANDOVER, FOLLOW-UPS, `docs/conformance.md`,
  `docs/roadmap.md`, `docs/architecture.md` and the ADR index; WP agents write their notes in their own handover.

## Models
- Opus: security, tenancy, contracts, production Java, infra proven on kind, the docs pass.
- Sonnet: routine web, docs, version pins, mocks.
- Never above Opus for an agent. Write the model in the brief header and pass it on the agent call.

## Mechanics
0. Keep the Mac awake for the whole round: `caffeinate -dims -t 28800 &` (8 h; note the pid) before the first agent
   starts. Host sleep stalls the Podman VM clock (tokens look expired, hooks time out) and suspends the agents' builds.
   Kill it at close-out. The same applies to any long single task (full verify, kind proofs, mutation runs).
1. Per WP: `git worktree add -b <wp-slug> ~/code/hoops-wt/<wp-slug> main` (under `$HOME`: the Podman machine
   cannot see `/tmp`). Never switch branches in a shared checkout; a session without the main checkout pushes with
   `git push origin <branch>:main`.
2. Agent prompt: the brief path, the skills to apply, who else is running and what they own.
3. Agents commit with `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths: the pre-commit
   stash conflicts with concurrent edits, and the Claude Code hook (isolation check) still runs.
4. On a report:
   1. In the worktree, `git rebase main`; check its exit status and `git status` (see Traps).
   2. Re-verify only when the combined tree was never built, i.e. another WP of the same area landed since the
      branch was cut: `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` plus
      `cd apps/web && flutter test`. Otherwise the agent's fresh results stand.
   3. In the main checkout, `git merge --ff-only <wp-slug>` on `main`, then `git push` (after every merge, not
      once per wave).
   4. Watch CI with the Monitor tool (`gh run list -b main -L 5`, `gh run watch <id> --exit-status`).
   5. `git worktree remove --force ~/code/hoops-wt/<wp-slug>`, `git branch -d <wp-slug>`.
   6. Update the Status cell in the FOLLOW-UPS plan table; start the next WP of the wave or the next wave.

## Traps
- An OpenAPI generator bump yields whitespace-only diffs in the Dart packages that the pre-commit hooks strip:
  discard them. `just gen-api` regenerates every package; commit only the WP's own (`scripts/gen-api.sh <svc>`).
- Rebase conflicts in index files (ADR README, roadmap, runbook lists), in a shared test's list constant
  (`ADOPTED` in `UpdateRequestClearListContractTest`) and in an ADR's adoption bullets: resolve keep-both.
- Never chain `git rebase … | tail` with `&&`: the pipe hides the conflict's exit code.
- `git worktree remove` needs `--force`: agents copy the git-ignored `.env` into their worktree.
- Agents may not edit the orchestrator's files (README, HANDOVER, FOLLOW-UPS); they say what is needed in their
  handover and the docs pass applies it.
- The Podman VM clock drifts after host sleep and Keycloak tokens look expired. The hooks resync it; by hand:
  `podman machine ssh "sudo date -u -s @$(date +%s)"`.
- Action pins: a release tag may be an annotated tag object; `git/ref/tags/<tag>` then returns `type: tag` and the
  pin must be the dereferenced commit (`git/tags/<sha>.object.sha`). Actions cannot check out a tag object SHA
  (WP55 pinned one; the orchestrator's spot-check caught it).
- Hook under load: with five or more parallel builds the isolation check's Keycloak container can miss its 120 s
  wait and the commit is blocked; retry when a build finishes instead of bypassing.
- `git commit --no-verify` (Mechanics 3) is refused by the session's permission check since the seventh round:
  agents commit with plain `git commit` and explicit paths after `gitleaks protect --staged`; the pre-commit hooks
  run and may trim trailing whitespace in generated Dart files (re-add, commit again). Say so in the agent prompt.
- Commit trailers: a brief that fixes the `Co-Authored-By` line gets that line from every model (WP38, WP41 noted
  it); drop the line from the brief to have agents name the model that did the work.

## Close-out (docs pass)
- [ ] FOLLOW-UPS: plan table statuses, resolved items moved to Resolved with their WP, new open items from the
      handovers' Open points.
- [ ] HANDOVER: State (merge order with commits, contract and chart versions, test totals), Pending, Working
      conventions (environment facts only), Next candidates.
- [ ] README status, `docs/conformance.md`, `docs/roadmap.md`, `docs/architecture.md`, `docs/adr/README.md` links.
- [ ] CI state on `main` observed with `gh run list -b main` (run ids in HANDOVER).
- [ ] Push; update the orchestrator's memory note (progress, what the repo cannot derive).
- [ ] `kill` the `caffeinate` started in Mechanics 0.
