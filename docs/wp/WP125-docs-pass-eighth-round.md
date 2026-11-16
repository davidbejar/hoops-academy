# WP125 — Docs pass, eighth round

Model: Opus · effort medium. Wave 5 (2026-11-15, eighth round): runs last and alone, after WP111–WP124 are merged.
You own README.md, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`,
`docs/architecture.md`, `docs/adr/README.md`, `docs/PLAN.md` status box and the user guides (es / en / id). The
rule "do not edit README, HANDOVER, FOLLOW-UPS" below does not apply to you. Depends on: every handover of the
round. Skills: verification-before-completion. Worktree: `~/code/hoops-wt/wp125-docs-pass`, branch `wp125-docs-pass`.

## Scope
Follow the Close-out checklist of `.claude/skills/wp-round/SKILL.md`:
1. **FOLLOW-UPS**: plan table statuses; the TODO items now built (pdf-service, finance-service, PMD, LINDDUN,
   observability, the small fixes, `images` red) moved to Resolved with their WP; the LINDDUN findings (WP112) and
   every handover's Open points as new open items.
2. **HANDOVER**: State (merge order with commits, contract and chart versions, test totals per language), Pending,
   Working conventions (environment facts only: Rust and Go toolchains, the new gates), Next candidates.
3. **README, conformance, roadmap, architecture** (five deployables, the finance bounded context, the PDF path),
   the ADR index, the user guides (Finance area per role, PDF buttons).
4. **CI state** on `main` observed with `gh run list -b main` (run ids in HANDOVER), `images` included.
5. **Orchestrator fixes of the round** (no work package; put them in HANDOVER and FOLLOW-UPS): 4d10d7cf the compose
   nginx limit counts only the public POST of `/platform/academy-requests`; 54e7a2da `tenant_timezone_test.dart`
   failed late on Sundays in UTC; a new dated ZAP acceptance in `.zap/api-core.conf` (40018 on
   `/platform/academy-requests`, until 2027-05-16: the 429 of the WP115 limit, as WP83's for `events:batch`) goes
   into "Acceptances with an expiry".
6. **More orchestrator notes** (2026-11-16): the realm audience mappers for `pdf-service` (dd54179d) and the web's
   `finance-service` audience line in `RealmTokenPolicyTest` were added at merge time; 0c9309aa (finance image
   check's cleanup) and a9649e02 (Go before CodeQL init) fixed the workflows; the commit hook's isolation check runs
   in the session's directory (the main checkout), so in a worktree it never checks the branch (open item: make it
   follow the commit's worktree); the owner's `.env` got `FINANCE_MIGRATOR_PASSWORD`, `FINANCE_APP_PASSWORD` and
   `REDPANDA_FINANCE_SERVICE_PASSWORD` copied from WP118's worktree; a network outage stopped wave 2 for about five
   hours (the watchdog resumed the agents); P-07 of the privacy threat model and `release.md`'s Jaeger line are out
   of date since WP120; database spans are missing in every service (WP120 handover); game's academy names need
   `just events-backfill force` (WP117 handover).
7. **Wave 4 notes** (orchestrator, 2026-11-16): WP123's agent could not run the journey (its worktree `.env` could
   not sign in to the shared database); the orchestrator ran `just e2e` on compose from the main checkout with WP123
   merged: 38 tests, 0 failures, `JourneyTest` 32 with none skipped, which is also the first real core → pdf-service
   and game → pdf-service call on compose. Not run by anyone: the finance ZAP scan outside CI (see the `e2e` run on
   the WP123 merge), whether its two pre-accepted export lines in `.zap/api-finance.conf` ever match (drop them if
   not). A usage limit stopped wave 4 once (resumed after the reset). Owner decision still open: IDR is stored with
   2 minor digits (ISO 4217) and shown without decimals for whole amounts (WP121 handover).

## Acceptance
- [ ] Every claim checked against a handover, a commit or a command you ran
- [ ] Links resolve (the repository's link check, if any; otherwise grep)
- [ ] Handover appended

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
2026-11-16, Opus · medium. Documentation only.

- **Built.** `docs/HANDOVER.md` rewritten for the eighth round: merge order with commits (WP112 af408107, WP115
  7c4421eb, WP113 bea1365c, WP114 d56c43eb, orchestrator 4d10d7cf / 54e7a2da / ef6cb697, WP111 2a8172c2 + dd54179d,
  WP116 c06988b0, WP117 a8ac9890, WP118 a40d3960 + fe0a1e9a / 0c9309aa / a9649e02, WP122 55de9963, WP120 d677c9c9,
  WP121 3e932f7e, WP119 1edf2029, WP124 94c27d7c, WP123 faa732eb, then 9bb4bdb2 / 031e1155 / 3f964fb2), contract
  versions, chart 0.13.0 and sub-charts, test totals per language, what kind proved and did not, local stack, CI run
  ids, Pending, Working conventions (three languages in `just test`, PMD gate, distroless, the hook in the main
  checkout, worktrees without a usable `.env`, `HOOPS_FINANCE_BIND` on Linux), Next candidates. `docs/wp/FOLLOW-UPS.md`:
  header, plan intro and WP125 cell; Pending rewritten (`images` gone; `.env` keys, other stacks, IDR decision,
  Dependabot PRs, browser checks for the PDF buttons and the Finance area); Resolved "Eighth round" (the items the round closed, plus
  the orchestrator's fixes and the interruptions); new or reworked open items: PDF leftovers, Finance leftovers,
  P-01..P-13 (P-07, P-10, P-11, P-12 marked partly or fully mitigated), PMD leftovers, Rust / Go tooling gaps, finance
  replica housekeeping, observability leftovers, the hook-in-worktree item, chart leftovers, e2e / ZAP for the new
  services, dependency-check NVD flakes, distroless debugging, the profile screen's pickers, new ZAP acceptances.
  README (features, roles, stack, commands, layout, documentation, status), `docs/conformance.md` (reconciliation,
  gaps 2 and 9, S-04, S-17, U-01, R-14, Kubernetes deviation, baseline; counts unchanged 55/7/5/0/2),
  `docs/roadmap.md`, `docs/architecture.md` (five services in sections 1 and 2, decisions 0051–0056, the `finance`
  schema, counts with Rust and Go, security posture, new section 14 "PDF and finance"), `docs/adr/README.md` (0052
  moved before 0053, amendments of 0003, 0007, 0034, 0046, 0048, 0051, 0056 noted), ADR-0007's status line ("not built
  yet" was stale), the PLAN status box, `docs/security/privacy-threat-model.md` ("Status after the eighth round"),
  `docs/runbooks/release.md` (Jaeger line, metrics pipeline, SBOM table: distroless, pdf, finance). Guides es / en /
  id: the Finance section for admins, the roster PDF for admins and coaches, the match sheet PDF for every role, the
  coach's "Dues up to date", the families' "Dues" tab, language and theme on the chooser (admin, super admin).
- **Verified.** Facts from the WP111–WP124 handovers, the orchestrator's notes (brief items 5–7 and the message about
  9bb4bdb2, 031e1155, 3f964fb2), `git log` / `git show` on the branch and `main`; versions from `libs/contracts/openapi/*.yaml`
  and `deploy/helm/hoops/**/Chart.yaml`; labels from `apps/web/lib/l10n/app_{en,es,id}.arb` and the finance screens;
  finance tables from its migrations; CORS from `common-quarkus` config; `gh run list -b main` and `gh run view` for
  every run id quoted (3f964fb2: `ci` 43815905569, `e2e` 43815905637 with `JourneyTest` 32 run 0 skipped and the
  finance ZAP scan, `codeql` 43815905544, `semgrep` 43815905530 green; last `images` 43813211306 on 2f51edb3 green);
  `gh pr list` for the open PRs. Relative links of every changed page resolve (script). No build or test run: no code
  changed; the test numbers are the handovers', not re-run.
- **Decisions/ADRs.** None (ADR-0007's status line corrected).
- **Contradictions found.** WP124's demo mock answers 409 `CURRENCY_NOT_SET` for the balance without a currency, the
  service (WP123) answers 404; WP122 expects the PDF name from `Content-Disposition`, but the services expose only
  `ETag` and `Location` through CORS (matters only cross-origin, unchecked); WP116 counts contracts 323, WP117 322
  (different branches); WP124 quotes its baseline as 1,652 (WP121) although WP122's tests were on `main` (1,687, plan
  table); WP121's IDR handling versus the brief ("no decimals"). All are in FOLLOW-UPS.
- **Open points.** The guides were written from the ARB files and the code, not a browser walk-through. Not
  re-checked: per-module JVM counts after WP118 (only totals reported). Memory files are the orchestrator's step.
