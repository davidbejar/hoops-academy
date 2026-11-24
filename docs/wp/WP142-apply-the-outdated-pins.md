# WP142 — Infra, chart, CI: apply the outdated pins; the bump script tracks PostgreSQL

Model: Sonnet · high. Wave 1 (2026-11-24, tenth round): runs alongside WP143 (database spans in the services). You own
the pinned lines in `infra/compose/compose.yaml`, `deploy/helm/hoops/values.yaml`, `deploy/lib/platform.sh`,
`deploy/containers/*.Containerfile`, `scripts/sbom.sh`, `scripts/zap-api-scan.sh`, `infra/tofu/check.sh`,
`.github/workflows/*.yml`, `.github/actions/**`, the chart snapshots, `scripts/bump_pins.py` with its tests, and the
one Redpanda Dev Services line in common-quarkus' `META-INF/microprofile-config.properties` (WP143 appends its own
lines to that file: touch only the pin). Depends on: nothing. Skills: work-package, podman-dev-env, owasp-security,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp142-apply-the-outdated-pins`,
branch `wp142-apply-the-outdated-pins`.

Decision 116 of 2026-11-24: the pins that `scripts/bump-pins.sh --check` reports outdated are applied in this round,
including the workflow-file pins the weekly bot cannot touch, and the bump script learns to track PostgreSQL's minor
version. No ADR is expected; if you make a decision, ADR-0076 is reserved for the round's infra packages (ask the
orchestrator before using it).

## Scope
1. **Apply**: `scripts/bump-pins.sh --check` on `main` reported 12 of 16 pins outdated on 2026-11-24 (distroless
   java25, Redis 8.12.0, Redpanda v26.3.1 in the chart, compose, finance's tests and Dev Services, Mailpit v1.34.0,
   otel-lgtm 0.41.1, Trivy 0.76.2, Semgrep 1.186.0, oras v1.4.0, the ZAP digest, CloudNativePG 1.30.2, Reloader
   2.2.21). Run `--apply` (with the workflow files), re-record what the pins are recorded into
   (`deploy/helm/tests/run.sh --update`), then `actionlint`. Minor and patch only: a major jump is listed in the
   handover, not applied. An action pin is the dereferenced commit, never a tag object.
2. **Read before trusting**: for each bumped image read the release notes for breaking changes that touch this repo
   (Redpanda's admin API and ACL bootstrap, Redis ACL user, Semgrep rule ids and the acceptances in
   `.semgrep/accepted.json`, ZAP rule ids in the gate files, Trivy result format). Run the Semgrep image locally with
   the repo rules and the gate (`scripts/sarif-gate.py`) so a new finding is seen here, not in CI.
3. **PostgreSQL in the bump script**: red test first in the script's tests: a `Pin` for PostgreSQL that covers every
   place the major is pinned (`infra/compose/compose.yaml`, the `databases` sub-chart's `values.yaml`,
   `PostgresRlsResource`, finance's `pgtest.go`, `.github/workflows/images.yml`) and reports a newer minor of the same
   major; a new major is reported, never applied. Do not change the PostgreSQL version itself: WP144 does that in wave
   2 and will move your pin's files.

## Acceptance
- [ ] `scripts/bump-pins.sh --check` reports only what you deliberately left (name each, with the reason)
- [ ] `python3 -I -m unittest discover -s scripts/tests`, `deploy/helm/tests/run.sh`, `actionlint`, `just test-go`
      (the Redpanda Testcontainers pin) and `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh;
      totals)
- [ ] Semgrep run locally with the new image: gate result recorded
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
