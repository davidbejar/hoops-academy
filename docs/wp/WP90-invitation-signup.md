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
