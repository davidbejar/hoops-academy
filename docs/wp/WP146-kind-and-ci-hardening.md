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

**Result.** The shell tests run in CI and pass on Linux. Under load, kind failed three different ways; each failure
now has a fix and a test, and Keycloak (WP139's failure) now survives twice WP139's load. **The acceptance "install, seed
and smoke green under load" is not met**: at a VM load of 50 to 60 the three JVM services still miss helm's 15 m and
the kube-apiserver restarts. The same cluster then passed `up.sh --deploy`, seed and smoke once the extra build had
ended (a quiet re-run, not a fresh install).

- Built:
  - **Shell tests in CI.** `test_workflows.py` adds `ShellTestsRunInCi`: every `*.test.sh` that `git ls-files` lists
    must be a step of `ci.yml`'s `scripts` job (red: 3 of 4 missing). The job now also runs `env-jdk`,
    `tenancy-gate`, `events-drift` and the new `kind-cnpg-patch`. The comment saying "they stay local" is gone.
  - **The Linux failures were all test assumptions; no script under test had a bug.** The red evidence is the
    `ubuntu:24.04` runs below, since a test-only change cannot be committed red.
    - `tenancy-gate.test.sh`: GNU `cut -c` counts bytes and cut through `✗` (54/55). The checks now match with a
      trailing glob.
    - `env-jdk.test.sh`: it passed only because macOS `java_home` found Homebrew's JDK 25 (1/3 on Linux). A stub 25 on
      `PATH` makes it hermetic, and the replacement must be exactly that stub.
  - **`maven_offline_first` (4ed1a1e4) gets four checks** with a stub `./mvnw`. Offline success runs once; "offline
    mode" and "has not been downloaded from it before" each retry online; a test failure does not retry. These test
    existing code, so they could not be red at HEAD. Each of the two mutants of the helper fails at least one check.
  - **kind, run 1 (no change).** helm's apply was refused by the CNPG webhook. The operator's upstream probes (1 s
    timeouts, 30 s to start) had killed it 7 times (exit 143).
    - `deploy/kind/cnpg-patch.sh` builds the kind JSON patch: no leader election as before, 5 s timeouts, 5 minutes to
      start, a kill after a minute.
    - `up.sh` waits for the operator to be `Available` right before `helm upgrade`.
    - Red test first: `scripts/tests/kind-cnpg-patch.test.sh`, 9 checks.
  - **kind, run 2.** Keycloak was killed by liveness (1 s timeout, exit 137) about 10 minutes into its start. The
    services were killed too (2-3 s timeouts, 30 s to a kill).
    - Helm 4.3.1 source (`statuswait.go`) and kstatus (`core.go`): a Deployment that hits `ProgressDeadlineExceeded`
      is `Failed`, and Helm stops waiting for it. Keycloak's deadline was 600 s while its startup probe allows 620 s.
    - `values-kind.yaml` now gives Keycloak, core, game, athlete, pdf and finance 5 s probe answers, a kill after a
      minute and 5 minutes to start. Keycloak gets `progressDeadlineSeconds: 900`, equal to up.sh's `--timeout 15m`,
      which is unchanged.
    - The Keycloak sub-chart takes the optional `probeTimeoutSeconds` and `progressDeadlineSeconds`; unset, they
      render as before.
    - Red first in `deploy/helm/tests/run.sh`, section "kind on a busy 2-CPU Podman VM": 9 checks, including that
      the default and cloud renders are unchanged. Snapshot `umbrella-kind.yaml` re-recorded: only the probe lines and
      the deadline.
  - **`smoke.sh` is unchanged**, so WP144's outbox wait still has no test (see open points).
  - **ADR-0076** (kind probes for a busy VM; helm's timeout stays the outer bound), with an index entry.
- Verified (fresh, 2026-11-24/25, HEAD after the rebase on `main` 23d51081, which includes WP145):
  - **kind runs**, all `MAVEN_ARGS="-o -Daether.remoteRepositoryFilter.prefixes=false" deploy/kind/up.sh --deploy
    --from-host`, with a throwaway `.env` of random values (never printed, removed afterwards):

    | Run | Load alongside | VM load (1 min) | up.sh | Outcome |
    | --- | --- | --- | --- | --- |
    | 1 | `./mvnw -o -T 1C verify` | up to 68 | rc 1 after 1190 s | CNPG webhook refused the apply |
    | 2 (CNPG fix) | two of those back to back | 85-123, CPU pressure 97 % | rc 1 after 1555 s | core, game, athlete, Keycloak InProgress after 15 m |
    | 3 (all fixes) | `-pl services/core-service -am verify`, no `-T`, started when helm began (23:25:50) | 32-63 | rc 1 after 1176 s | core, game, athlete, lgtm InProgress |

    - In run 3, Keycloak, both databases and the CNPG operator had 0 restarts, and finance and pdf were Ready. The
      three services were killed by liveness about 23:36 and by startup at about 23:31 and 23:43; the
      kube-apiserver restarted at 23:43:36.
    - With no extra load, everything was `Available` at 23:47:41. On that same cluster: `up.sh --deploy --from-host`
      rc 0 in 275 s, `deploy/kind/seed-users.sh` rc 0 in 45 s, `deploy/kind/smoke.sh core game athlete` **SMOKE
      PASSED, 57 checks** in 56 s (VM load 5).
    - Cluster deleted (`kind get clusters`: none).
  - **Linux**: an `ubuntu:24.04` container (mawk, GNU coreutils, `/usr/bin/java` = 17, Podman 4.9 remote to the VM)
    on a `git clone` of HEAD.
    - Every tracked `*.test.sh` passed: tenancy-gate 59/59, doctor drop-in 5/5, env-jdk 3/3, events-drift 49/49,
      kind-cnpg-patch 9/9.
    - `python3 -I -m unittest discover -s scripts/tests`: 140 OK (1 skipped). This needs `curl`, which the runner
      has.
    - The new awk lines of `run.sh` give the same values under mawk.
  - **macOS**:
    - `python3 -I -m unittest discover -s scripts/tests`: 140 OK, 1 skipped.
    - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (246 ok).
    - `actionlint`: clean. `shellcheck` on the new and changed shell files: clean (in `run.sh` and `up.sh`, only
      the lines I touched).
    - `just docs-build`: no issues.
  - **`just test`**: rc 0 in 665 s, Maven offline.
    - Maven: contracts 346, common-quarkus 585, core 1267, game 530, athlete 1028 tests, 0 failures. e2e: 38, of
      which 32 skip without a stack.
    - pdf-service: 105 tests, coverage 95.72 % / domain 99.80 %. finance-service: 15 packages ok, 88.68 % / domain
      98.84 %, govulncheck clean.
- Decisions/ADRs: ADR-0076.
- Only CI will prove: the four shell-test steps on GitHub's runner (its Podman, the Docker Hub pull of
  `postgres:19.0-trixie` for events-drift, its jq and git). The container run is the nearest local equivalent.
- Not run: `just isolation-check` / `db-role-check` by hand (no tenancy change; the commit hook ran its check on each
  commit); kind with `--eso`; the cloud install. Nothing touched the owner's compose stack.
- Open points:
  1. **The VM has 2 vCPUs and also runs the compose stack.** The release cannot converge in 15 m beside a build at a
     load of 50 or more. The remedies are more vCPUs (`podman machine set --cpus`, which stops the owner's stack:
     their decision) or not building while installing. Raising helm's timeout would only hide this.
  2. WP144's outbox wait in `smoke.sh` still has no committed test (I did not touch the script).
  3. Under load, core's `PlatformEventBackfillTest.withoutATenantEveryAcademyIsBackfilled` failed once with a 30 s
     `SocketTimeoutException` (run 1's build). It passed in `just test`. It is a timing-sensitive test under heavy
     load, not investigated (outside scope).
  4. `env.sh` keeps a wrong-major `JAVA_HOME` (with a warning) when no JDK 25 exists anywhere. The behaviour is
     unchanged and untested, because macOS always has one through `java_home`.
  5. otel-collector (5-6 restarts) and lgtm also restart under load. Their probes are unchanged (not app workloads).
