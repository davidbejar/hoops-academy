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
- Built: `scripts/bump-pins.sh` (wrapper, shellcheck clean) + `scripts/bump_pins.py` (stdlib; inventory table in its header; 12 pins: UBI runtime, nginx, redis, redpanda, mailpit, Trivy, Semgrep, ZAP digest, Envoy Gateway, CNPG, ESO, Reloader chart+digest+image digest). `--check` (exit 1 if outdated, 2 on lookup/format failure), `--apply` (tag and digest together, all files of a pin), `--major`, `--markdown`, `--root`. Registry lookups: skopeo v1.20.0 in a pinned container (`CONTAINER_ENGINE`, default podman); GitHub releases API for versions. `.github/workflows/bump-pins.yml` (weekly + dispatch, minimal permissions, `peter-evans/create-pull-request` v8.1.1 pinned to its SHA, branch `chore/bump-pins`, label `dependencies`, never main). `docs/runbooks/release.md` section 6 "Pins and bumps"; dependabot.yml comment.
- Verified: `scripts/bump-pins.sh --check` on 2026-11-07 (exit 1):
  ```
  ok       ubi9 openjdk-21-runtime: 1.24 sha256:cfa544effa28
  ok       nginx-unprivileged: 1.30-alpine
  ok       redis (chart): 8.10.3-alpine
  ok       redpanda (chart): v26.2.6 sha256:8b1076e0d61b
  OUTDATED mailpit (chart): v1.32.0 -> v1.33.0
  OUTDATED trivy: 0.76.1 -> 0.76.2
  OUTDATED semgrep: 1.183.0 sha256:2e45517a85e1 -> 1.184.0 sha256:cc1b68266f26
  OUTDATED zaproxy stable: sha256:030d3df57735 -> sha256:9624669db72f
  OUTDATED Envoy Gateway: v1.9.3 -> v1.10.0
  ok       CloudNativePG: 1.30.1
  ok       External Secrets Operator: v2.14.0
  ok       Stakater Reloader: 2.2.19 sha256:dfa9fd167fc7
  5 outdated of 12 pins
  ```
  `--apply --root <throwaway copy>`: 6 files, 8 lines changed (Trivy in ci.yml + images.yml x2, Semgrep, mailpit, Envoy Gateway, ZAP in ci.yml + zap-api-scan.sh); `bash -n` on the bumped up.sh ok; second `--apply` gives an identical diff; `--check` on the applied copy: 0 outdated of 12. Reloader chart digest computed by the script equals the pinned one. `actionlint` (all workflows) and `shellcheck -S warning` clean; bump-pins.yml actions pinned to SHAs with version comments. The real files were not bumped.
- Decisions/ADRs: no ADR (tooling under decision 63). Same-major default; nginx follows even minors only (stable line); Gateway API is not bumped (must follow the Envoy Gateway matrix, ADR-0031); floating tags without a digest (Maven, Flutter) and Lighthouse (not pinned anywhere in the repo) are out of the inventory. Python helper used because regex multi-line rewrites and JSON are unwieldy in bash.
- Open points / follow-ups: (1) The Envoy Gateway v1.9.3 -> v1.10.0 shown above is a same-major minor: it needs the Gateway API matrix check and a kind proof before merging; the scheduled PR will propose it. (2) PRs opened with GITHUB_TOKEN do not trigger `ci`/`e2e`: either a PAT/GitHub App token later or close/reopen (documented). Repo setting "Allow Actions to create PRs" and a `dependencies` label must exist (documented). (3) The workflow was not run on GitHub (needs the merge). (4) Pin formats WP86 changes in values.yaml / up.sh must keep the shapes matched by `PINS` (the script exits 2 naming the pin otherwise). (5) A full `--check` takes ~90 s (one skopeo container per lookup).
