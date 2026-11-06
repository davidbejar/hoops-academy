# WP85 — Security logging: Keycloak login events, authorization-failure events in the services, SBOM in CI

Model: Opus. Wave 3 (2026-11-06, fifth round): starts after wave 2 is merged; runs alongside WP76 (web), WP82 (game +
athlete), WP90 (core: it owns `services/core-service`; your change to `libs/common-quarkus` compiles into every
service, keep it additive and tell the orchestrator when it lands so WP82/WP90 rebase). You own
`libs/common-quarkus` (authz event logging), the three services' `application.properties` logging keys only,
`infra/keycloak/realm-academy.json` + `seed-users.sh` (events config) + chart realm copies (`scripts/sync-chart-files.sh`),
`.github/workflows/images.yml` (SBOM step), `docs/security/asvs-checklist.md` rows 16.3.1, 16.3.2, SBOM row,
`docs/runbooks/observability.md` section "Security events" (WP86 created the file), `docs/runbooks/release.md`
section "SBOM". Depends on: ADR-0034, ADR-0038, WP86 (OTel: the events should flow with the logs), WP50 (pins).
ADR-0043 reserved for you. Skills: owasp-security, test-driven-development, verification-before-completion.
Worktree: `~/code/hoops-wt/wp85-security-logging`, branch `wp85-security-logging`.

Decision 60 of 2026-11-06: Keycloak realm login events with retention and structured authorization-failure events in
the services (ASVS 16.3.1, 16.3.2); a CycloneDX SBOM per image in CI.

## Scope
1. **Keycloak**: realm `eventsEnabled`, `eventsListeners` (jboss-logging), `enabledEventTypes` (LOGIN, LOGIN_ERROR,
   LOGOUT, UPDATE_PASSWORD, UPDATE_TOTP, REMOVE_TOTP, CODE_TO_TOKEN_ERROR, REFRESH_TOKEN_ERROR, ...),
   `eventsExpiration` (e.g. 30 days), admin events on with representation off; `seed-users.sh` patches an existing
   realm; chart copies synced; a Keycloak test (`-Pkeycloak-it`) proves a failed login is logged.
2. **Services**: one structured event (JSON log line, category `security`, fields: kind, tenant id, subject, role,
   resource, outcome; never the token) for every authorization failure: non-member 404, role denial, `Authz` fine-grained
   denial, tenant mismatch, expired/invalid token (where the OIDC layer lets you hook), rate of failures as a metric
   `hoops_authz_denied_total{kind}`. Red tests in `libs/common-quarkus` and one per service through a real endpoint.
3. **SBOM**: CycloneDX for each service (`cyclonedx-maven-plugin` pinned, bound in the `images` build) and for the
   web image (syft or trivy `--format cyclonedx` in a pinned container), attached as workflow artifacts and pushed as
   OCI referrers/attestations next to the images if ghcr supports it with the current action (say what you did).
4. **Docs**: ADR-0043 (what is logged, PII rule, retention), ASVS rows, runbook sections. `actionlint` clean.

## Acceptance
- [ ] Red tests first; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals);
      `-Pkeycloak-it` for your Keycloak test green
- [ ] `deploy/helm/tests/run.sh` green after the realm sync; `just e2e` 23/23 on compose (coordinate the stack with
      WP82 and WP90 through the orchestrator)
- [ ] SBOM step proven locally (file produced per image, validated with `cyclonedx-cli` or trivy in a container)
- [ ] ADR-0043 indexed (append at the end of `docs/adr/README.md`); handover appended

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
