# WP136 — Chart, kind, cloud: library chart for the service sub-charts; one source for the kind and cloud install pins

Model: Opus · high. Wave 3 (2026-11-23, ninth round): starts after wave 2 is merged; runs alongside WP134 (library and
services), WP135 (web). You are the only kind user of the wave. You own `deploy/**` and the `Tiltfile`; nobody else
touches them. Not `infra/**`, not `scripts/**` except `scripts/sync-chart-files.sh` if a path moves. Depends on:
ADR-0022, ADR-0038. Skills: work-package, podman-dev-env, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp136-chart-library-install-pins`, branch
`wp136-chart-library-install-pins`.

Decision 104 of 2026-11-23: everything confirmed under `deploy/` is fixed; the `infra/` copies in the chart stay
(DEP-04). ADR-0068 is reserved for you (write it for the library chart).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `deploy.md`
(DEP-01..12), verification `verify-deploy-infra-ci.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Library chart (DEP-01)**: helpers, `service.yaml` and `httproute.yaml` first (exact copies), then the near-copies
   of the three service sub-charts (about 300 lines). The rendered output must not change: `deploy/helm/tests/run.sh`
   green **without** `--update`; bump the chart version.
2. **Snapshots (DEP-03, INF-10 as corrected)**: five near-identical umbrella renders, each with the password blocklist
   (0.70 MB of 1.69 MB): keep the coverage, cut the repetition if it can be done without weakening a test.
3. **Install pins (DEP-02)**: the pins and the Reloader / Envoy Gateway blocks pasted into `kind/up.sh` and
   `cloud/install.sh` come from one sourced file; `just tofu-check` keeps policing what remains.
4. **The rest**: every other DEP finding of your scope, the Containerfiles included (layer order, repeated stages)
   where the verification confirms them.

Not yours: DEP-04: leave. DEP-07 (`KEYCLOAK_URL` in the chart) is WP139: do not rename variables.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `deploy/helm/tests/run.sh` green without `--update` after the library chart step
- [ ] `deploy/kind/up.sh --deploy` and `deploy/kind/smoke.sh` green on a fresh cluster (evidence in the handover);
      `helm lint` and kubeconform as the tests run them
- [ ] `scripts/build-images.sh` builds every image you touched
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
