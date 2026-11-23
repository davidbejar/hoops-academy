# WP132 — pdf-service: test helpers and contract cache, `tower` to dev, token leeway and Problem names aligned

Model: Sonnet · medium. Wave 2 (2026-11-23, ninth round): starts after wave 1 is merged; runs alongside WP130
(library, game, athlete), WP131 (finance), WP133 (CI). You own `services/pdf-service/**` and
`.claude/skills/rust-service/SKILL.md`; nobody else touches them. `libs/contracts/openapi/pdf.yaml` only if a Problem
name changes (bump `info.version`; tell the orchestrator, core and game validate against it). Depends on: ADR-0051,
ADR-0052. Skills: work-package, rust-service, test-driven-development, clean-code, verification-before-completion.
Worktree: `~/code/hoops-wt/wp132-pdf-test-helpers-leeway-problem-names`, branch
`wp132-pdf-test-helpers-leeway-problem-names`.

Decisions 104 and 112 of 2026-11-23: everything confirmed in pdf-service is fixed; the token clock leeway takes the
Java services' value and the Problem type names those of `common.yaml`. ADR-0064 is reserved for you if a decision is
needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `pdf-service.md`
(PDF-01..12), verification `verify-pdf-finance.md`; X-11 in `cross-cutting.md`, verification
`verify-cross-cutting-libs.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Tests**: PDF-02 (parse `pdf.yaml` and compile the validator once, `OnceLock`), PDF-04 (one leak list, path
   constants and JSON-pointer helpers: the P-11 privacy guard has one copy), PDF-05 (fewer test binaries where it is
   safe; `logs.rs` stays its own binary; one RSA key per binary).
2. **Manifest (PDF-03)**: `tower` is used only by tests: dev-dependency; `tests/layering.rs` follows.
3. **Aligned rules (X-11)**: leeway and Problem type names; a test reads the names from the contract.
4. **Handlers (PDF-01, as corrected)**: no domain `Sheet` trait; a generic handler in the adapters only if it is
   plainly simpler than the two functions, otherwise leave and say so.
5. **The rest**: every other PDF finding of your scope; the skill file where it lags the code.

Not yours: PDF-12's claim that fmt runs after the tests is wrong: nothing to do there.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `just test-rust` green (fresh; totals; coverage gates; `cargo deny`)
- [ ] the render output is unchanged for the fixtures (`tests/render.rs` green without re-recording)
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
