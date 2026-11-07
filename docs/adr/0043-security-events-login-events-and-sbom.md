# ADR-0043: Security events: Keycloak login events, authorization failures in the services, a CycloneDX SBOM per image

- Status: Accepted
- Date: 2026-11-07
- Related: decision 60 of 2026-11-06, WP85, ADR-0017 (observability defaults, JSON logs with `tenantId`), ADR-0034
  (token audience per service), ADR-0038 (realm hardening, `seed-users` patches the realm), ADR-0046 (logs over OTLP),
  `docs/runbooks/observability.md` "Security events", `docs/runbooks/release.md` "SBOM", ASVS 16.3.1, 16.3.2, V15

## Context
ASVS 16.3.1 (authentication operations logged, successful and failed) and 16.3.2 (failed authorization logged) were a
partial and a gap: the realm had no events, and a 401, 403 or 404 of the services left no trace beyond the HTTP status.
No image had an SBOM. Decision 60: Keycloak login events with retention, a structured event in the services for every
authorization failure, a CycloneDX SBOM per image in CI. Constraints: the logs leave the pod over OTLP (ADR-0046), so
whatever the events contain is shipped; the services have no personal data in logs (V14); this is a pet project with
easy sign-up, so the events are for investigation, not for blocking.

## Decision
### Keycloak (realm `academy`)
- `eventsEnabled` with `eventsExpiration` 30 days: the user events of `enabledEventTypes` are stored in Keycloak's
  database (admin console "Events", admin API `/events`) and deleted after 30 days. The list is the authentication
  operations: `LOGIN`, `LOGOUT`, `CODE_TO_TOKEN`, `CLIENT_LOGIN` (the services' tokens), `UPDATE_PASSWORD`,
  `RESET_PASSWORD`, `SEND_RESET_PASSWORD`, `UPDATE_CREDENTIAL` / `REMOVE_CREDENTIAL` and the deprecated `UPDATE_TOTP` /
  `REMOVE_TOTP` (OTP set-up, ADR-0038), `UPDATE_EMAIL`, `EXECUTE_ACTIONS` / `EXECUTE_ACTION_TOKEN` (the set-up mails),
  each with its `_ERROR`, plus `REFRESH_TOKEN_ERROR` (a reused refresh token, ADR-0034), `INTROSPECT_TOKEN_ERROR`,
  `LOGOUT_ERROR` and the brute-force lockouts `USER_DISABLED_BY_TEMPORARY_LOCKOUT` / `..._PERMANENT_LOCKOUT`.
  Successful refreshes are not stored (every tab every 5 minutes).
- `eventsListeners: [jboss-logging]`: every event of the realm (the listener sees all types, the list only filters the
  store) becomes a line of category `org.keycloak.events` in Keycloak's log, errors at WARN; successful ones at INFO via
  `KC_SPI_EVENTS_LISTENER__JBOSS_LOGGING__SUCCESS_LEVEL=info` (compose, chart, Testcontainers; Keycloak's default DEBUG
  drops them).
- Admin events on (`adminEventsEnabled`), **without representation** (`adminEventsDetailsEnabled: false`: the changed
  user's names and e-mail never reach the store or the log), stored 30 days (realm attribute `adminEventsExpiration`).
- `infra/keycloak/seed-users.sh` patches an existing compose realm from the realm file (other realm attributes are
  kept); kind imports the synced chart copy.
- **PII exception:** Keycloak's event lines carry the login's `username`, which is its e-mail (ADR-0023), and the client
  IP; that is what makes a credential-stuffing or lockout investigation possible, and Keycloak has no option to drop it.
  They live in Keycloak's log and its 30-day store only. Passwords and tokens are never in them
  (`RealmSecurityEventsKeycloakTest`).

### Services (library `common-quarkus`, every service)
- **One event per failure**: a WARN record of log category `hoops.security`, message
  `authz_denied kind=.. outcome=.. tenant=.. subject=.. roles=.. resource=".." reason=".."`, the same values as MDC
  fields for the duration of the record: `security.event` (`authz_denied`), `security.kind`, `security.outcome` (the HTTP
  status answered), `tenantId`, `security.subject`, `security.roles`, `security.resource`, `security.reason`. The JSON
  console log prints the MDC, the OTLP log handler exports it as attributes, so the events flow with the logs (ADR-0046)
  and are filtered by `security.event` or the category.
- **Kinds and where they are decided**: `unauthenticated` (401, no credentials: the tenant filter, Quarkus'
  `@Authenticated` / `@RolesAllowed` checks), `invalid_token` (401, Quarkus' `AuthenticationFailureEvent`; reason from
  jose4j's error codes: `expired`, `not_yet_valid`, `audience`, `signature`, `issuer`, `invalid`; and `no_sub`, a
  verified token without `sub`), `not_member` (404, the tenant filter), `tenant_mismatch` (404, a resolved membership of
  another tenant: never bound; before it was an `IllegalStateException`, 500), `role` (403, `@RequiresTenantRole`),
  `fine_grained` (403, every `AccessDeniedException` reaching the Problem mapper: `Authz.require` and the use cases),
  `realm_role` (403, `@RolesAllowed`: `super_admin` on /platform, `service` on /internal). Each failure is written once
  (the tests assert a single event per refused request).
- **What is written, and what never**: the subject is the token's `sub` (an id), roles are the tenant roles (realm
  roles for `realm_role`), the resource is `METHOD /route/{template}` (Quarkus' matched template; the concrete path only
  where no route matched yet, e.g. a token refused before routing), the reason a developer-written text or the jose4j
  reason. Never the token, a claim of an unverified token, an exception message (jose4j puts claims into them), a name
  or an e-mail. Values are stripped of control characters and quotes (log injection) and cut at 200 characters.
  Quarkus OIDC's own `Token verification has failed` WARN quotes the refused token (CWE-532); the library mutes that
  logger below ERROR (`io.quarkus.oidc.runtime.OidcProvider`), the `invalid_token` event replaces it.
- **Metric** `hoops_authz_denied_total{kind}` (Micrometer `hoops.authz.denied`, every kind registered at 0 at start so
  a rate is defined); scraped from `/q/metrics` like the others (ADR-0017).
- **Retention** of the services' events is the log backend's (ADR-0046: the chart ships them, the environment keeps
  them); not in the database. Admin actions stay in the audit trail (`core.audit_event`, 16.3.3), not duplicated here.

### SBOM
- **Services:** `cyclonedx-maven-plugin` 2.9.3 (pinned in the root pom, profile `sbom`) writes `target/bom.json`
  (CycloneDX 1.6, compile and runtime scope: what the fast-jar ships) in the image's own Maven stage; the Containerfile
  stage `sbom` holds only that file, `scripts/sbom.sh maven` builds it from the image build's cache and copies it out
  as `<svc>-maven.cdx.json` (`podman build --output` would be simpler but fails with a remote Podman, i.e. on macOS). A second SBOM of the
  whole image (UBI packages and jars) comes from Trivy (`<svc>-image.cdx.json`).
- **Web:** Trivy's CycloneDX of the image (`web-image.cdx.json`; the Flutter bundle has no package manager inside the
  image, so it lists nginx/Alpine).
- `scripts/sbom.sh` (Trivy as in the scan step, `cyclonedx-cli` 0.33.1 and ORAS 1.3.6 pinned by digest, in
  `scripts/bump-pins.sh`): `maven`, `generate`, `validate` (every file against the CycloneDX schema of its version, the job fails otherwise),
  `attach`. `images.yml` keeps the files as the workflow artifact `sbom-<image>` (90 days) and, when it pushes, attaches
  each SBOM to the pushed image digest as an **OCI referrer** (`oras attach`, artifact type
  `application/vnd.cyclonedx+json`). ghcr.io has no referrers API; ORAS then uses the OCI referrers tag schema
  (`sha256-<digest>` tag), which ghcr.io stores. Proven locally against a `registry:3` (referrers API) with
  `oras discover`; on ghcr.io not yet (the first push from main will show it). No signed attestation (no
  `actions/attest-sbom`, no cosign): that needs an id-token permission and a signing decision, left open.

## Consequences
- ASVS 16.3.1 met (Keycloak events + `invalid_token`), 16.3.2 met (every failure kind), V15 SBOM met for CI-built images.
- A realm change needs `just seed-users` on an existing compose stack, a fresh Keycloak database on kind
  (`IGNORE_EXISTING`, as ADR-0038).
- Every refused request now costs one WARN line; a scanner hammering the API produces as many lines as requests. The
  gateway's rate limits (ADR-0033) bound it; an alert on `rate(hoops_authz_denied_total[5m])` is the intended use.
- Keycloak's log is the container's stdout: on kind it is not exported over OTLP (Keycloak 26.8 can, with the
  `opentelemetry-logs` feature and `telemetry-logs-*` options; not wired, follow-up). Its 30-day store is queryable.
- New tenant-level checks get their events for free if they throw `AccessDeniedException` (403) or go through the
  tenant filter; a service that answers a denial in another way must call `SecurityEventLog.denied` itself.
- The SBOM steps add a cached `--target sbom` build, a Trivy run and the validation to each image job: 20 to 90 s per
  image locally (Trivy's first run downloads its Java index).
- Trivy 0.76 writes CycloneDX 1.7, the Maven plugin 1.6: `scripts/sbom.sh validate` checks each file against the
  schema of its own `specVersion` (1.6 or newer).
