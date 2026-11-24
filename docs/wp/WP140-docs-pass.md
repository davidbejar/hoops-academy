# WP140 — Docs pass, ninth round

Model: Opus · medium. Wave 6 (2026-11-23, ninth round): runs last and alone, after WP126–WP139 are merged. You own
README.md, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`,
`docs/architecture.md`, `docs/adr/README.md`, `docs/quality/mutation.md`, the skills under `.claude/skills` and
`CLAUDE.md` (finding X-14), and the stale lines the handovers name (`apps/web/README.md`, the comment of
`services/finance-service/internal/adapters/in/rest/api_test.go`). No production or test code. Depends on: every
handover of the round. Skills: wp-round (Close-out), work-package, verification-before-completion. Worktree:
`~/code/hoops-wt/wp140-docs-pass`, branch `wp140-docs-pass`.

Decision 104 of 2026-11-23: the round does what the audit confirmed; the docs pass records it. Decision 111: the audit
files are not committed and not linked; finding IDs are the reference.

## Scope
1. **FOLLOW-UPS**: plan table and merge order; items the round closed moved to Resolved with their WP; new open items
   from the handovers' open points and skipped findings (finding ID and reason).
2. **HANDOVER**: State (merge order with commits, contract and chart versions, test totals with their source), Pending
   user actions, Working conventions (environment facts only), Next candidates; CI observed with `gh run list -b main`.
3. **README, conformance, roadmap, architecture, ADR index** (0059–0071, the unused 0058, the amendments of the
   round), `docs/quality/mutation.md` from the handovers' numbers (no PIT run).
4. **Stale lines** named by handovers: test fakes and vectors in `apps/web/README.md`, the 413/415 comment in finance's
   `api_test.go`, old realm variable names, `sync_receipt`, the deleted fake files.
5. **Skills drift (X-14)**: `quarkus-hexagonal-service`, `flutter-feature`, `tenant-isolation-testing`,
   `go-hexagonal-service`, `rust-service`, `podman-dev-env`, `work-package`, `wp-round` and `CLAUDE.md` against what
   the round moved; three new Traps in `wp-round`.

## Acceptance
- [ ] Every claim checked against a handover, a commit, the code or a command; unverifiable numbers attributed
- [ ] `just docs-build` (strict) clean; relative links of the changed files resolve
- [ ] No `audit/` path linked or cited
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time (never `git add -A`,
  never `--no-verify`). Conventional Commits. End every commit message with a `Co-Authored-By:` line naming the model
  that did the work.
- Do not read, copy or print any `.env`; do not stop or restart the compose stack; do not re-run the big test suites.
- Finish per the `work-package` skill. Final report to the orchestrator.

## Handover
2026-11-24, Opus · medium. Documentation only, plus one comment line in a Go test file.

- **Built.** `docs/HANDOVER.md` rewritten for the ninth round: merge order with commits (WP129 983691e2, WP126
  45273b84, WP127 a93bbb2a, WP128 df5fcf26, orchestrator 2c47222f, WP132 8a76ebb9, WP133 ee44cd18, WP131 896b56d6,
  WP130 7937a127, WP135 65120abb, WP136 87e5fd68, WP134 5a5f6745, WP138 parts 1–2 699be74a / 5c0049c2, WP137
  ffe907ee / 7197ffa8, WP138 part 3 6d126f83, orchestrator bf586552, WP138 part 4 b0f374b3, WP139 bb12d2e0,
  orchestrator b8443244, WP138 part 5 e0cf6902 / 17d3dbb1), contract versions (finance 1.1.0), chart 0.15.0 with
  `hoops-lib` 0.1.0, test totals labelled with their handover, kind and local-stack state, CI run ids and the round's
  reds, a short section on the dependency merges of 2026-11-22/23, Pending (rollover wizard, audit files, stale PR #21,
  `.env` names), Working conventions (the compose provider, realm and admin URL names, the role list, shared settings
  and the chart test, transient Maven Central failures, kind under load, CI layout), Next candidates.
  `docs/wp/FOLLOW-UPS.md`: header, plan paragraph with the merge order, WP140 status; Pending (`.env` names of
  WP139, the audit files, the rollover wizard, PR #21 and #22 instead of #6 and #8–#13); contract wording (WP126,
  LIB-07); the finance leftovers without the two resolved lines; web (mock points of WP138 part 5, WP135's helpers
  left); backend (finance `parked_event`, replica and authz leftovers, every skipped finding with its reason);
  infra / CI (kind install under load, the fresh compose volume, shell tests outside CI, INF-07 / INF-08 / INF-11,
  MailHog, CI findings left, the transient failures with run ids, the ZAP port clash); security (the round's Semgrep
  acceptances, ZAP 40018 on core's audit export seen once); Resolved "Ninth round" with the orchestrator's fixes.
  README (layout, status, ninth round, chart, mutation), `docs/conformance.md` (ninth-round reconciliation, counts
  unchanged 55 / 7 / 5 / 0 / 2, the S-09 domain-gate claim corrected, V-01's stale "Left", S-04, S-17, gap 2, CI, the
  verification baseline), `docs/roadmap.md`, `docs/architecture.md` (chart 0.15.0 and `hoops-lib`, the web tests on
  the mock, "One pipeline, one rule" in section 5, decisions 0059–0071 in section 8, section 11 counts),
  `docs/adr/README.md` (the unused 0058, the amendments of 0006, 0014, 0030, 0031, 0037, 0040, 0053, 0055),
  `docs/quality/mutation.md` (scopes and mutant counts after WP137, history lines of WP127, WP128, WP130, WP134,
  WP137), `apps/web/README.md` (seeded mock instead of the fakes, the one vectors copy), finance's `api_test.go`
  comment. Skills: `quarkus-hexagonal-service` (paging helper, replica pipeline, membership rule, the real Problem
  exceptions, shared settings and test support), `flutter-feature` (tests on the seeded mock, vectors),
  `tenant-isolation-testing` (role list, membership rule, `bindTenant`), `podman-dev-env` (the compose provider),
  `rust-service` (one own slug, `tests/api/contract.rs`, `hoops-lib`, pin test), `go-hexagonal-service` (`hoops-lib`,
  the Go pin in `setup-go`), `work-package` (plain commits one at a time, context hand-back), `wp-round` (Mechanics 3
  and 4.2, three Traps, the brief template's commit rule), `CLAUDE.md` (what common-quarkus holds, the role list, the
  realm URL names).
- **Verified.** Facts from the WP126–WP139 handovers, `git log` / `git show` (merge order, orchestrator commits), the
  code (`Chart.yaml` versions, `openapi/*.yaml` versions, Dart package versions, PIT scopes in the poms, common's
  `microprofile-config.properties`, the web's `playerDues` through `fetchAll`, the mock's balance 404, the rollover
  call in `seasons_repository.dart` and `ROLLOVER_SAME_SEASON` in core, the `scripts` job of `ci.yml`, the pdf slug
  guard), `podman compose version` (Docker Compose v2.15.1), `gh run list` / `gh run view` for every run id and red
  cause quoted, `gh pr list` / `gh pr view`. `just docs-build` (strict): "No issues found". Relative links of every
  changed file outside `docs/` resolve (script). finance: `gofmt -l .` clean; `go vet ./...` reports one finding,
  `persistence/ports.go:17` "struct literal uses unkeyed fields", which is on `main` too (WP131's deliberate unkeyed
  `Ports` literal; golangci-lint's `govet` passes it); `go vet -composites=false ./...` clean. No build or test suite
  re-run; the test numbers are the handovers'.
- **Decisions/ADRs.** None.
- **Contradictions found.** The orchestrator's prompt named chart 0.14.0 as current; `Chart.yaml` says 0.15.0 (WP136
  bumped to 0.14.0, WP139 to 0.15.0). WP133 named `env-jdk.test.sh` and `tenancy-gate.test.sh` as not in CI (true);
  `events-drift.test.sh` is not in any workflow either. WP138 part 4 counted 1,952 for a fresh run of 21af40a0 where
  part 3 reported 1,953. The `trivy-fs` red on 393b5676 was not a download failure as such: Maven resolved the
  `dependency:` prefix to `org.codehaus.mojo:dependency-maven-plugin:1.0`. The two red `e2e` ZAP steps of 312cf764 and
  0c1ac2ae were a port clash of the ZAP daemon (game scan, then core scan), not a finding.
- **Open points.** Not verified: the Go test count after WP131 (WP137 and WP139 report green without a count), the
  Maven total as one number (3,780 is the sum of WP139's module counts), whether the ZAP 40018 on core's audit export
  is the known false positive. Owner decisions: the rollover wizard, the audit files' deletion, IDR digits. The
  orchestrator's memory note and the push are the orchestrator's steps.
