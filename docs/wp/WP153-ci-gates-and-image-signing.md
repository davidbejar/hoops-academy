# WP153 — CI: the Keycloak tests run, guarded paths are checked, images wait for CI and are signed

Model: Opus · high. Wave 3 (2026-11-29, eleventh round): starts after WP152 and WP154 are merged (both touch the
workflows before you) and runs alone. You own the structure of `.github/workflows/**` (jobs, triggers,
permissions), `.github/CODEOWNERS` if you add one, and the workflow tests under `scripts/tests`. Depends on: WP148
(TM-03, TM-08), WP149 (AG-01, AG-02, AG-04, AG-08), WP152, WP154. Skills: work-package, owasp-security (its
config-and-supply-chain reference), test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp153-ci-gates-and-image-signing`, branch `wp153-ci-gates-and-image-signing`.

Decisions 122 and 125 (FOLLOW-UPS). ADR-0080 is reserved for you.

## Scope
1. **AG-01, CI part**: a job runs the Keycloak-tagged tests (`-Pkeycloak-it`, the cross-tenant login tests
   among them) on every pull request and on `main`. Red first: a workflow test that fails while no job runs them.
2. **AG-02, TM-03, AG-08**: images are built and pushed only for a `main` commit whose `ci` run is green. The
   ruleset on `main` is the orchestrator's step at the end of the round: write in your handover the exact check
   names it must require, and prove each name exists on a pull request run.
3. **AG-04**: a `guarded-paths` job that fails a pull request changing a guardrail or instruction file
   (`.claude/**`, `scripts/hooks/**`, `.github/**`, `.gitleaks.toml`, `.pre-commit-config.yaml`, `CLAUDE.md`)
   unless the pull request carries a label only the owner sets; say in the ADR what this stops and what it does
   not while agents use the owner's login (AG-05).
4. **TM-08**: the pushed images are signed with cosign (keyless, the workflow's identity) and carry a provenance
   attestation; the release runbook says how to verify one. Deploying by digest in the chart is not in this
   package: list it as an open point.
5. **Docs**: ADR-0080 and its line in `docs/adr/README.md` (append at the end); the entries of your findings in
   the two threat models; `docs/security/sast-dast.md` where it lists the jobs.

## Acceptance
- [ ] Red tests committed before each change; the workflow tests under `scripts/tests` green; `actionlint` clean
- [ ] Least privilege kept: no job gains a permission it does not use (`id-token: write` only where signing needs
      it)
- [ ] What can only be proven on GitHub (the new jobs, the signing) is listed for the orchestrator to check on
      the pull request's run
- [ ] Handover appended: the required check names, and how to verify a signature

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
