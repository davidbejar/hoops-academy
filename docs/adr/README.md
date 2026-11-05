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
| [0008](0008-sync-rest-then-outbox.md) | Synchronous REST behind a RosterPort for v1; outbox + Redpanda for v2 |
| [0009](0009-tenant-logo-in-postgres.md) | Academy logo stored in Postgres, served by core-service |
| [0010](0010-age-rule-birth-year-default.md) | Age categories computed by birth year vs season by default |
| [0011](0011-tenant-binding-in-transactions.md) | Binding the tenant to transactions and to Hibernate |
| [0012](0012-kubernetes-secrets-strategy.md) | Kubernetes secrets: Secrets from .env locally, External Secrets Operator beyond local |
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
| [0024](0024-temporary-password-replaces-setup-email.md) | Temporary password at first sign-in replaces the setup and verification e-mails |
| [0025](0025-one-login-many-academies-easy-sign-up.md) | One login, many academies; easy sign-up over account-linking safeguards |
| [0026](0026-shared-login-email-reaches-every-academy.md) | A shared login's e-mail change reaches every academy that uses it (same transaction, per-statement tenant binding) |
| [0027](0027-contracts-without-allof-composition.md) | Contracts without allOf composition, validated strictly everywhere |
| [0028](0028-temporary-password-expiry-without-a-scheduler.md) | Temporary passwords expire after three days, swept on events instead of a scheduler |
| [0030](0030-match-event-feed-filtered-by-player-visibility.md) | Match event feed filtered by player visibility (F-01) |
