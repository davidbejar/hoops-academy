# WP146 — kind, CI: the kind install waits for Keycloak under load; the skipped shell tests run in CI

Model: Opus · medium. Wave 3 (2026-11-24, tenth round): starts after WP144 is merged; runs alongside WP145 (trigram
index); you are the wave's only kind user. You own `deploy/kind/**`, `deploy/lib/**`, `.github/workflows/ci.yml`,
`.github/actions/**`, `scripts/tests/*.test.sh`, `scripts/hooks/tenancy-gate.test.sh` and the code under test only
where a test shows a real Linux bug. WP145 owns athlete-service and the extension lines of the database bootstrap.
Depends on: WP144. Skills: work-package, podman-dev-env, systematic-debugging, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp146-kind-and-ci-hardening`, branch
`wp146-kind-and-ci-hardening`.

Decision 116 of 2026-11-24: two leftovers of the ninth round are closed. ADR-0076 is reserved for you only if you make
a decision worth one.

## Scope
1. **kind install under load (WP139)**: `deploy/kind/up.sh --deploy` failed its `helm --wait` once: Keycloak missed
   its progress deadline on the 2-CPU Podman VM at load 31, and the same helm command passed once Keycloak was ready.
   Reproduce or reason from the script and the chart (systematic-debugging: what waits for what, which deadline fired)
   before changing anything. The fix belongs where the cause is (a startup probe budget in the kind values, an
   explicit wait before the release's `--wait`, or a retry of the same command), not in a longer global timeout that
   hides a real failure. Proof: the full install, seed and smoke (`up.sh --deploy`, `seed-users.sh`, `smoke.sh core
   game athlete`) once, with load on the VM (a Maven build alongside); cluster deleted afterwards. Rebase on `main`
   before the proof if WP145 has merged, so the extension is covered.
2. **Shell tests outside CI**: `scripts/tests/env-jdk.test.sh` (2 of 3 fail on Linux: it needs a real JDK 25 outside
   `PATH`), `scripts/hooks/tenancy-gate.test.sh` (1 of 55 fails on Linux: a string cut at a multi-byte character) and
   `scripts/tests/events-drift.test.sh` run in no workflow. For each: is the Linux failure a bug in the script under
   test (fix it, red first) or a test that assumes macOS (make the test portable, or skip the one case on Linux with
   the reason printed)? Then run all three in the `ci` job `scripts`. You cannot run GitHub's runner: use a Linux
   container under Podman with the same tools to see the failures before pushing.
3. **Honest limits**: `shellcheck` reports 237 findings in the kind scripts and `run.sh` (WP136): fix the ones in
   lines you touch, do not start a sweep.

## Acceptance
- [ ] kind: install, seed and smoke green under load, with the command lines and timings in the handover
- [ ] The three shell tests pass in a Linux container and are wired into `ci.yml`; `actionlint` clean
- [ ] `python3 -I -m unittest discover -s scripts/tests` and `deploy/helm/tests/run.sh` green
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
