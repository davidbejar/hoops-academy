# WP42 — kind: e2e mail checks through Mailpit, `tilt ci` on the Gateway API chart

Model: Sonnet. Wave 2 (2026-11-06): starts after WP40 is merged (the chart it verifies is the final one). You own
`e2e/`, `Tiltfile`, `deploy/kind/*` and the kind runbooks in this wave; you are the only agent using kind. Depends on:
WP36, WP40. Skills: podman-dev-env, verification-before-completion, systematic-debugging. Worktree:
`~/code/hoops-wt/wp42-kind-tilt`, branch `wp42-kind-tilt`.

Decision 22 of 2026-11-06: the e2e journey runs the mail checks on kind too, and the Tilt inner loop is verified
against the Gateway API chart.

## Scope
1. **Mail checks on kind**: on kind the SMTP sink is Mailpit behind Service `mailhog` (`deploy/helm/hoops/templates/
   mailpit.yaml`), whose HTTP API is `/api/v1/...`, not MailHog's `/api/v2/messages`; the journey therefore skips the
   mail steps there (WP36 handover). Make `e2e/src/test/java/com/hoopsacademy/e2e/support/MailHog.java` (rename to
   `MailSink` if the name becomes a lie) detect or configure which API it talks to (`E2eEnv`), and remove the skip, so
   the journey is 21/21 with the mail assertions on both compose and kind. Test the support class against both APIs
   (a small fake HTTP server in a unit test is enough; the journey itself is the integration proof).
2. **`tilt ci`**: `just kind-up` then `just tilt ci` (`Tiltfile`, `deploy/helm/hoops/values-kind.yaml`); fix what
   broke since WP30/WP36/WP40 (resource groups, the Gateway objects, Redis, port mappings) so it ends green; then
   `deploy/kind/smoke.sh core game athlete`. Record the runtime. Do not change the chart's behaviour outside kind.
3. **Journey on kind**: run it once through the Gateway on kind per `docs/runbooks/e2e.md` after `tilt ci` (or after
   `up.sh --deploy` if Tilt leaves the cluster in a different state): 21 tests, 0 skipped. Record the runtime.
4. **Docs**: `docs/runbooks/{e2e,kind}.md` (mail checks, Tilt flow), `docs/runbooks/troubleshooting.md` for anything
   you hit. Delete the cluster with `deploy/kind/down.sh` at the end.

## Acceptance
- [ ] Unit test of the mail support class against both API shapes, committed red first
- [ ] `just e2e` on compose 21/21 with mail checks; journey on kind 21/21, 0 skipped (runtime in the handover)
- [ ] `tilt ci` green on kind (runtime in the handover); smoke green
- [ ] `./mvnw -B -ntp -pl e2e -am verify -DskipTests` compiles (or the e2e module's own build command from the
      runbook); `shellcheck -S warning` clean on touched scripts
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
