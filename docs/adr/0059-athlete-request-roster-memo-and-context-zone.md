# ADR-0059: athlete keeps roster answers for one request and takes the tenant zone from the caller's context

- Status: Accepted
- Date: 2026-11-23
- Related: ADR-0008 (roster from core, 30 s REST cache), ADR-0037 (roster replica, "no cache" on the replica),
  ADR-0042 (ended seasons are history), [WP127](../wp/WP127-athlete-roster-reads-zone-gate.md), audit 2026-11-23
  ATH-01, ATH-03

## Context
Since WP98 athlete reads rosters from its local replica by default. A roster read there is three or four SQL
statements and nothing is cached (ADR-0037 §6), while the access rules were written for the cached REST source: one
request asks for the same team's roster several times (an ADMIN recording attendance: three times; a parent listing
plan assignments: once per linked player and team with assignments, 160 statements in the audit's example).

Every use case that needed a date also read the tenant's zone from `athlete.tenant_registry`, although the request's
`AuthzContext` carries it: core's contract requires `timezone`, and the replica resolver always sets it. The registry
fallback for "an older core" no longer had a reason, and a stale or missing registry row gave a wrong date.

## Decision
1. **Roster answers live for one request.** The `RosterPort` the use cases get keeps each `teamRoster` answer (a roster
   or "not found") per tenant and team for the rest of the request, on both sources. Nothing outlives the request, so
   ADR-0037's "no cache" for the replica still holds between requests; a 503 is not kept. Outside a request (the
   nightly job, the replica consumer) every call reads the source.
2. **"Which of these teams have one of these players"** is a port operation (`RosterPort.teamsOf`): one query on the
   replica, the cached fan-out on REST. `AuthzContext.playerTeamIds` is not a substitute: it leaves out teams whose
   season ended, which a parent still sees assignments of.
3. **The tenant zone of a request is `AuthzContext.timezone`**, read without a query. The registry's zone is for the
   jobs only. `hoops.athlete.default-timezone` stays as the last resort for a zone this JVM does not know (common's
   client drops it); the "older core" fallback is gone. The registry row is written with the zone the requests use and
   only when it changed.

## Consequences
- A request sees one snapshot of each roster: a replica update arriving during the request shows from the next one.
- A `@QuarkusTest` method runs in a request context, so the memo spans the whole test method; tests of the REST
  adapter's cache use the adapter, not the produced port.
- The replica's `teamsOf` must follow the same rules as its rosters (open, valid assignments of complete players on
  known teams of an ACTIVE tenant); `RosterPortContract` and `ReplicaRosterRulesTest` pin them.
