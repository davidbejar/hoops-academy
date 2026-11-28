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
- Built:
  - **ADR-0077** `docs/adr/0077-threat-modelling-methods.md` and its line at the end of `docs/adr/README.md`: STRIDE
    per boundary (product, `TM-`), LINDDUN per boundary with the same numbers where both have the boundary (1 to 10;
    STRIDE's 11, build and supply chain, has no privacy table; `P-`), MAESTRO for the build system only (`AG-`), PASTA's
    rating (thresholds as in the brief) and attack chains, VAST's keep-current rule; Trike and OCTAVE not used, with the
    reasons. Consequence written down: findings rated before the ADR (`F-`, P-01..P-13) keep their severity until a
    revision re-rates them.
  - **Privacy model** `docs/security/privacy-threat-model.md`: §9 (pdf-service) and §10 (finance-service) rewritten
    as built, every row with code or test evidence; header, inventory and data-flow overview without "planned"
    (PostgreSQL 19, database spans, telemetry backends); §1 DD (compose nginx has the export brake), §4 I (a major
    move's copies), §7 (finance is the third consumer), §8 I and DD (database spans per ADR-0074, exception messages,
    LGTM 24 h) corrected; retention table extended (finance stores, LGTM, dump and old volume); P-10..P-13 worded as
    built; a "Status after the tenth round" section lists every change; the Verification section names what was read.
  - **New findings** (ADR-0077 scale):

    | ID | Rating | Gate | Title |
    |---|---|---|---|
    | P-14 | Medium (L1 × I3) | yes | A PostgreSQL major move leaves the old volume and an unencrypted `pg_dumpall` file (every schema, password verifiers) with no deletion rule (ADR-0073, `scripts/pg-major-move.sh`) |
    | P-15 | Low (L1 × I1) | no | Exception events on server spans keep the message: game's `NotFoundException`s carry match / player ids (`MatchLookup`, `GetPlayerSeasonStats`, `IngestEventBatch`); a driver echo of refused input is untested (ADR-0074 §4) |

    New residuals folded into existing findings, not numbered: the finance audit trail is readable through no API
    (joins P-01); dues, payments, expenses, finance audit rows and parked events are never deleted (P-02); guardians
    are not told the roster CSV/PDF prints their contacts (joins P-05); the expense description is free text in the
    list and the CSV, its "no names with salaries" rule a contract convention only (P-12); Info: pdf-service on
    compose's `127.0.0.1:8084`, finance answers 403 (not 404) to members without the role.
  - **Rule**: one clause in `CLAUDE.md`'s Definition of Done, one checkbox in the `wp-round` Close-out list; `git diff`
    of both files shows nothing else.
- Verified: `just docs-build` (strict) green after each change ("No issues found"; the new anchor
  `#status-after-the-tenth-round-2026-11-28-wp150` present in the built page). `agentic-threat-model.md` is named in
  code formatting only (it arrives with WP149); `threat-model.md` is linked as a file, no anchor of WP148's new
  sections. `just test` not run: docs and instruction files only, no code or configuration changed. Evidence: every
  test cited in §9 and §10 found by exact name (`grep -rn "^func Test"`, `fn ...` in the Rust tests, Java method
  names); assertions read only for the tests opened: finance `TestRoleMatrixOfDuesPaymentsAndTheReads` (other family
  403 whether the player exists or not, stranger 404), `TestCrossTenantDuesAndPaymentsAreRefused` (404),
  `TestAuthenticationAndTheTenantHeader` (unknown and suspended academy 404), `TestReasonsAndNotesNeverReachLogsOrAudit`,
  `TestTheDuesExportFollowsTheCsvSpec`, `TestTheExpensesExportFollowsTheCsvSpec`, the expense lifecycle test's audit
  and log check. `TestAPersonEventKeepsLoginRolesAndActiveOnly` was dropped as evidence: its name predates V11 (the
  person replica keeps a display name), so the row cites `decode.go` instead.
- Decisions/ADRs: ADR-0077 (decisions 119–122). The P-14 and P-15 ratings are this package's judgement on that scale.
- Open points / follow-ups:
  - Wave 2 candidate: P-14 (a dated deletion or encryption rule for the dump and the old volume; the owner's PG17
    volume and dump are kept on purpose until the owner says otherwise). P-15 is Low, an open item (messages without
    ids, or no message on 4xx exception events; a test for the driver-echo case).
  - Likelihood is read as "how likely someone who should not see the data reaches it, given who can reach that store
    or path today" (stated in the Findings preamble); WP148 and WP149 may read it differently, the docs pass should
    align the three documents.
  - P-01..P-13 are not re-rated on the ADR-0077 scale (out of scope); a later revision may do it.
  - To verify: what finance's "request failed" log line (`rest/problem.go`, the error text of an unexpected error)
    can contain; the rows of §1–§8 that WP150 did not touch were not re-checked against the code beyond the tenth
    round's claims and the "planned / this round / yet" wording.
  - §7's note says the STRIDE model takes the Redpanda boundary up as 7 in WP148; if WP148 numbers it differently,
    the docs pass aligns the note.
