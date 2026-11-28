# WP151 — Chart: serving pods without the migrator password; outbound network policies

Model: Opus · high. Wave 2 (2026-11-29, eleventh round): runs alongside WP152 (pins) and WP154 (agent guardrails);
you are the wave's only kind user. You own `deploy/helm/**` and `deploy/kind/**`, and in the services only what the
split of migration and serving needs (start-up configuration, the finance runner's entry point); nobody else touches
those. Depends on: WP148 (`docs/security/threat-model.md`, findings TM-01 and TM-02 with their evidence). Skills:
work-package, quarkus-hexagonal-service, go-hexagonal-service, tenant-isolation-testing, owasp-security,
test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp151-chart-migration-job-and-egress-policies`, branch
`wp151-chart-migration-job-and-egress-policies`.

Decision 122 of 2026-11-28: the Medium findings are fixed in this round. ADR-0079 is reserved for you.

## Scope
1. **TM-01** (chart): a serving pod of core, game, athlete or finance holds only its `*_app` credential. The
   migrations run as the `*_migrator` in a step of their own (a Job, a hook or an init container: choose, measure
   on kind, record in ADR-0079) that finishes before the service serves. Red first: a chart test that fails while
   a serving container's environment names a migrator secret. Compose is the developer stack: say in the ADR
   whether it follows now or stays, with the reason.
2. **TM-02** (chart): core, game, athlete and Keycloak get outbound rules through `hoops-lib` (DNS, Postgres,
   Keycloak, Redpanda, the collector, and what each one really calls: read the code), as pdf and finance have. Red
   first: chart tests; then the proof on kind that a pod cannot reach an address outside its list and that the
   smoke still passes.
3. **Docs**: ADR-0079 and its line in `docs/adr/README.md` (append at the end); the runbooks that describe the
   install; the TM-01 and TM-02 entries of `docs/security/threat-model.md`.

## Acceptance
- [ ] Red tests committed before each change
- [ ] `deploy/helm/tests/run.sh` green; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green if a service
      changed (fresh; totals); `just test-go` green if finance changed
- [ ] On kind, on a quiet machine (do not build while `up.sh --deploy` runs): a fresh install, `deploy/kind/smoke.sh`
      green, the serving pods' environment without a migrator secret, an outbound call outside the list refused
- [ ] `just isolation-check` and `just db-role-check` run by hand in your worktree, results in the handover
- [ ] Handover appended with what the orchestrator must do at merge time on the owner's stack, if anything

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push: the
  orchestrator opens the pull request and merges it on green CI (decision 125).
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- Red test first, committed before the change it proves (a chart test, a script test, a workflow test).
- Threat model: when a finding of yours is fixed, edit only that finding's row or entry in its document (status,
  the fix, the evidence); other packages edit other rows of the same file.
- Do not read `.env` or `.claude/settings.local.json`, and do not edit `.claude/settings.json`; do not stop or change
  the owner's running compose stack and remove no volume.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Maven offline: `./mvnw -o
  -Daether.remoteRepositoryFilter.prefixes=false` when the network stalls.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator: short, the detail stays in the
  handover.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
