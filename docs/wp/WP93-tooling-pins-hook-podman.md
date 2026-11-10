# WP93 — Tooling: bump-pins fix, commit hook false positive, Podman machine drop-in

Model: Sonnet · effort medium. Wave 1 (2026-11-10, sixth round): runs alongside WP91 (core), WP92 (athlete,
training web), WP94 (model diagrams, one step in `ci.yml`), WP95 (web). You own `.github/workflows/bump-pins.yml`,
`scripts/bump_pins.py`, `scripts/bump-pins.sh`, `scripts/tests` for them, `.claude/hooks/**`, `scripts/hooks/**`,
`scripts/doctor.sh`, `infra/podman/**` (new), `docs/runbooks/local-stack.md` (the Podman section) and the
`podman-dev-env` skill file. Shared file: `justfile` (put a recipe next to the related ones; WP94 adds one too).
Depends on: WP89 (bump-pins), WP87 (the `--time=0` drop-in), FOLLOW-UPS "Infra, CI, e2e". Skills:
systematic-debugging, podman-dev-env, owasp-security (the hook is the tenancy gate), test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp93-tooling`, branch `wp93-tooling`.

Three independent fixes; commit each on its own.

## Scope
1. **bump-pins on the amd64 runner**. The first scheduled run failed (2026-11-09, run 42629848979): `exec container
   process /usr/bin/skopeo: Exec format error` and "image platform (linux/arm64/v8) does not match the expected
   platform (linux/amd64)". Cause to confirm first: `SKOPEO_IMAGE` in `scripts/bump_pins.py` is pinned to the
   digest of the arm64 image instead of the multi-arch index. Fix: pin the digest of the manifest list (check with
   `skopeo inspect --raw` that the pinned digest is an index holding both `amd64` and `arm64`), and check every
   other digest the script or the workflow *runs* for the same mistake. Add a test under `scripts/tests` that fails
   when a pin the script executes is a single-platform digest (or document why it cannot be tested offline and test
   the parsing part). `actionlint` clean. The orchestrator starts `gh workflow run bump-pins` after the merge.
2. **Hook false positive** (`.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash). Today `runs_git` greps the whole
   command text, so a command that only mentions the words runs the ~40 s to 3.5 min check. New rule: split the
   command into simple commands on `;`, `&&`, `||`, `|`, newlines and `$(`…`)`, drop quoted strings and comments,
   and match only when a simple command *is* a git commit or push. Write `scripts/hooks/tenancy-gate.test.sh` first
   (red), run by a new `just test-hooks` recipe, with at least these cases:

   | Command | Gate |
   |---|---|
   | `git commit -m x` | commit |
   | `git -C dir commit -m x` | commit |
   | `git -c user.name=a commit` | commit |
   | `git --no-pager commit` | commit |
   | `cd x && git commit --no-verify -m "a; b"` | commit |
   | `gitleaks protect --staged && git commit -m x` | commit |
   | `git push`, `git push origin a:main`, `git -C d push` | push |
   | `echo "=== git commit times"; git log` | none |
   | `git log --grep 'git push'` | none |
   | `# git commit` followed by `git status` | none |
   | `grep -n "git commit" file` | none |
   | `git commit-tree`, `git show-ref`, `git stash push` | none |
   | `FOO=1 git commit`, `env FOO=1 git push` | commit, push |

   When in doubt the gate must run: a false positive costs time, a false negative lets a commit skip the tenant
   isolation check. A command the parser cannot read (unbalanced quotes) is treated as a match. Keep the hook's
   result line as it is and make it one clear line the model can quote (`tenancy-gate: isolation-check PASSED in
   41 s`).
3. **Podman drop-in survives a re-init** (owner decision 2026-11-07, both parts).
   (A) `infra/podman/machine-playbook.yml`: writes
   `~core/.config/systemd/user/podman.service.d/no-timeout.conf` (`--time=0`) with explicit `core` ownership, for
   `podman machine init --playbook`. Find out whether Podman runs it as root or as `core` before relying on
   `systemctl --user`. Verify only with `ansible-playbook --check` inside the existing VM.
   (B) `scripts/doctor.sh`: read `systemctl --user cat podman.service` through one `podman machine ssh`; when
   `--time=0` is missing write the drop-in and `daemon-reload`; restart the service only when no container is
   running, otherwise print that a restart is pending; print the effective `ExecStart`.
   Docs: the init command in `docs/runbooks/local-stack.md`, a line in the `podman-dev-env` skill.

## Acceptance
- [ ] `just test-hooks` green with the table above; `shellcheck` clean on the files you changed if it is installed
- [ ] `python3 scripts/bump_pins.py --check` (or the script's own entry point) runs on this arm64 host; the pinned
      skopeo digest is a multi-arch index (paste the `inspect --raw` media type in the handover)
- [ ] `actionlint .github/workflows/*.yml` clean
- [ ] `just doctor` reports the drop-in present on the current machine
- [ ] Handover appended; no JVM or Flutter build is needed for this WP

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.
- **Other agents are building on the same Podman machine.** Do not remove the existing drop-in to test (B), do not
  restart `podman.service`, do not `podman machine stop/rm/init`. Test the "missing drop-in" and the "restart"
  branches of the doctor step with stubbed commands in a shell test; the orchestrator runs the real check in a
  quiet window.

## Handover
- Built:
  1. bump-pins: cause confirmed, `SKOPEO_IMAGE` pinned the arm64 manifest (`f42bdedc...`) of `skopeo/stable:v1.20.0`.
     Now the index `sha256:47853bb9...42f4` (amd64, arm64, ppc64le, s390x). `skopeo inspect --raw` media type of the new pin:
     `application/vnd.oci.image.index.v1+json`. Every other pin the repo executes (zaproxy, cyclonedx-cli, semgrep, oras,
     ubi9 openjdk-21-runtime, kindest/node) was checked: all are indexes with amd64 and arm64; redpanda and the OTel
     collector in values.yaml (outside the scan, checked by hand) too. New `scripts/tests/test_pins_multiarch.py`: offline parsing and
     pin-scan tests always; the registry check runs with `BUMP_PINS_ONLINE=1` (red before the fix, green after).
  2. Hook: `runs_git` replaced by a small parser (simple commands split on `; & | ( ) newline $( ` `, comments and quoted
     strings dropped, `VAR=`/env/time/sudo prefixes and git global options skipped). Unsure cases gate: unbalanced quotes,
     quoted or `$VAR` command word, `bash -c`/`sh -c`/eval/xargs wrappers and `$(...)` inside double quotes fall back to
     the old loose match. `TENANCY_GATE_CLASSIFY_ONLY=1` prints the classification (used by the test). Result line:
     `tenancy-gate: isolation-check PASSED in N s` (or `db-role-check`), on stderr. `gate()` stays fail-closed.
     `scripts/hooks/tenancy-gate.test.sh`: 39 table cases (all of the brief's plus unsure cases) and 3 end-to-end cases
     with stub gate scripts in a throwaway repo (pass, block, skip).
  3. Podman: `infra/podman/machine-playbook.yml` (absolute paths, `core` ownership, idempotent) and
     `ensure_podman_dropin` in `scripts/doctor.sh` (one ssh to read; write + daemon-reload only when missing; restart only
     when `podman ps -q` is empty, else "restart is pending"; prints the effective ExecStart). doctor.sh is sourceable
     now (main runs only when executed). Stub test `scripts/tests/doctor-podman-dropin.test.sh`. Docs: runbook section, skill line.
- Verified: `just test-hooks` green (matcher 42/42, doctor 5/5, python 24 tests, 1 skipped online test); online test green
  with `BUMP_PINS_ONLINE=1`; `shellcheck -x` clean on the changed shell files; `actionlint .github/workflows/*.yml` clean;
  `python3 scripts/bump_pins.py --check` runs on this arm64 host (5 of 14 outdated, no error); `just doctor` shows
  "podman API --time=0 drop-in present"; `ansible-playbook -i localhost, -c local --check --diff` inside the VM (as `core`):
  `ok=2 changed=0`. Not run: no JVM or Flutter build (not needed).
- Decisions/ADRs: none. Not verified: whether Podman runs `--playbook` as root or `core` at init (not observable without
  `podman machine init`, forbidden here); the playbook uses absolute paths and explicit ownership so both work, and was
  checked as `core` only. The real "missing drop-in" and "restart" branches of doctor ran only against stubs.
- Open points: after the merge run `gh workflow run bump-pins` (the ~PR it opens bumps Envoy Gateway etc.). Real doctor
  drop-in write/restart in a quiet window. The hook that gates the session is the one configured at session start;
  the new matcher applies once the merged `.claude/hooks/tenancy-gate.sh` is in the main checkout. A heredoc body
  containing `git commit` still gates (accepted false positive).
