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

### Built
Every pin below carries a digest or a checksum, each is a `scripts/bump_pins.py` entry (27 entries now: 10 new, 5
extended; `--check` and `--apply` ran against the registries, `--apply` on a throwaway copy), and
`scripts/tests/test_supply_chain_pins.py` fails on a registry image without a digest (`BY_TAG` lists the exceptions with
reasons), on a `flutter pub get` without `--enforce-lockfile`, and on each other pin below.

| Pin | Old | New |
|---|---|---|
| Maven builder image (`service.Containerfile`) | `maven:3-eclipse-temurin-25` | `3.10.0-eclipse-temurin-25@sha256:84bd9615...d686` (3.10.2 is amd64 only: the bump skips a tag without amd64 and arm64) |
| nginx-unprivileged (`web.Containerfile`) | `1.30-alpine` | `1.30-alpine@sha256:f5116ed4...df03` |
| cirruslabs/flutter (`web.Containerfile`) | `:stable` | `3.44.0@sha256:46691e31...33f8` (same digest as `stable`) |
| Trivy (ci.yml, image-publish, sbom.sh, infra/tofu/check.sh) | `0.76.2` | `0.76.2@sha256:8f6bb947...68fb` |
| Keycloak (compose, chart values; templates render `digest`) | `26.8.2` | `26.8.2@sha256:7e66a96e...38b3`; `Chart.yaml` appVersion and `TestRealm.java` stay by tag, in their own entry |
| CNPG database image (`databases` values) | `19.0-minimal-trixie` | `...@sha256:12688a49...a2af` (entry runs after the PostgreSQL one and recomputes the digest of its tag) |
| Redis, Mailpit (chart values; mailpit template renders `digest`) | tag only (`digest: ""`) | `sha256:5af80107...3483`, `sha256:23a2ef85...1a4e` |
| Flutter in CI (`setup-flutter`) | subosito `channel: stable` | own install of 3.50.0 from the release archive, `sha256sum -c` `6ea2d806...f9f5` (the version `pubspec.lock` was resolved with), `actions/cache` for `~/.pub-cache` |
| CNPG operator manifest (`deploy/lib/platform.sh`) | `raw.githubusercontent.com/.../release-1.30/releases/cnpg-1.30.2.yaml`, no check | `releases/download/v1.30.2/cnpg-1.30.2.yaml`, `CNPG_MANIFEST_SHA256=ea4cc355...c68c` (the digest GitHub records for the asset; the same bytes as the branch file), checked before `kubectl apply` from a file |
| Maven wrapper | no checksum | `distributionSha256Sum=9c1ef917...adb5` (publisher's SHA-512 matched on the same download) |
| Maven | warns on a mismatch | `.mvn/maven.config` `-C` (strict checksums; also in the image build) |
| `flutter pub get` (ci.yml x2, e2e.yml, images.yml, web.Containerfile, Tiltfile, justfile, build-images.sh, start.sh) | plain | `--enforce-lockfile` |
| Semgrep rulesets p/java, p/rust, p/golang, p/owasp-top-ten | fetched live | `scripts/semgrep-rules.sh` fetches them against the SHA-256 in `.semgrep/registry-rules.txt` and stops on a change; `sarif-gate.py --strip-rule-prefix semgrep-registry.` keeps the rule ids of `.semgrep/accepted.json` |
| pre-commit gitleaks | `v8.30.0` | `6eaad039...` `# frozen: v8.30.0` (the tag object is `2ca41cc1`, not pinned) |
| pre-commit-hooks | `v6.0.0` | `3e8a8703...` `# frozen: v6.0.0` |
| docs site requirements | versions only | 11 packages, 314 `--hash=sha256` lines (every file of every version), `pip install --require-hashes`; `scripts/docs_requirements.py` writes them |

Docs: ADR-0068 amendment (the pin policy), `docs/runbooks/release.md` section 6, `docs/runbooks/docs-site.md`,
`docs/security/sast-dast.md`, TM-04 and TM-05 (rows and findings), AG-12.

### Verified
- `python3 -I -m unittest discover -s scripts/tests`: 174 tests, 1 skipped (the online multi-arch check), green. The red
  tests are commit `cd6534d6` (31 failures and 13 errors before the change). The tests for `--strip-rule-prefix`, the
  semgrep fetch script and the rewrite of the new pins were written with their code, not before it.
- `BUMP_PINS_ONLINE=1 python3 -I -m unittest discover -s scripts/tests -p test_pins_multiarch.py` (5 tests, 68 s, not
  skipped; `SCANNED` now covers `.github/actions`, `deploy/lib` and `deploy/helm/hoops`) and `scripts/bump-pins.sh
  --check` against the live registries: every pinned digest is an index with amd64 and arm64; `--check` lists only unrelated bumps (Semgrep 1.187.0, LGTM 0.41.2,
  distroless digest, Maven 3.10.2, Flutter 3.50.1, gitleaks v8.30.1). `--apply --root <copy>` rewrote each new pin in each file.
- `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`, fresh, with `-C` on: BUILD SUCCESS, 15:15 min, 3794 tests
  (38, 346, 585, 530, 1028, 1267 per module), 0 failures, 0 errors, 32 skipped. A first run failed once in
  `InvalidTokenEventsTest` (Testcontainers Postgres start timeout under load 15); the module passed on the rerun.
- Checksum policy online, cold cache, `-C` from `.mvn/maven.config`: `libs/contracts package` (53 s) and the whole reactor's
  `dependency:go-offline` into an empty scratch `-Dmaven.repo.local` (BUILD SUCCESS, 3:31 min, 422 MB, what the
  `trivy-fs` job runs), then `-Psbom,security-scan dependency:resolve-plugins` into the same repository: no error.
  Mismatch proof on a file:// repository: without `-C` a wrong `.sha1` only warns and the build succeeds, with the
  repository's `.mvn/maven.config` it fails ("Checksum validation failed"). Wrapper: a scratch `MAVEN_USER_HOME` accepts
  the sum and refuses a wrong one ("Failed to validate Maven distribution SHA-256").
- `flutter pub get --enforce-lockfile` (Flutter 3.50.0) leaves `pubspec.lock` unchanged. `just web-test`: 1958 tests, all passed (4 min 48 s).
- `deploy/helm/tests/run.sh --update` then `run.sh`: ALL CHART TESTS PASSED; the snapshots change only in the image lines
  (Keycloak, Redis, Mailpit, CNPG image) of the four umbrella renders.
- Semgrep, on the final tree with the pinned image: the pinned-hash rulesets and the old live `--config p/...` command
  both ran 441 rules on 2474 files and found the same 27 results (same rule ids after stripping the prefix, same paths);
  the gate says "accepted in baseline: 26 of 26", no STALE entry. The four hashes matched the registry again on
  2026-11-29 at the end of the work (no drift yet).
- `infra/tofu/check.sh` (reads `platform.sh`, `sbom.sh`'s Trivy pin): TOFU CHECK PASSED; the five `*.test.sh` files of the
  `scripts` job pass; `scripts/sbom.sh generate` on the web test image with the digest-pinned Trivy: valid CycloneDX.
- `install_cnpg` applies a local file: `cloud_kubectl` (`deploy/cloud/lib.sh`) is a local `kubectl --kubeconfig`, as in
  kind, so a path works in both; its test uses stub `curl` and `kubectl` (match applies, mismatch never reaches kubectl).
- Docs: `just docs-build` in a fresh `.venv-docs` with `--require-hashes`: no issues; a wrong hash is refused.
- `actionlint`, `shellcheck` on the new shell: clean. Images built with `scripts/build-images.sh`: `athlete-service`
  (from the pinned Maven builder; the Maven stage read `.mvn/maven.config` on a warm `hoops-m2` cache mount, so that
  proves the file is used in the image, not a cold download; runs as 65532) and `web` (pinned nginx base, nginx 1.30.7; the
  pinned Trivy gate of `image-publish` on it: exit 0, no fixable HIGH or CRITICAL).

### Could not be pinned, and why
- `apk upgrade` and the nginx.org package in `web.Containerfile`: signed packages fetched at build time. Dropping them
  was tried: the pinned base still carries fixable HIGH CVEs (nginx 1.30.6, zlib 1.3.2-r0 per the pinned Trivy), so the
  gate would fail. Residual, written in TM-04, ADR-0068 and the release runbook.
- Envoy Gateway and ESO charts stay by version (ESO is in `deploy/kind/up.sh`, WP151's; Envoy's chart reference would
  need a digest form in `platform.sh` and a chart-kind variant of the bump). Not done.
- By tag on purpose (`BY_TAG`): compose `postgres` and `nginx`, the finance image check's `postgres` in `images.yml`,
  Lighthouse's two images, Keycloak's `Chart.yaml` appVersion and `TestRealm.java`, the Redpanda Dev Services tag.
- `cirruslabs/flutter`: its last tag is 3.44.0 (= `stable`), older than `pubspec.lock` needs (>= 3.47), so
  `WEB_SOURCE=flutter` cannot build the current app with any tag; pinned by digest all the same, no pipeline uses it.
- `gen-api.sh` runs `dart pub get` in generated client packages, which have no lock file.
- Maven `-C` does not re-verify artifacts already in a local repository.

### Open points and what only GitHub can prove
- **Not run by a pull request:** `images.yml` runs on a push to `main` that touches its paths (and `workflow_dispatch`),
  `mutation.yml` monthly and on dispatch. So these are proven only after the merge, or by dispatching `images.yml` on the
  branch (it pushes only on `main`): the Trivy pin in `image-publish` (used by `images.yml` only), `flutter pub get
  --enforce-lockfile` in `images.yml` and `mutation.yml`, the Maven image build with the pinned builder on amd64.
  `ci`, `e2e`, `codeql`, `semgrep` do run on the PR and cover `setup-flutter`, the Trivy fs pin, the Semgrep fetch.
- **For WP153 (workflow rule):** `semgrep.yml` gained one step (`scripts/semgrep-rules.sh`) and its scan and gate commands
  changed (`--config semgrep-registry/`, `--strip-rule-prefix`): more than pin lines, needed because the pin is a fetch.
  `setup-flutter` (a composite action) no longer uses `subosito/flutter-action` (Dependabot entry for it, if any, is moot).
- `setup-flutter` downloads the 1.5 GB archive per job (no SDK cache): job time and the extract step on a runner, and
  `flutter pub get --enforce-lockfile` with Flutter 3.50.0 on Linux (it ran green on macOS only).
- `scripts/semgrep-rules.sh` on a runner: the registry must serve the same bytes there as here. Until the weekly
  bump-pins PR is merged, a ruleset that changes upstream stops the `semgrep` job on every pull request ("changed upstream"):
  by design, and the cost of the pin. The code-scanning alert ids of the registry rules now start with `semgrep-registry.`.
- `docker run aquasec/trivy:...@sha256:...` in `ci.yml` and `image-publish`, the web job's Trivy gate with the pinned nginx
  base, `images.yml` building the Maven image on amd64.
- The pins in `ci.yml` (Trivy) are by hand under `bump-pins --skip-workflows`, like Semgrep's: the PR body lists them.
- Merge: the four umbrella snapshots conflict with WP151 if it re-records them (take both: `run.sh --update`);
  `keycloak.yaml` and `mailpit.yaml` templates changed on the image line only.
- Pre-commit: after the first commit with the new revs, pre-commit rebuilds the hook environments (one slow commit).
- No Node, no push, `main` untouched.
