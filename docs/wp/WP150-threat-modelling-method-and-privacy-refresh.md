# WP150 — Security docs: the threat-modelling method (ADR-0077), the privacy model refresh, the keep-current rule

Model: Opus · medium. Wave 1 (2026-11-28, eleventh round): runs alongside WP148 (STRIDE refresh; owns
`docs/security/threat-model.md`) and WP149 (agentic threat model; owns `docs/security/agentic-threat-model.md`). You
own `docs/adr/0077-threat-modelling-methods.md`, the ADR index line in `docs/adr/README.md` (append at the end),
`docs/security/privacy-threat-model.md`, the Definition of Done paragraph of `CLAUDE.md` and the Close-out list of
`.claude/skills/wp-round/SKILL.md`; nobody else touches those in this wave. Depends on: nothing. Skills:
work-package, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp150-threat-modelling-method-and-privacy-refresh`, branch
`wp150-threat-modelling-method-and-privacy-refresh`.

Decisions 119 to 122 of 2026-11-28 (FOLLOW-UPS): which threat-modelling method is used for what. ADR-0077 is
reserved for you.

## Scope
1. **ADR-0077**, in the form of the existing ADRs: the methods and what each is used for.
   - STRIDE per trust boundary for the product (`threat-model.md`).
   - LINDDUN per trust boundary for privacy (`privacy-threat-model.md`), same boundary numbers.
   - From PASTA only two parts: the rating (likelihood and impact Low, Medium or High as 1, 2, 3; product 6 or 9
     High, 3 or 4 Medium, 1 or 2 Low; likelihood for the project as exposed today, impact as if a real academy's
     data were in it) and attack chains for the top assets. The full seven stages are too heavy for this project.
   - From VAST only its idea that the model is kept current inside delivery: the rule of part 3.
   - MAESTRO for the agent-driven build system (`agentic-threat-model.md`); the product has no AI.
   - Not used, with the reason: Trike (its actor, asset and action matrix is what `docs/domain/authz-matrix.md`
     already is, and tests enforce it) and OCTAVE (organisational risk workshops; one owner).
   - Consequences: three documents, one rating scale, finding ids `F-` (review), `P-` (privacy), `TM-` (STRIDE),
     `AG-` (agentic).
2. **Privacy model refresh**: sections 9 and 10 are headed "planned" for pdf-service and finance-service, which are
   built. Re-check both against the code and rewrite them as built (evidence as the other sections give it); check
   the status sections and the findings table for claims the tenth round changed (PostgreSQL 19, database spans in
   traces: ADR-0073, ADR-0074) and correct them. New privacy findings continue the `P-` numbering.
3. **Keep-current rule**: one clause in `CLAUDE.md`'s Definition of Done (a work package that adds or changes a
   trust boundary, a service, a data store or an agent guardrail updates the threat model that covers it) and one
   checkbox in the `wp-round` Close-out list (the three threat models checked against the round's changes). Keep
   both short; change nothing else in those two files.

## Acceptance
- [ ] ADR-0077 written and listed in `docs/adr/README.md`
- [ ] Privacy sections 9 and 10 describe the services as built, with evidence that exists on `main`
- [ ] The rule is in `CLAUDE.md` and the `wp-round` Close-out list
- [ ] `just docs-build` green (strict)
- [ ] Handover appended: what changed in the privacy model and any new `P-` finding with its rating

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- Docs and instruction files only: no code, no configuration, no test changes, so there is no red test in this
  package.
- Do not read `.env` or `.claude/settings.local.json`; do not stop or change the owner's running stack.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator: short, the detail stays in the
  handover.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
