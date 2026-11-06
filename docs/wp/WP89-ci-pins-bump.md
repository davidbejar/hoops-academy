# WP89 — CI: scheduled bump of image digests, chart image tags and kind pins

Model: Sonnet. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged (WP83 owns the workflows in wave 1);
runs alongside WP73/74/75 (web), WP80 (services), WP86 (chart + kind: it edits `deploy/helm/hoops/values.yaml` and
`deploy/kind/up.sh`; you only READ them from your script, you do not edit them this wave; if a pin needs a format
change for your script, say so in the handover). You own a new `.github/workflows/bump-pins.yml`, `scripts/bump-pins.sh`
(+ a small Python helper if needed, stdlib only), `docs/runbooks/release.md` section "Pins and bumps",
`.github/dependabot.yml` (comment pointing at the new workflow). Depends on: WP30 (image pins), WP50 (actions pinned
to SHAs), WP43 (Dependabot). Skills: owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp89-ci-pins-bump`, branch `wp89-ci-pins-bump`.

Decision 63 of 2026-11-06: a scheduled bump of what Dependabot does not cover: Containerfile ARG image digests
(`deploy/containers/*.Containerfile`), chart image tags/digests (`deploy/helm/hoops/values.yaml`: redis, redpanda,
mailpit, the ESO/Reloader/collector pins), kind pins (`deploy/kind/up.sh`: Envoy Gateway, Gateway API, CNPG, ESO,
Reloader), the Trivy/ZAP/Lighthouse/Semgrep container tags in workflows and scripts.

## Scope
1. **Script** `scripts/bump-pins.sh`: inventory of every pin (one table in the script header: file, pattern, how to
   resolve the latest: `skopeo inspect` in a container for digests, GitHub releases API for versions, Helm repo index
   for charts); `--check` prints what is outdated (exit 1 if any), `--apply` rewrites the files (digest and tag
   together; same-major only by default, `--major` to allow). Idempotent, shellcheck clean, runs with Podman locally.
2. **Workflow** `bump-pins.yml`: weekly schedule + manual dispatch; runs `--check` then `--apply`, opens one PR per
   run with the diff and the release links (`peter-evans/create-pull-request` pinned to a SHA, or `gh pr create`), labels
   `dependencies`; never pushes to main; `actionlint` clean; minimal `permissions`.
3. **Docs**: `release.md` "Pins and bumps" (what is bumped where, how to run locally, that chart/kind proofs must
   follow a bump of Envoy Gateway / CNPG / ESO before merging).

## Acceptance
- [ ] `scripts/bump-pins.sh --check` run locally lists the current state (output in the handover); `--apply` on a
      throwaway copy produces a sane diff (do not commit the bumped files: the PR does that later)
- [ ] `actionlint` and `shellcheck -S warning` clean; every action pinned to a commit SHA with a version comment
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
