# WP152 — Supply chain: digests, checksums and enforced lock files for what builds and what runs in a shell

Model: Sonnet · high. Wave 2 (2026-11-29, eleventh round): runs alongside WP151 (chart, kind) and WP154 (agent
guardrails). You own the pin lines (image tags and digests, tool versions, checksums) in `deploy/containers/**`,
`.github/workflows/**`, `.github/actions/**`, `.pre-commit-config.yaml`, `.mvn/**`, the docs site's requirement
files, `scripts/bump_pins.py` / `scripts/bump-pins.sh` and their tests; in workflow files you change pin lines and
install commands only, never jobs, triggers or permissions (WP153 restructures the workflows after you). In the chart
you may change image references and the CloudNativePG manifest source only; tell WP151 nothing else. Depends on:
WP148 (TM-04, TM-05) and WP149 (AG-12) with their evidence. Skills: work-package, owasp-security (its
config-and-supply-chain reference), test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp152-pins-digests-checksums-lockfiles`, branch `wp152-pins-digests-checksums-lockfiles`.

Decision 122 of 2026-11-28: the Medium findings are fixed in this round. No ADR is reserved: amend the ADR that
holds the pin policy if the policy changes.

## Scope
1. **TM-04**: every floating or tag-only pin the finding lists gets a digest or checksum that
   `scripts/bump_pins.py` tracks (the Maven builder image, nginx and its `apk upgrade`, Flutter, Trivy, Keycloak,
   the CloudNativePG image and its manifest fetched from a branch URL). Red first: a case in the pin tests that
   fails on a tag-only reference.
2. **TM-05**: `distributionSha256Sum` for the Maven wrapper; a Maven checksum policy that fails on a mismatch;
   `flutter pub get --enforce-lockfile` wherever CI, a Containerfile or a script resolves packages; the Semgrep
   rules pinned.
3. **AG-12**: the pre-commit hooks pinned by commit SHA, the docs site's Python dependencies installed with
   hashes.
4. **Docs**: the release and SAST runbooks where they list pins; the TM-04, TM-05 and AG-12 entries of the two
   threat models. An action pin is the dereferenced commit, never a tag object's SHA (`wp-round` Traps).

## Acceptance
- [ ] Red tests committed before each change; the pin tests under `scripts/tests` green
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals) with the checksum policy on;
      `just web-test` green; `just docs-build` green; `actionlint` clean
- [ ] One image built locally from each changed Containerfile (`scripts/build-images.sh`)
- [ ] Handover appended: every pin changed, and any the registry or tool could not give a digest for

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
