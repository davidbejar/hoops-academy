# WP90 — Invitation-only sign-up: request API, super admin workbench, landing form wired, rejection mail

Model: Opus. Wave 3 (2026-11-06, fifth round): starts after wave 2 is merged; runs alongside WP76 (web features
listed in its brief), WP82 (game + athlete), WP85 (`libs/common-quarkus`, realm). You own
`libs/contracts/openapi/core.yaml` + `apps/web/packages/core`, `services/core-service`, Flyway core `V17` (reserved;
`V16` is WP80's), `apps/web/lib/features/platform/**` (workbench) and `apps/web/lib/features/landing/**` (the
form only: wire it to the API, keep the look; WP77 moves the language switch in wave 4), `lib/core/mock` (mock
parity), `deploy/helm/hoops/values.yaml` rate-limit rule for the request endpoint ONLY (one list entry; no other chart
change), `docs/domain/authz-matrix.md` rows (append at the end). `lib/l10n/*.arb`: keys next to the landing /
platform keys. Depends on: decision 51 and 58, WP70 (form fields: name, e-mail, role, academy name), ADR-0024
(temporary passwords), ADR-0029 (audit), WP46 (rate limits), WP42 (Mailpit/MailHog: SMTP sink). ADR-0044 reserved for
you. Skills: quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, flutter-feature,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp90-invitation-signup`, branch
`wp90-invitation-signup`.

Decision 58 of 2026-11-06: anyone with an admin, coach or parent role may request a new academy; on acceptance the
requester becomes the academy's first ADMIN; rejection sends an e-mail with the reason; players never request.

## Scope
1. **Contract core → next minor** (WP81 took 3.1.0, WP80 3.2.0 if it changed core; take the next free minor): public
   `POST /platform/academy-requests` (no auth; name optional, e-mail, role ∈ ADMIN|COACH|PARENT, academy name unique
   against existing tenants and pending requests: 409; honeypot field + rate limit; 202 with no body that reveals
   existence); super admin `GET /platform/academy-requests?status=`, `POST .../{id}:accept` (creates the tenant as
   `POST /platform/tenants` does, the requester as its first ADMIN with a temporary password per ADR-0024, returned
   once), `POST .../{id}:reject` (reason, e-mail sent); audit rows (ADR-0029) for accept/reject.
2. **Data** (`V17`): `core.academy_request` (platform table, no tenant; status, timestamps, reason, requester
   fields, normalised academy name unique while pending/accepted); Problem types.
3. **Mail**: `quarkus-mailer` in core (SMTP from env: the compose MailHog, the chart's Mailpit; `.env.example` keys
   with placeholders; chart env/secret entries are WP87/86's files: put the needed keys in your handover and use
   existing SMTP values if the chart already has them for Keycloak) with es/en/id templates for rejection (and an
   acceptance mail with the login hint but never the password); `MailSinkTest`-style e2e check.
4. **Web**: the landing form posts to the API (success and error states, honeypot hidden); super admin workbench
   under `features/platform`: pending / accepted / rejected tabs, accept (shows the temporary password once, like
   the admins screen), reject with reason; demo mock parity.
5. **Security**: gateway rate limit for `/platform/academy-requests` (per IP, low), input length limits, no
   enumeration, audit; threat notes in ADR-0044.
6. **Docs**: ADR-0044; authz matrix rows; `docs/runbooks/onboard-tenant.md` section "Requests".

## Acceptance
- [ ] Contract validated; Dart core package regenerated and committed (only yours); `pubspec.lock` updated
- [ ] Red tests first; RLS/platform table conventions; `./mvnw -B -ntp -pl services/core-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals); `just mutation core-service` at or above baseline
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] `just e2e` 23/23 + a new journey step (request → accept → first login) on compose, mail checked in MailHog
      (coordinate the stack with WP82 and WP85 through the orchestrator); chart tests green with the rate-limit entry
- [ ] ADR-0044 indexed (append at the end of `docs/adr/README.md`); handover appended

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
- Built:
  - **Contract core 3.3.0** (`libs/contracts/openapi/core.yaml`, tag `AcademyRequests`): public `submitAcademyRequest`
    (`POST /platform/academy-requests`, `security: []`, 202 `{"status":"RECEIVED"}` whatever happened, 409
    `ACADEMY_NAME_TAKEN`), `listAcademyRequests` (`?status=`), `acceptAcademyRequest` (`…/{id}:accept`,
    `AcademyRequestAccepted` = request + tenant + `temporaryPassword` once, no-store; 409 `REQUEST_NOT_PENDING` /
    `SLUG_TAKEN` / `ACADEMY_NAME_TAKEN`, 422, 502), `rejectAcademyRequest` (`…/{id}:reject`, reason 1..500); audit action
    `tenant.request_accepted`. Contract tests: `AcademyRequestContractTest` (new); `OpenApiConventionsTest` lists the
    public operations by name (`PUBLIC_OPERATIONS`, must be explicitly anonymous `/platform` ops saying
    "Authz: anonymous"); `TemporaryPasswordContractTest` + accept; `AuditTrailContractTest` 30 actions;
    `SeasonHistoryContractTest` version check is now "at least" (it pinned 3.2.0 exactly). Dart client regenerated,
    `pubspec.lock` 3.3.0.
  - **Core**: `V17__academy_request.sql` (platform table, RLS forced, core_platform policy only, core_app nothing,
    requester columns immutable by column grants, no delete, decision check constraint; `core.academy_name_key()` used by
    a partial unique index on open requests and an expression index on `core.tenant`). Domain `domain.signup`
    (`AcademyRequest`, `Requester`, `AcademyName`, `RequesterRole`, …); use cases `SubmitAcademyRequest` (3 pending per
    e-mail, silent drop), `DecideAcademyRequest` + `AcademyRequestSteps` (claim → `CreateTenant.handle(id, …)` →
    audit → mail; a failed onboarding reopens the request); `PlatformAcademyRequestRepository` (native SQL, platform
    PU); `PlatformAcademyRequestResource` (class `@RolesAllowed(super_admin)`, only `submit` `@PermitAll`, honeypot
    `website` dropped in the adapter, bean validation without control/format characters); `MailAcademyRequestNotifier`
    (`quarkus-mailer`, plain-text Qute templates `templates/mail/academy-request-{accepted,rejected}.{es,en,id}.txt`,
    constant subjects, never the password, no address in logs; `notifiedAt` set only when sent).
  - **Web**: landing form posts the request (`features/landing/data|application`: `InvitationRepository`, outcome
    sent / academyTaken (message under the academy field) / failed (banner, values kept); hidden honeypot field; look
    unchanged). Workbench `features/platform/presentation/academy_requests_screen.dart` (Platform > Requests, chips
    Pending / Accepted / Rejected, accept = pre-filled form with suggested slug and split name → temporary password shown
    once via `announceLogin`, reject with reason, "E-mail not sent" chip, link to the academy). Mock parity in
    `MockPlatformApi` (seeded requests, submit / list / accept / reject). ARB keys es/en/id next to the landing and
    platform keys; copy file section 7 got the two server answers.
  - **Infra/docs**: one `rateLimits` entry (`/platform/academy-requests`, 10/min, 2/s per IP) + chart test line and
    snapshots; `.env.example` SMTP keys; ADR-0044 (+ index); authz matrix rows; audit-events row; runbook
    `onboard-tenant.md` "Requests"; `.semgrep/accepted.json` entry for the one `@PermitAll` (reason, expiry 2027-05-06).
  - **E2E**: JourneyTest steps 70-71 (anonymous request → 409 on the same name → accept → acceptance mail in MailHog
    without the password → first login as ADMIN; rejection mail with the reason); `MailSink.textTo` (MailHog QP /
    Mailpit) with tests; `Actor` accepts a null token (anonymous).
- Verified (2026-11-07, worktree `wp90-invitation-signup`, rebased on main after WP76):
  - Red first for the domain, contract and resource tests; `./mvnw -B -ntp -pl services/core-service -am verify
    -Dquarkus.http.test-port=0`: **core 963**, common 201, contracts 279, SpotBugs 0, coverage gates met.
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh): common 201, contracts 279, core 963, game 423,
    e2e 31 (25 skipped without a stack) green; **athlete-service 838 with 1 error**: `ReplicaAuthzRulesTest`, Dev Services
    Redpanda "localhost:2375 failed to respond" (Podman socket) at the same point in 3 module runs; the class alone
    passes 10/10; athlete-service has no change in this branch (`git diff main -- services/athlete-service` empty).
  - `just mutation core-service`: **622/629 (98.9 %)**, baseline 95; every `domain.signup` mutant killed (the 7 left are
    the older KafkaEventBroker / RosterEventAppender / Eligibility ones).
  - `flutter analyze` clean; `just web-format-check` 0 changed; `just web-test` (fresh) **997 passed**. New:
    academy_requests_test (11), academy_request_repository_test (3), acceptance_defaults_test (6),
    invitation_repository_test (5), mock_academy_requests_test (5), landing tests +5; goldens
    `platform_requests_{360x780,360x780_dark,1024x768}.png`; `platform_list_360x780{,_dark}.png` re-recorded (the new
    Requests button).
  - `just e2e` on compose (`QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future,*:missing'`): **JourneyTest 25/25**,
    MailSinkTest 6/6; both decision mails checked in MailHog.
  - Chart tests (`deploy/helm/tests/run.sh`): ALL CHART TESTS PASSED (176 ok). Semgrep (repo rules + p/java +
    p/owasp-top-ten) gate green with the one acceptance (24 of 24 accepted).
- Decisions/ADRs: ADR-0044 (amends ADR-0024 §8: core sends the two decision mails). No mail on submission; the
  requester is first ADMIN whatever role; a rejection has no academy audit row (the immutable request row is the
  record); claim-before-onboarding against double accepts; mail failures leave `notifiedAt` null (no retry).
- Open points / follow-ups:
  - **Chart (WP86/87's files)**: core needs `SMTP_HOST: mailhog`, `SMTP_PORT: "1025"` (kind's Mailpit Service keeps the
    realm's `mailhog:1025` name), `SMTP_START_TLS: OPTIONAL` (REQUIRED for a real server), `MAIL_FROM`,
    `HOOPS_PUBLIC_URL: '{{ .Values.global.publicUrl }}'`, and for a real server `SMTP_USERNAME` + a secretEnv
    `SMTP_PASSWORD` (e.g. Secret `hoops-smtp`, key `password`). Without them core falls back to `localhost:1025` and
    the decision mails fail (decisions still work, `notifiedAt` empty). Mailpit's NetworkPolicy already admits pods of
    the namespace.
  - Outside my file list but needed: `apps/web/lib/core/http/mock_api_adapter.dart` (anonymous POST of the request in
    mock mode; platform call extracted), `apps/web/lib/app/feature_modules.dart` (route `/platform/requests`),
    `libs/contracts` tests (above), `e2e/**`, `.semgrep/accepted.json`, `docs/marketing/landing-copy.md`.
  - Not done: the audit screen has no label for `tenant.request_accepted` (shows the wire name; `features/audit` was not
    mine: add `auditActionTenantRequestAccepted`); compose nginx has no `limit_req` for the public path (gateway only);
    `docs/quality/mutation.md` scores not updated (core now 622/629).
  - v2: purge of decided requests (personal data of non-members, no retention now); a crash between claim and
    onboarding leaves an ACCEPTED request without academy (runbook "Recovery"); mail retry.
  - athlete-service `ReplicaAuthzRulesTest` Podman-socket error in full module runs on this machine (see Verified).

