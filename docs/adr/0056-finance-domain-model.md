# ADR-0056: The finance model: one currency, fee plans per cadence, dues per player and period, one payment each

- Status: Accepted
- Date: 2026-11-16
- Records: decisions 93-99 of 2026-11-15 and the choices WP118 made where they leave a gap (marked **choice**)
- Related: ADR-0051 §2 (finance in Go), ADR-0055 (stack), ADR-0037 (replicas), ADR-0017 (audit), ADR-0048 (exports),
  `libs/contracts/openapi/finance.yaml` 1.0.0, `docs/security/privacy-threat-model.md` (P-10, P-12),
  `docs/domain/authz-matrix.md` section Finance

## Context
Academies track what families owe and pay, and what the academy spends. The owner fixed the cadences (93), the currency
(94), payments (95), roles (96), joins and leaves (97), generation (98) and the expense categories (99). WP118 writes the
whole contract at once, because WP119 (dues, payments), WP121 (web), WP123 (expenses, balance, exports) build on it in
parallel; the model below is what they share.

## Decision
### Money (decision 94)
- One active **ISO 4217** currency per academy in `finance.settings`, chosen by ADMIN. Fund codes, metals, SDR, test
  codes and withdrawn currencies are refused (422 `UNKNOWN_CURRENCY`; **choice**: the list of `domain/currencies.go`, 2026).
- Every amount is an integer in the currency's **minor unit** (`amountMinor`); `minorDigits` (EUR 2, JPY 0, BHD 3) tells the
  web how to show it. Amounts are 1..10^11 minor units (a due is never changed to 0: waive it instead). No conversion.
- The currency is **fixed once the first due exists** (409 `CURRENCY_LOCKED`); a fee plan or an expense needs it chosen
  first (409 `CURRENCY_NOT_SET`).

### Fee plans and periods (decision 93)
- A plan charges the players of **one team, or of every team of one age category** of **one season** (exactly one target),
  an amount per period of its **cadence**: `MONTHLY`, `QUARTERLY`, `SEASON`.
- **Period keys**: a calendar month `YYYY-MM`; a calendar quarter `YYYY-Qn` (Q1 = January to March; **choice**: calendar
  quarters, not quarters counted from the season's start, so a key means the same in every academy); `SEASON` for the one
  period of a SEASON plan, whose dates are the season's (from the team replica). A period's days are its intersection with
  the season: a period wholly outside the season creates no dues.
- `firstPeriod` (required for MONTHLY / QUARTERLY) and `lastPeriod` (optional; none = to the end of the season) bound the
  plan; SEASON plans take neither.
- **Immutable** after creation: season, target, cadence (create another plan). `firstPeriod` is fixed once the plan has
  dues (409 `FEE_PLAN_HAS_DUES`); name, amount, `lastPeriod` and `autoGenerate` stay editable. A new amount applies to dues
  generated afterwards (**choice**); existing dues keep theirs.
- **Archive** (idempotent) stops all generation and keeps the dues; **delete** only a plan without dues (else 409).

### Dues (decisions 97 and 98) - built by WP119 on the tables of V3
- One due per **(plan, player, period)** (unique). A player is due for a period when on the roster of the plan's target on
  **any day** of the period within the season (open or closed assignment overlapping it), at the plan's full amount; no
  proration. A player on two teams of one category owes once; `team_id` is the first team found.
- **States**: `OPEN` → `PAID` (one payment) or `WAIVED` (ADMIN, with a reason; **choice**: final, a waived due is not
  reopened). While OPEN, ADMIN may **change the amount** with a reason (`reason` keeps the last one; the history is the audit
  trail); `planAmountMinor` keeps the plan's amount at generation.
- **Immutable**: plan, player, period and its dates.
- **Generation**: a daily job per academy in its time zone for plans with `autoGenerate` (not archived), single-run across
  replicas; and by hand per plan and period, with a preview. Both idempotent: a re-run creates only the missing dues.

### Payments (decision 95)
- A payment settles a due **in full**: its amount is the due's amount at that moment; method `CASH`, `BANK_TRANSFER`,
  `CARD`, `OTHER`; `paidOn` the day the family paid (not after today in the academy's zone, 422 `PAID_ON_IN_FUTURE`;
  **choice**); an optional note.
- At most **one valid payment** per due (partial unique index). **Voiding** keeps the payment with when, by whom and a
  reason, and makes the due OPEN again (409 `PAYMENT_ALREADY_VOIDED` the second time). No partial payments, no refunds.

### Reads (decision 96)
- ADMIN reads and writes everything.
- A team's current **COACH** reads `upToDate` per player of the team's current roster: false when the player has an OPEN due
  of a started period (period start on or before today, academy zone), of any plan. No amounts, plans, reasons, expenses
  or balance. ASSISTANT_COACH has no finance access.
- A **PARENT** reads the dues of linked players, a **PLAYER** their own: amount, status, period, plan name and the valid
  payment's day and method. **Choice**: never reasons, notes or voided payments (P-12 left "whether a family sees the
  reasons" open; the minimal answer was taken, WP119 may widen it with an additive contract change).

### Expenses and balance (decision 99) - built by WP123
- Categories fixed: `COURT_RENTAL`, `SALARIES`, `KIT`, `TOURNAMENT_FEES`, `TRAVEL`, `OTHER` (labels in the web). An expense
  has a day, category, amount, a description (1-120) and an optional note.
- The **season balance**: dues of the season's plans by status (PAID by the paid amount, OPEN, WAIVED), expenses whose day
  lies within the season's dates by category (all six, zero included), net = paid minus expenses.
- **Exports** by ADR-0048 (dues, expenses), 10,000 rows at most, audited, rate-limited at the gateway (chart 0.12.0, nginx);
  never reasons or notes.

### Privacy (WP112: P-10, P-12)
- **Reasons and notes** (waiver, amount change, void, payment note, expense note) are at most 200 characters and must hold
  no health or family details and no named person's salary; the contract says so on every such field. They are read by
  ADMIN only, and never written to logs, spans, audit metadata or exports.
- **The roster replica holds no birth date and no gender**: WP118's part (academies, members) keeps status, time zone,
  login, roles and the active flag only, not even names; WP119's players, teams, assignments, staff and guardian links keep
  what the reads need (a player's display name for the lists, dates of assignments and seasons), never birth date or gender.
- Retention of finance records stays with P-02 (not decided).

### Audit actions
`finance.settings_changed`, `fee_plan.created|updated|archived|unarchived|deleted` (WP118); `dues.generated`,
`due.amount_changed`, `due.waived`, `payment.recorded`, `payment.voided` (WP119); `expense.created|updated|deleted`,
`dues.exported`, `expenses.exported` (WP123). Metadata: ids, enum values, field names, counts.

## Alternatives rejected
- **Periods counted from the season's start**: the same key would mean different months in different academies, and a
  season changing its dates would move existing dues.
- **Several currencies or conversion**: not needed by an academy and a source of rounding questions (decision 94).
- **Partial payments and a payment ledger**: decision 95; a due is paid or not, which keeps the coach's status and the
  family view simple.

## Consequences
- WP119 fills `finance.due` and `finance.payment` (V3) and may add columns in V10-V19; WP123 adds `finance.expense` in
  V20-V29. Every new table goes through the Go RLS suites (`fixtureOverrides` for its check constraints).
- The contract is 1.0.0 for the whole service; operations not built yet answer 501 `NOT_IMPLEMENTED`; changes are additive
  (minor version) and regenerate `apps/web/packages/finance`.

## Amendment 2026-11-16 (WP119): what the dues, payments and reads needed
- **Roster replica** (V10, ADR-0037 rules): `player_ref` (person, display name, status), `team_ref` (season id and dates,
  age category; no team name), `team_player_ref` (team, player, `joined_on`, `left_on`, `invalid_reason`; no jersey or
  play-up levels), `team_staff_ref` (team, person, role), `guardian_link_ref` (guardian person, player); all tenant tables
  under the RLS suites, soft removals without state. Never a birth date or a gender: the decoder does not read them
  (`TestAPlayerEventDropsBirthDateAndGender`, P-10). V11 adds a member's `display_name` to `person_ref`, for the
  `PersonRef` of who recorded or voided a payment (empty until the member's next event or a replay). V12 indexes a due's
  payments.
- **Who owes** (**choice**): a valid assignment (`invalid_reason` null) of a player not removed, overlapping the window;
  `left_on` is the player's last day on the team (inclusive). A season's dates come from its teams in the replica; a
  season no team of which is known yet answers 422 `PERIOD_OUTSIDE_SEASON` ("the season's dates are not known yet").
  A due's `periodStart` / `periodEnd` are the window: the period's days within the season.
- **Generation order**: archived plan 409 `FEE_PLAN_ARCHIVED`, a key of another cadence 400, the season unknown or the
  period outside it 422, outside the plan 422 `PERIOD_OUTSIDE_PLAN`, more than 2,000 new dues 422 `TOO_MANY_DUES`.
  `existing` counts every due of the plan and period (also of players no longer on the roster); a due another run stored
  meanwhile (unique `(plan, player, period)`, `on conflict do nothing`) counts as existing, never twice.
- **The daily job** (decision 98): every instance ticks hourly (`FINANCE_DUES_JOB_INTERVAL`, 1m-24h; off with
  `FINANCE_DUES_JOB_ENABLED=false`); a run takes `pg_try_advisory_xact_lock` on `finance.dues-generation` (key: the first 8
  bytes of the name's SHA-256, as common-quarkus' `ExclusiveLocks`) in a lock transaction that binds no tenant and reads no
  table, and skips when another instance holds it (`TenantScope.runExclusive`'s pattern). The academies come from
  `finance.replica_tenant` (global, ids only, ADR-0037 amendment WP82); each is entered in its own transaction bound to it
  (never an unbound or nil tenant); only ACTIVE academies, on their own date (IANA zone of `tenant_ref`, the tz database
  embedded in the binary). It creates the dues of **every started period** of each automatic plan (first period up to the
  one containing today, within the season), so a roster change after a period started is caught by the next run; a re-run
  creates nothing. A period a rule refuses (`TOO_MANY_DUES`) is skipped and counted; a failing academy is logged and
  retried at the next tick, the others still run. Audit actor `system` without a person (`actor_person_id` null).
  Proof: `TestTheDuesJobRunsOnceAcrossInstancesAndIsIdempotent` (two pools, the lock held by one, then both at once),
  `TestTheJobUsesEachAcademysTimeZone`.
- **Payments**: the due is locked (`for update`) for every write; a void locks the payment, then its due. Order of answers:
  400 (input) - 404 - 409 (`DUE_NOT_OPEN`, `PAYMENT_ALREADY_VOIDED`) - 422 (`PAID_ON_IN_FUTURE`, today in the academy's
  zone).
- **The coach's status**: the team's roster today is its open, valid assignments of players not removed (ADR-0037 §6);
  "current coach" needs a `team_staff` row with role COACH (an ASSISTANT_COACH row does not count, even for a member who
  also holds the COACH role) for a team not removed whose season ends today or later. A COACH of another team gets 403
  (`fine_grained`) before any lookup, so an unknown team id tells nothing; ADMIN gets 404 for an unknown team.
- **The family's dues**: PARENT and PLAYER are checked against their relations before anything is read: another or an
  unknown player is 403 (`fine_grained`), never 404, so no answer tells whether a player exists. ADMIN asking for a
  player without dues gets an empty page. Reasons, notes and voided payments stay out (the choice above is kept).
  `playerName` is empty once the player is removed from core's roster (the due stays).
- **Audit metadata**: `dues.generated` (plan, period, count; target the plan), `due.amount_changed` / `due.waived` (due,
  plan, period), `payment.recorded` (due, payment, method; target the payment), `payment.voided` (due, payment). Never a
  reason, note or amount (`TestReasonsAndNotesNeverReachLogsOrAudit`).
