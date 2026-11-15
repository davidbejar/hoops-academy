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
- [x] Every boundary of the STRIDE model has its LINDDUN table; every mitigation cites something that exists
- [x] Findings list with severities; the project nature (learning project, decisions F-11 / F-22 accepted) respected
- [x] Handover appended: the findings as one-line items ready for FOLLOW-UPS

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
- Built: `docs/security/privacy-threat-model.md` (LINDDUN per trust boundary). A personal-data inventory, then the
  STRIDE data-flow overview extended by the events, telemetry and the two planned services. One table with the seven
  categories for each of the six STRIDE boundaries, plus §7 core → Redpanda → replicas, §8 services → collector → log
  backend, §9 core / game → `pdf-service` (planned) and §10 browser ↔ `finance-service` (planned). Also a status table
  of data-subject rights and retention per store, findings P-01..P-13 and a verification section.
- Verified: every cited mitigation was looked up in the tree at 8eec8325: migrations, classes, tests, realm, chart
  values, collector template, `sw.js`, tofu and the contracts (list in the document's "Verification" section). Rows
  for pdf-service and finance rest on ADR-0051, decisions 86–103 and the briefs WP111, WP116–WP119, WP123, and are
  marked planned. Not verified: EXIF handling of logos; whether game reads `birthDate` / `gender` beyond the replica
  filter (searched by name only). No build run: documentation only, no code changed.
- Decisions/ADRs: none. Severities rate the project as it runs today (learning project). A "Gate" column marks what
  must be closed before real academies use it: P-01..P-05. F-11 / F-22 stay accepted by design; their privacy impact
  is written down, not repeated as findings.
- Open points / follow-ups (one line each, for `docs/wp/FOLLOW-UPS.md`):
  - **P-01 (Medium, gate)**: no erasure, export or "about me" path for a person (GDPR 15/17/20). Persons and players are never deleted, so no `.removed` reaches replicas or topics. Action: an ADR for pseudonymising erasure plus a per-person export across services, then a WP.
  - **P-02 (Medium, gate)**: no retention enforcement. Withdrawn academies after `retain_until`, `core.audit_event` and decided academy requests are kept for ever. Action: the v2 purge job with a written period per store.
  - **P-03 (Low, gate)**: published `core.outbox` rows are never deleted: the full history of person/player payloads (name, birth date, gender, `sub`). Action: a core job that deletes published rows older than the 7-day tombstone retention.
  - **P-04 (Low, gate)**: health writes and deletes (art. 9, minors) have no audit trail in athlete. Action: audit health writes and deletes; decide on logging reads.
  - **P-05 (Low, gate)**: no privacy notice, legal basis, consent record, DPIA or records of processing. Action: a notice page in es / en / id (landing, request form, app menu) and a DPIA note in `docs/security/`.
  - **P-06 (Low)**: the free-text reason of a planned absence (and attendance notes) is readable by every staff role of the academy and can carry health details. Action: limit it to ADMIN and the player's team staff, or use a category plus a hint.
  - **P-07 (Low)**: shipped logs link a person across academies (`sub` + `tenantId` in `hoops.audit` / `hoops.security`) and have no retention. Action: WP120 sets log and trace retention (e.g. 30 days) and operator-only Grafana access.
  - **P-08 (Info)**: `LOGIN_SHARED` / `EMAIL_TAKEN` tell an academy ADMIN about another academy's membership or an existing login. Action: record it as accepted in ADR-0025 (F-11 family).
  - **P-09 (Info)**: athlete `CallerActor` falls back to `preferred_username` (the e-mail) as the author name shown to families. Action: a neutral fallback label.
  - **P-10 (Info)**: replicas store birth date and gender of every player; the finance replica must not copy them. Action: WP119 stores only what finance needs; check whether game needs them.
  - **P-11 (Low, planned)**: pdf-service errors may echo request values (children's names) into Problems or logs; the printed roster carries guardians' contacts. Action: WP111 uses generic details and adds a no-echo test; WP116 / WP117 never log its bodies; WP116 decides the contact columns.
  - **P-12 (Low, planned)**: finance free-text reasons and notes in audit and exports; the coach sees who is behind (by design); parent visibility of reasons, export rate limits and retention are undecided. Action: settle them in WP119 / WP123.
  - **P-13 (Low)**: a guardian link is made by one ADMIN without notice to the player or other guardians, and it grants health access. Action: show the links (and new ones) on the person's own profile.
