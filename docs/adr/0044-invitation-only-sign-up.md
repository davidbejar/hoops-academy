# ADR-0044: Invitation-only sign-up: a public academy request, the super admin's decision, decision e-mails

- Status: Accepted (WP90, core 3.3.0)
- Date: 2026-11-07
- Records: decisions 51 and 58 of 2026-11-06 (`docs/wp/FOLLOW-UPS.md`)
- Amends: ADR-0024 §8 ("No e-mail at all from core": core now sends the two decision e-mails below, never a password)
- Related: ADR-0013 (onboarding saga), ADR-0023 (super admin manages administrators), ADR-0024 / ADR-0028 (temporary
  passwords), ADR-0029 (audit trail), ADR-0033 (gateway rate limits), ADR-0045 (SAST acceptances), WP70 (landing form)

## Context
The landing page (WP70) has an invitation form that sent nothing. Decision 51: a visitor asks for a new academy with
name, e-mail, role and academy name; the super admin accepts (the existing "create academy" logic, temporary password)
or rejects. Decision 58: anyone with an admin, coach or parent role may ask; on acceptance the requester becomes the
academy's first ADMIN; a rejection is e-mailed with the reason; players never ask. It is the platform's first operation
without sign-in.

## Decision
1. **One public operation.** `POST /platform/academy-requests` (`submitAcademyRequest`, `security: []`): name
   (optional), e-mail, role ∈ ADMIN | COACH | PARENT, academy name, the page's language, a honeypot `website`. Everything
   else under `/platform` stays `super_admin`. The contract conventions test lists the public operations by name
   (`PUBLIC_OPERATIONS`) and requires each to be an explicitly anonymous `/platform` operation that says
   "Authz: anonymous". The resource method carries `@PermitAll` (the class `@RolesAllowed(super_admin)`); the Semgrep
   rule `hoops-permitall-on-api-resource` keeps firing on it and is accepted for this one method in
   `.semgrep/accepted.json` (reason + expiry, ADR-0045), so any other `@PermitAll` still fails the gate.
2. **No enumeration, no mail relay.** Every valid request is answered `202 {"status":"RECEIVED"}`, whether it was
   stored, dropped by the honeypot, or dropped as the fourth pending request of the same e-mail (case-insensitive). The
   answer never depends on the e-mail (already a login, already asked). The only conflict is the academy name (409
   `ACADEMY_NAME_TAKEN`), which decision 51 wants checked against existing academies; a name is a public fact. Nothing
   is e-mailed on submission: the endpoint cannot be used to send mail to a third party.
3. **Input limits.** Bean validation (400): name ≤ 120, e-mail ≤ 254 (`@Email`, no whitespace), academy name 1..120,
   honeypot ≤ 2048, no control or format characters (`\p{Cc}`, `\p{Cf}`: line breaks, NUL, bidi overrides) in name and
   academy name. The domain (`Requester`, `AcademyName`) applies the same rules again, trims and collapses whitespace.
   The 2 MB body limit stays.
4. **Rate limit at the gateway.** The chart's core route gets one `rateLimits` entry: the exact path
   `/platform/academy-requests`, 10 requests/minute and 2/second per client IP, global (ADR-0033). The route matches
   every method, so the super admin's list (`GET`, same path) shares the counter; a human browsing the workbench stays
   far below it; accept and reject (`/{id}:accept|reject`) are not limited. The compose nginx has no rule for it (local
   only; see the WP90 handover).
5. **Data: a platform table.** `core.academy_request` (V17) belongs to no tenant: RLS forced with a policy for
   core_platform only (core_app has no privilege at all), declared as a global table in `CoreRlsSchemaMetaTest` and
   pinned by `AcademyRequestRlsTest`. core_platform may insert and read, and update only the decision columns (column
   grants): the requester's data is immutable; nobody but core_migrator deletes. A check constraint keeps the
   decision complete (PENDING has none; ACCEPTED has who, when and the academy; REJECTED who, when and the reason).
6. **One name rule.** `core.academy_name_key(name)` = trimmed, inner whitespace collapsed, lower-cased, used by a
   partial unique index (`status in (PENDING, ACCEPTED)`, so a rejection frees the name) and by the check against the
   tenant registry (expression index on `core.tenant`). The application never compares names itself.
7. **Accept = claim, onboard, record, mail.** (a) A transaction claims the PENDING request for a freshly chosen
   academy id (conditional update; a second accept gets 409 `REQUEST_NOT_PENDING` before any side effect) and checks
   that no academy got the name meanwhile (409 `ACADEMY_NAME_TAKEN`). (b) `CreateTenant` runs unchanged with that id
   (saga of ADR-0013): the request's academy name and e-mail, the slug, time zone, default language and the
   administrator's names from the super admin (the workbench pre-fills them; the administrator's language defaults to
   the request's). The requester is the first ADMIN whatever role they gave (decision 58). Any failure (409
   `SLUG_TAKEN`, 422, 502 from Keycloak) puts the request back to PENDING. (c) The audit row
   `tenant.request_accepted` (target the academy, metadata `academyRequestId`, `requesterRole`, actor the super admin)
   goes into the new academy's trail (ADR-0029). (d) The acceptance e-mail.
   The temporary password of a new login is returned once (`temporaryPassword`, `Cache-Control: no-store`, ADR-0024);
   an existing login is linked and gets none.
8. **Reject = decide, mail.** The reason (1..500 characters, line breaks allowed) is stored with who and when. There is
   no academy, hence no audit-trail row: the immutable request row is the record of the rejection.
9. **Decision e-mails.** `quarkus-mailer` over SMTP from the environment (`SMTP_HOST`, `SMTP_PORT`, `SMTP_START_TLS`,
   `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM`; defaults reach compose's MailHog), plain text from Qute templates in
   the request's language (es / en / id). Subjects are constants; requester input reaches only the body and the
   recipient (already validated). The acceptance mail gives the sign-in address (`HOOPS_PUBLIC_URL/login`) and the
   login (the e-mail), and says the temporary password comes separately, privately — never the password itself. The
   rejection mail carries the reason. The e-mail is sent after the decision is committed; when the mail server refuses
   or is down, the decision stands, `notifiedAt` stays null (the workbench shows it) and a warning without the address
   is logged. No retry in v1.

## Threats considered
| Threat | Control |
|---|---|
| Spam / bulk requests | gateway limit per IP (10/min, 2/s), honeypot, at most 3 pending requests per e-mail, nothing happens until a human decides |
| Account or e-mail enumeration | one 202 for every valid body; no mail on submission |
| Mail relay / mail bombing of a third party | no mail on submission; decision mails only after a super admin's action |
| Header injection | constant subjects; e-mail pattern without whitespace or control characters; no control characters in names |
| Name squatting | a pending request holds a name; the super admin rejects and the name is free again |
| Pre-account hijacking (someone requests with another person's e-mail) | the super admin decides; the temporary password goes to the super admin, who passes it on privately (ADR-0024's accepted risk, unchanged) |
| Double accept (two tabs, two admins) | the claim is a conditional update; the loser gets 409 before anything is created |
| Personal data of non-members | stored only in the platform table, read only by the super admin; no retention job in v1 (as the audit trail) |

## Alternatives rejected
- **A confirmation e-mail on submission** (double opt-in): it would make the public endpoint a mail sender for any
  address; the owner wanted easy sign-up and a human decision anyway.
- **Creating the academy at once and holding it disabled**: tenants, logins and outbox events for every bot request.
- **Hold a coach's or parent's request until an admin of the academy confirms** (an open option of decision 51): there
  is no admin yet; decision 58 makes the requester the first ADMIN.
- **An audit row for a rejection**: the trail is per academy (tenant_id not null, RLS); a platform trail for requests
  would duplicate the immutable request row.
- **A transactional mail outbox with retries**: two mails per request, a human waiting on the other end; the
  workbench shows an unsent mail and the super admin can write by hand.

## Consequences
- Core sends e-mail again (ADR-0024 §8 amended): the chart needs the SMTP settings for core (the WP90 handover lists
  them; Mailpit on kind is the realm's `mailhog:1025`).
- A request's personal data (name, e-mail) stays until a v2 purge job; FOLLOW-UPS lists it.
- A crash between the claim and the onboarding leaves an ACCEPTED request whose academy does not exist (the
  compensation never ran); the onboarding repair job (WP17) does not see it. Rare; the super admin creates the academy
  with `createTenant` by hand. Recorded as a follow-up.
