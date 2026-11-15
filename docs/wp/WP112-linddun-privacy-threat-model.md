# WP112 — Security docs: LINDDUN privacy threat model

Model: Opus · effort medium. Wave 1 (2026-11-15, eighth round): runs alongside WP111, WP113, WP114, WP115; none of
them touches `docs/security`. You own `docs/security/privacy-threat-model.md` only; you change no code. Depends on:
`docs/security/threat-model.md` (STRIDE, the data-flow overview and trust boundaries), `docs/security/review-2026-11.md`,
ADR-0017, ADR-0025, ADR-0026, ADR-0029, ADR-0042, ADR-0043, ADR-0046, ADR-0048, ADR-0050, ADR-0051. Skills:
owasp-security, verification-before-completion. Worktree: `~/code/hoops-wt/wp112-linddun`, branch `wp112-linddun`.

Decision 102 of 2026-11-15 (owner): write the LINDDUN model; its findings become FOLLOW-UPS items (the docs pass
moves them, you list them).

## Scope
1. **Model**: over the same data-flow overview and boundaries as the STRIDE model, one table per boundary with the
   seven LINDDUN categories (linking, identifying, non-repudiation, detecting, data disclosure, unawareness,
   non-compliance); each row: the threat, the existing mitigation with its file or ADR, the residual risk.
2. **Cover at least**: minors' personal data and guardian links; health and fitness data (GDPR art. 9); the audit
   trail and security events (what they record about a person); exports (ADR-0048); one login across academies
   (ADR-0025, ADR-0026); offline device storage; traces and logs (ADR-0046); retention and the missing purge job;
   portability and erasure (not designed); and, as decided this round (FOLLOW-UPS decisions 89–99), the request bodies
   of `pdf-service` and the `finance` data (what a family owes and has paid; a coach sees status only).
3. **Verify every claim against the code** (a mitigation you cite must exist: name the class, migration or config).
4. **Findings**: a numbered list `P-01…` with severity and a proposed action, in the style of the security review.

## Acceptance
- [ ] Every boundary of the STRIDE model has its LINDDUN table; every mitigation cites something that exists
- [ ] Findings list with severities; the project nature (learning project, decisions F-11 / F-22 accepted) respected
- [ ] Handover appended: the findings as one-line items ready for FOLLOW-UPS

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
