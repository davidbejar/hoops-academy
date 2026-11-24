# WP147 — Docs: docs pass of the tenth round

Model: Opus · medium. Wave 4 (2026-11-24, tenth round): starts after every other package is merged and runs alone. You
own README, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`,
`docs/architecture.md`, the ADR index, `CLAUDE.md` and the skills where the round made them wrong. Depends on:
WP142–WP146. Skills: work-package, wp-round (Close-out), verification-before-completion. Worktree:
`~/code/hoops-wt/wp147-docs-pass`, branch `wp147-docs-pass`.

Decisions 114–118 of 2026-11-24. No ADR.

## Scope
1. **Close-out**: the `wp-round` skill's checklist: FOLLOW-UPS (plan statuses, the round's resolved items moved to
   Resolved with their package: PostgreSQL 19, the fresh-volume bootstrap, the trigram index, database spans, the kind
   install under load, the shell tests outside CI, the outdated pins; new open items from the handovers), HANDOVER
   (state, versions, totals labelled with their source, environment facts), README, conformance, roadmap,
   architecture, ADR index.
2. **Version lines**: every doc, skill and runbook that says PostgreSQL 17 as the current version says what was
   adopted (historic mentions in `docs/PLAN.md`, old briefs and ADRs stay).
3. **CI**: record the runs you observe with `gh run list -b main`; claim green only for what you saw.

## Acceptance
- [ ] `just docs-build` (strict) and `python3 -I -m unittest discover -s scripts/tests` green
- [ ] Every factual line comes from a handover, the code, `git log` or `gh`; unverifiable numbers are attributed
- [ ] Red tests committed before each change
- [ ] Handover appended: what was built, fresh verification with totals, what was not run, open points

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
- Do not read, copy or print any `.env`. The compose stack that is running is the owner's: do not `just down` it, do
  not remove or recreate its volumes. What needs the real stack or the owner's database comes back "not run" in the
  handover; the orchestrator runs it from the main checkout at merge time.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
2026-11-25, Opus 5.5 · medium. Documentation only; no code, test or build change.

- **Built.**
  - Version lines (ca918a7e): README stack line, `docs/architecture.md` diagram, `docs/conformance.md` S-07 and S-11,
    `docs/security/threat-model.md` scope line and `apps/web/README.md`'s realm reset (`hoops_pgdata-19`) name
    PostgreSQL 19; `docs/runbooks/release.md` §6 lists the PostgreSQL pin; `docs/security/sast-dast.md` reads the
    Semgrep image from `semgrep.yml` instead of naming 1.183.0 (WP142 open point 2). Left as history: ADRs, PLAN, old
    briefs and handovers, the two runbooks that describe the way back, the V21 migration comment, the test fixtures.
  - `docs/wp/FOLLOW-UPS.md` (2e9fac04): header, tenth-round plan paragraph with the merge order; Resolved "Tenth
    round" (PostgreSQL 19, the fresh-volume bootstrap, the trigram index closed by ADR-0075 as a decision changed by
    evidence, database spans with the orchestrator's Tempo proof, the shell tests outside CI, Keycloak's start on kind,
    the outdated pins and PR #21, this pass, the hook fix 4ed1a1e4); Open items rewritten or added (below); Pending:
    the PostgreSQL 17 volume and dump, more vCPUs, workflow-file pins, the rollover wizard among the browser checks.
  - `docs/HANDOVER.md` (0ded9872): state of the tenth round (merge order, contract and chart versions read from the
    files, totals labelled with their source, kind, local stack, security, CI run ids), Pending 7 and 8, Working
    conventions (PostgreSQL volume per major, Maven offline and the prefix filter flag, jqwik's line to AI agents,
    database spans, Redpanda's one-way move, the shell tests in CI, kind under load), Next candidates.
  - 234773bf: README status and the tenth round, `docs/conformance.md` reconciliation (no status changed: 55 / 7 / 5 /
    0 / 2) and baseline, `docs/roadmap.md`, `docs/architecture.md` (§8 rows 0072–0076, the observability line, §11
    counts), `docs/adr/README.md` (0073 before 0074; 0041 and 0046 rows name their amendments), skills `wp-round`
    (three traps) and `quarkus-hexagonal-service` (the sampler constraint of ADR-0074).
- **Verified** (fresh, 2026-11-25): `python3 -I -m unittest discover -s scripts/tests` 140 OK, 1 skipped (before and
  after each commit); `just docs-build` (strict) "No issues found"; `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED
  (246 ok lines); relative links of the changed files outside `docs/` resolve (script). Facts from the WP142–WP146
  handovers, the orchestrator's notes (labelled "orchestrator"), `git log`, the tree (`Chart.yaml` and `openapi/*.yaml`
  versions, `bump_pins.py`, `_common.sh` (no prefix-filter flag), `ci.yml`'s `scripts` job, `DatabaseSpansNeedAParent`)
  and `gh run list -b main` / `gh run view` / `gh pr list`. No Maven, Go, Rust or Flutter run: the totals are the
  handovers'.
- **CI observed**: every run on 4ed1a1e4, c9daa73e, b2e269f5 and 1781cfcb green; on d6539fc6 `ci` (with WP146's four
  shell-test steps green on GitHub's runner), `images`, `codeql`, `semgrep`, `pages` green, `e2e` 45445935916 still
  running at the last look: **orchestrator to fill in** (also in HANDOVER's CI paragraph).
- **Red tests**: not applicable (documentation only, no behaviour changed; WP140's and WP145's precedent).
- **Decisions/ADRs**: none.
- **Contradictions found.** The brief's Working rules say "Do not edit README.md, docs/HANDOVER.md,
  docs/wp/FOLLOW-UPS.md" while its header and Scope 1 give them to this package: treated as a template leftover and
  edited. The orchestrator names `TenantUsageResourceTest.aPeerSlowerThanTheTimeoutCountsAsUnavailable` as failing
  once in WP146's runs; WP146's handover names `PlatformEventBackfillTest.withoutATenantEveryAcademyIsBackfilled`
  instead: both recorded with their source. Go coverage: 88.68 % (WP143, WP146) vs 88.75 % (WP144); WP146's quoted.
  HANDOVER said 1,954 Flutter tests; WP141 reported 1,958 (no web change since).
- **Not run / not done**: no build or suite beyond the checks above; the push, the orchestrator's memory note and
  stopping `caffeinate` are the orchestrator's close-out steps.
- **Open points recorded** (FOLLOW-UPS unless noted): ids in exception messages on game's spans (P-11 / ADR-0043
  question) and the untested refused-input echo (Security); scheduler tracing, the outbox per-poll span count, the
  sampler constraint (Observability leftovers); PostgreSQL 19 leftovers (ADR-0073 table when CNPG 1.31 / Keycloak /
  Flyway list 19, the CNPG import path never run, the move's later steps only on stubs); kind install under load and
  otel-collector / lgtm restarts; `smoke.sh`'s outbox wait without a test; two load-sensitive core tests; one Keycloak
  admin 401 in `seed-users` (cause not established); Maven's prefix filter; `env.sh` with no JDK 25; INF-07 retrofit
  removable (candidate); `app.enable_tenant_rls` PUBLIC `EXECUTE` (Backend). Pending: the PostgreSQL 17 volume and
  dump, more vCPUs, the rollover wizard and the other browser checks.
