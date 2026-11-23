# ADR-0066: the membership rule (authorisation context) once in common-quarkus, under mutation testing once

- Status: Accepted (amends ADR-0053, amendment section appended there)
- Date: 2026-11-24
- Related: ADR-0037 point 6 (the replicas reproduce core's `/internal` rules), ADR-0042 (historic staff teams),
  ADR-0053 (duplication gate: CPD per module), ADR-0059 (athlete's one `seasonEnds` read), ADR-0062 (the replica pipeline
  in common), `docs/domain/authz-matrix.md`, decision 107 of 2026-11-23,
  [WP134](../wp/WP134-replica-authz-rule-in-common.md), audit 2026-11-23 X-02, ATH-04

## Context
Every `/api/**` request of core, game and athlete starts with the same rule: from the membership tables, build the
caller's `AuthzContext` in the requested tenant, or answer "not a member" (404). Core wrote it in `MembershipLookup`
(behind its tenant filter and `/internal/authz`); game and athlete each wrote a `ReplicaAuthzResolver` over their roster
replica (the default source since ADR-0037's 2026-11-10 amendment). Three copies of the tenant-isolation rule, with
different port shapes; only game's was under PIT, athlete's had only a `@QuarkusTest`. A change of the rule (ADR-0042
was one) had to be made and proven three times. ADR-0053 left copies *between* modules to "a later look"; for this rule
the look is now.

Before moving anything, one table (`MembershipRuleContract` in common's test-jar, 17 cases from the authz matrix and
ADR-0042, a world in Asia/Jakarta at 20:00 UTC so that "today" differs between UTC and the academy) ran against the three
copies over in-memory ports. What it and the reading of the adapters found:

| # | Difference | core | game | athlete | Resolution |
|---|---|---|---|---|---|
| 1 | A staff row of a team the store does not know | historic staff team (every staff team not "not ended" counted as ended) | neither current nor historic | neither | **The replicas' answer**: an unknown team grants nothing (least privilege; ADR-0037's WP82 amendment already says so of a removed team). Unreachable in core (`team_staff` has a foreign key to `team`), so no behaviour of core changes; core now reads `seasonEnds` (one query, as before) |
| 2 | Where the ACTIVE check sits | `MembershipLookup` builds the context for any status and keeps the status beside it; the tenant filter, `/me` and the callers of `/internal/authz` drop non-ACTIVE | in the resolver, before anything about the person is read | same as game | **Both kept**: the library offers `resolve` (ACTIVE first, then the person) for the replicas and `contextOf` (a member already found) for core, whose `/internal/authz` contract reports the status. Same answer on every tenant filter (the table's SUSPENDED / WITHDRAWN / unknown rows pass on all three) |
| 3 | A replica team row without a season end (only removed rows have none) | n/a (`end_date not null`) | `seasonEnds` put the null in the map and `Collectors.toMap` threw: a 500 | the row is left out | **athlete's**: the port says "a team the store does not know is absent"; game's read now filters `season_end_date is not null` (red first: `AuthzContextContractTest.aReplicaTeamWithoutASeasonEndCountsForNothing`) |
| 4 | Tenant status in the replica | n/a | `TenantStatus.valueOf` (an unknown value throws) | `"ACTIVE".equals(status)` (an unknown value is inactive) | Both readers now map to common's `TenantStatus`; the column only ever holds the contract's enum (the decoder validates `core.tenant` against its schema), so no reachable case changes |
| 5 | A member with no role | impossible (`Person` needs one role) | possible (empty `roles` array) | possible | Not a rule difference: the rule does not branch on an empty role set (the context then grants nothing beyond membership). Left as is |

Everything else matched: the own player only with PLAYER, guardian links only with PARENT, staff rows read whatever the
roles (`AuthzContext.isStaffOf` asks for COACH or ASSISTANT_COACH), player teams from open valid assignments of the own
and linked players, a season current while it ends today or later in the academy's zone, one season read for both team
sets, no assignment read without players.

## Decision
1. **One rule in `com.hoopsacademy.common.authz`.** `MembershipRule` (pure, final, static) builds the context over two
   ports: `MemberRelations` (own player, guarded players, staff teams, open valid teams of players, season ends of
   teams; plain `UUID`s, the values `AuthzContext` carries, since common has no `PlayerId` / `TeamId`) and
   `MembershipReads extends MemberRelations` (+ the tenant's `TenantState(TenantStatus, ZoneId)` and the login's
   `Member(personId, roles)`). `resolve(subject, tenant, reads, clock)` answers the replicas' tenant filter;
   `contextOf(subject, tenant, zone, member, relations, clock)` serves core. The rule skips the assignment read without
   players and the season read without teams. It holds no state and caches nothing: every read goes through the
   caller's port in the caller's transaction, with the requested tenant bound (RLS), so nothing about one tenant can
   reach another through the shared code. Non-members still get 404 (the tenant filter is unchanged).
2. **Each service implements the ports over its own tables.** core: `CoreMemberRelations` over its repositories
   (`TeamRepository.seasonEnds` replaces `seasonNotEnded`); game: `JdbcMembershipReads` (the six membership queries
   leave `JdbcRosterReplicaRepository` / `RosterReplicaQueries`, `ReplicaPerson` goes); athlete:
   `ReplicaMembershipRepository` implements `MembershipReads` directly (`ReplicaMembershipReads` goes). The services'
   `ReplicaAuthzResolver`s stay as the `@Transactional` CDI bean the source selection picks, one line each.
3. **Proof.** The table runs once against the library (`MembershipRuleTest`, plus what the reads cost) and against
   core's lookup over its real adapter (`MembershipLookupRuleTest`, mocks of core's repositories). The services' own
   contract tests on a real database stay the proof of each port implementation: game `AuthzContextContractTest` (REST
   and replica), athlete `MembershipContract` (both sources) and `ReplicaAuthzRulesTest`, core's API and role-matrix
   tests, plus the new `TeamSeasonEndsTest`. The per-service rule tests (game `ReplicaAuthzResolverTest`, the
   characterisation subclasses of game and athlete) are gone with the copies.
4. **Mutation testing once.** `Member`, `MembershipRule*`, `MembershipReads*` are in common's PIT scope (threshold 99,
   as game's was for its copy); game's `ReplicaAuthzResolver*` / `ReplicaPerson*` entries are gone. athlete's copy,
   never under PIT, is gone too.
5. **The Go copy stays** (finance-service, ADR-0055: another language); a change of this rule names it in the same
   pull request.
6. **Amends ADR-0053**: a copy between modules of a tenant-isolation rule is not accepted; it lives in common with one
   table test and one PIT entry.

## Consequences
- A change of the rule is made and proven once; the three services follow at the next build.
- core's tenant filter, `/internal/authz` and `/me` answer as before (difference 1 is unreachable there); the replicas
  answer as before except game no longer fails on a team row without a season end.
- core's `TeamRepository` loses `seasonNotEnded` (its only caller was the lookup).
- `common.authz` depends on `common.client` for `TenantStatus` (no cycle; `CommonLibraryArchitectureTest`).

## Alternatives considered
- **The library rule as a CDI bean** used by all three: core needs the context for non-ACTIVE tenants (`/internal/authz`
  reports the status), and a bean in common is discovered by core too; a pure class with two entry points is simpler.
- **Generic ids (`MemberRelations<P, T>`)**: the context carries `UUID`s anyway; the generic noise buys nothing.
- **Running the table against each replica store on Postgres** (the audit's "abstract rules test in the test-jar"): the
  existing contract tests already run the same cases through events on both sources; a third harness per service was
  not worth its boot time.
