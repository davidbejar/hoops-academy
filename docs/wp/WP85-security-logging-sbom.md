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
- **Built**
  - `libs/common-quarkus` (additive; landed first at c402a7a): package `security` with `SecurityEventLog` (one WARN record,
    category `hoops.security`, fields in the MDC: `security.event/kind/outcome/subject/roles/resource/reason` + `tenantId`;
    Micrometer `hoops.authz.denied{kind}` = `hoops_authz_denied_total`, every kind registered at 0), `AuthzDenial` (pure;
    log-injection cleaning, 200-char cut), `DenialKind`, `TokenFailureReason` (jose4j codes, never messages),
    `QuarkusSecurityEvents` (observes `AuthenticationFailureEvent` / `AuthorizationFailureEvent`), `MissingSubjectException`.
    Hooks: `TenantHeaderFilter` (`unauthenticated`, `not_member`, new `tenant_mismatch`: a membership of another tenant is
    never bound, 404 instead of the former 500), `RequiresTenantRoleInterceptor` throws `TenantRoleDeniedException`
    (`role`), the Problem mapper logs every `AccessDeniedException` (`fine_grained`) and a token without `sub`
    (`invalid_token`/`no_sub`). Resource = `METHOD /route/{template}` (Quarkus' matched template). Library default mutes
    `io.quarkus.oidc.runtime.OidcProvider` below ERROR: its WARN quoted refused tokens (header + claims, CWE-532; found
    by a red test). Test-jar: `SecurityEventCapture`, `RealmTokens.passwordAttempt`, the success-level env in
    `RealmKeycloakResource`. PIT scope extended to the pure classes. No service `application.properties` change was needed.
  - Keycloak: realm `eventsEnabled`, 30-day `eventsExpiration`, `jboss-logging`, 32 `enabledEventTypes` (logins, logouts,
    code/refresh/client/introspect errors, password, credential/OTP, reset, e-mail, actions, lockouts), admin events on
    without representation, `adminEventsExpiration` 30 days; `KC_SPI_EVENTS_LISTENER__JBOSS_LOGGING__SUCCESS_LEVEL=info`
    in compose and the chart; `seed-users.sh` patches an existing realm; chart copy synced, 4 snapshots re-recorded.
  - SBOM: `cyclonedx-maven-plugin` 2.9.3 (root pom, profile `sbom`) in the image's Maven stage + Containerfile stage
    `sbom`; `scripts/sbom.sh` (`maven`, `generate` = Trivy image SBOM, `validate` = cyclonedx-cli against each file's
    spec version, `attach` = ORAS OCI referrer); `images.yml` runs them per image, uploads `sbom-<image>` (90 days),
    attaches on push. cyclonedx-cli 0.33.1 and ORAS v1.3.6 pinned by digest and added to `bump_pins.py`.
  - Docs: ADR-0043 (indexed), ASVS 16.3.1 / 16.3.2 / V15 Met, observability runbook "Security events", release runbook
    "SBOM" + pin table.
- **Verified**
  - Red first: common tests failed to compile / failed (incl. the OIDC token-quoting test) before the code.
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh, 2026-11-07): common 246, contracts 272, core 897,
    game 425, e2e module 27 (23 skipped without a stack), athlete 840 with 1 error: `ReplicaAuthzRulesTest` boot,
    Redpanda Dev Services "localhost:2375 failed to respond". Pre-existing: the same error at the same place on a clean
    checkout of main dc71f57 (athlete 838, 1 error); the class passes alone on this branch (10/10, twice). SpotBugs 0,
    JaCoCo gates met for every module that reached them. PIT common-quarkus 172/173 (99 %, the survivor is the old
    `CoreRosterClient` one).
  - `-Pkeycloak-it` (core, game, athlete): 43/43, incl. `RealmSecurityEventsKeycloakTest` 4/4 (failed login = WARN
    `LOGIN_ERROR` line + stored event, success = INFO line, 30-day config, admin event without representation, never
    the password).
  - New tests: `AuthzDenialTest` 15, `TokenFailureReasonTest` 13, `AuthzDenialEventsTest` 9, `InvalidTokenEventsTest` 7
    (real OIDC validation with a per-run key: expired, audience, signature, garbage, no token quoted anywhere),
    `MissingSubjectTest` +1, `SecurityEventsTest` 2 each in core / game / athlete, `RealmSecurityEventsPolicyTest` 3.
  - `just e2e` on compose: 23/23 (after `just seed-users`; Keycloak recreated with the new env). In the services' JSON
    logs of that run: core 21 / game 17 / athlete 5 events (`not_member`, `role`, `fine_grained`, `realm_role`,
    `unauthenticated`, `invalid_token`/`audience`), MDC fields present, route templates, 0 JWTs in any log; Keycloak
    logged `LOGIN`, `CLIENT_LOGIN`, `CODE_TO_TOKEN`, `UPDATE_PASSWORD`, `REFRESH_TOKEN_ERROR`, ...
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (after `--update`; diff = realm events + the env line).
    `seed-users.sh` against a throwaway Keycloak with the old realm: events config applied, other attributes kept.
  - SBOM evidence (local Podman, images built from this branch with the CI command): core 282 Maven / 422 image
    components, game 281 / 421, athlete 287 / 427, web 71 (`localhost/hoops/web:dev`); every file valid
    (Maven CycloneDX 1.6, Trivy 1.7); a corrupted file fails `validate` (exit 1). `attach` to a local `registry:3`:
    `oras discover` lists both game SBOMs and the web SBOM as `application/vnd.cyclonedx+json` referrers; a pulled
    referrer is byte-identical (sha256). 20-90 s per image.
  - Semgrep (repo rules + p/java + p/owasp-top-ten): gate passes, no finding in the new code; `actionlint` clean;
    `shellcheck scripts/sbom.sh` clean; `scripts/bump-pins.sh --check`: the new pins resolve and are current.
- **Decisions/ADRs**: ADR-0043. Category `hoops.security` (next to `hoops.audit`) rather than a bare `security`;
  `tenant_mismatch` is 404 + event (was 500); Keycloak event lines keep the login's e-mail (`username`) and IP, a stated
  PII exception; services log only the `sub`. SBOM attached as plain OCI referrers, not signed attestations.
- **Open points / follow-ups**
  - ghcr.io referrers are unproven until the first push from main (ORAS falls back to the referrers tag schema there).
  - No signed SBOM attestation (cosign / `actions/attest-sbom` need `id-token: write` and a signing decision).
  - Keycloak's log is not exported over OTLP on kind (Keycloak 26.8 `opentelemetry-logs` feature + `telemetry-logs-*`).
  - The pre-existing athlete `ReplicaAuthzRulesTest` boot failure (Redpanda Dev Services after an idle Docker API
    connection) belongs to the athlete owner: `ContainerStarts`-style retry for Dev Services, or a test order change.
  - Chart versions not bumped (keycloak template env + realm copy changed); bump with the next chart release.
  - Existing kind realms keep their settings until the Keycloak database is recreated (`IGNORE_EXISTING`, as ADR-0038).
