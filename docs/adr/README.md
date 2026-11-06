# Architecture decision records

One file per decision, `NNNN-<slug>.md`, numbered in the order they were taken. A later ADR that changes an earlier one
says so in its header ("Supersedes", "Records"), and the earlier one carries an "amended by" note in its status line.

| ADR | Decision |
|---|---|
| [0001](0001-repo-outside-onedrive.md) | Source repository lives outside cloud-synced folders |
| [0002](0002-monorepo.md) | Single monorepo for services, frontend and infrastructure |
| [0003](0003-quarkus.md) | Quarkus 3.x on Java 21 for backend services |
| [0004](0004-flutter-web-pwa.md) | Flutter Web as the mobile-first PWA without a Node toolchain |
| [0005](0005-keycloak-authentication-only.md) | Keycloak for authentication; tenant roles owned by core-service |
| [0006](0006-rls-multitenancy.md) | Shared schema multitenancy with Postgres Row-Level Security |
| [0007](0007-three-services.md) | Three services for v1: core, game, athlete |
| [0008](0008-sync-rest-then-outbox.md) | Synchronous REST behind a RosterPort for v1; outbox + Redpanda for v2 (amended 2026-11-06: core outbox and publisher implemented, WP67) |
| [0009](0009-tenant-logo-in-postgres.md) | Academy logo stored in Postgres, served by core-service |
| [0010](0010-age-rule-birth-year-default.md) | Age categories computed by birth year vs season by default |
| [0011](0011-tenant-binding-in-transactions.md) | Binding the tenant to transactions and to Hibernate |
| [0012](0012-kubernetes-secrets-strategy.md) | Kubernetes secrets: Secrets from .env locally, External Secrets Operator beyond local (amended 2026-11-06: chart ExternalSecrets behind `externalSecrets.enabled`, Kubernetes-provider store on kind, WP65) |
| [0013](0013-core-onboarding-saga-and-membership-index.md) | Core onboarding saga, platform datasource reach and the cross-tenant membership index |
| [0014](0014-match-event-ingest-and-projection.md) | Match event ingest and projection semantics (offline-first statistics) |
| [0015](0015-roster-eligibility-engine-and-rollover.md) | Roster eligibility engine: season non-overlap, sticky invalidation, orphan scope, rollover |
| [0016](0016-wp2c-consolidation-contracts-2-shared-core-client-job-lock.md) | WP2c consolidation: contracts 2.0, shared core client, cluster-wide job lock |
| [0017](0017-audit-trail-observability-and-http-hardening.md) | Audit trail, observability defaults and service-level HTTP hardening |
| [0018](0018-web-offline-shell-service-worker.md) | Web offline shell: own caching service worker, no CDN, explicit update prompt |
| [0019](0019-web-session-and-sign-out.md) | Web session lifetime and sign-out semantics |
| [0020](0020-approval-workflow-and-player-lifecycle.md) | Approval workflow and player lifecycle (ADD / WITHDRAW, REJECTED, ORPHAN on creation) |
| [0021](0021-authorization-refinements-beyond-the-matrix.md) | Authorization refinements beyond the authz matrix |
| [0022](0022-login-experience-branded-keycloak-same-tab.md) | Login experience: branded Keycloak pages in the same tab, back to the app |
| [0023](0023-super-admin-manages-academy-admins-email-as-login.md) | Super admin manages academy administrators; e-mail as login; shared-login rule |
| [0024](0024-temporary-password-replaces-setup-email.md) | Temporary password at first sign-in replaces the setup and verification e-mails (amended: guardian logins, WP58; the `resendTenantAdminInvitation` alias removed by ADR-0035) |
| [0025](0025-one-login-many-academies-easy-sign-up.md) | One login, many academies; easy sign-up over account-linking safeguards |
| [0026](0026-shared-login-email-reaches-every-academy.md) | A shared login's e-mail change reaches every academy that uses it (same transaction, per-statement tenant binding) |
| [0027](0027-contracts-without-allof-composition.md) | Contracts without allOf composition, validated strictly everywhere |
| [0028](0028-temporary-password-expiry-without-a-scheduler.md) | Temporary passwords expire after three days, swept on events instead of a scheduler |
| [0029](0029-audit-trail-read-api.md) | Reading the audit trail: academy ADMINs under RLS, the super admin through a platform read policy (amended 2026-11-06: platform actors masked on the academy path) |
| [0030](0030-match-event-feed-filtered-by-player-visibility.md) | Match event feed filtered by player visibility (F-01) (amended 2026-11-06: the filter runs in SQL, WP60) |
| [0031](0031-gateway-api.md) | Gateway API with Envoy Gateway replaces ingress-nginx (routes, local rate limits per client IP, kind NodePort; its rate-limit decision replaced by ADR-0033) |
| [0032](0032-update-requests-clear-list.md) | Update requests name the fields to clear in a `clear` list (absent or null = unchanged; adopted by athlete 2.1.0, core 2.7.0, game 2.2.0) |
| [0033](0033-gateway-global-rate-limit.md) | Global rate limits at the gateway: Envoy rate limit service + Redis, shared by every Envoy replica, fail open (amended 2026-11-06: Redis ACL, per-second burst caps; chart 0.4.0) |
| [0034](0034-token-audience-per-service-and-refresh-token-rotation.md) | A token audience per service (least-privilege audience mappers, `quarkus.oidc.token.audience`) and refresh-token rotation with reuse detection; web tabs refresh one at a time (F-08, F-14); `deploy/kind/smoke.sh` checks each service's audience (WP56) |
| [0035](0035-core-3-removes-the-resend-invitation-alias.md) | Core 3.0.0 removes the deprecated `resendTenantAdminInvitation` alias (major bump, migration note) |
| [0036](0036-redpanda-event-broker.md) | Redpanda as the event broker (one node, own StatefulSet, same pin in compose, chart and Dev Services): topics `core.*` with one partition, key `<tenant id>:<aggregate id>`, compacted, SASL/SCRAM per service + ACLs + NetworkPolicy (chart switch `events.enabled` with its mirror `global.events.enabled`, services wired in chart 0.7.0, WP71) |
| [0037](0037-roster-replicas-from-core-events.md) | Roster replicas in game (WP68) and athlete (WP69) fed by core's events behind `RosterPort` (`hoops.roster.source`: `rest` or `replica`, default `rest`): tenant tables with RLS, idempotent upserts (known `eventId` skipped, older `occurredAt` never wins), soft removals, invalid events parked, a failed consumer turns the pod's health DOWN, replay = rebuild from the compacted topics |
| [0038](0038-keycloak-csp-password-blocklist-optional-otp.md) | Keycloak pages get a full realm CSP (residual `script-src 'unsafe-inline'`), the password policy a 10,000-entry blocklist, every login an optional TOTP set up from the account console (decision 39) |
| [0039](0039-localized-template-texts-accept-language.md) | Shared seed content (global plan templates) is localized on the server from `Accept-Language` (es / en / id, `en` fallback, stored locale not consulted), translations as jsonb on the existing tables; tenant content as stored (WP61, athlete 2.2.0) |
| [0040](0040-web-design-system.md) | Web design system: landing-page tokens (`HoopsColors`, spacing, radii, type, motion), a token-mapped Material 3 theme, a shared widget kit (`core/ui/kit.dart`), button orange `#C2410C` for AA, contrast proven by a test (WP72) |
| [0041](0041-sessions-reference-plans-directly-quick-add-copies.md) | A session references any readable plan or template directly (no assignment); `q` also finds plans by an item title (`matchedItems`); quick-add copies items into a tenant plan or into the session's own plan (created on first use, copy on write, deleted when left); no trigram index; catalogue deferred (WP78, athlete 2.3.0) |
| [0045](0045-sast-dast-gates-and-expiring-acceptances.md) | SAST and DAST gates in CI (WP83): SpotBugs + find-sec-bugs in `verify`, CodeQL `security-extended` (High/Critical), Semgrep with repository rules (ERROR), ZAP API scans per service after the e2e journeys (High/Medium); every acceptance carries a reason and (SARIF, pending fixes) an expiry, and never switches a rule off |