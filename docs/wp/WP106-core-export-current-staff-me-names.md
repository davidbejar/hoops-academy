# WP106 — Core: roster export for current staff only; given and family name in `/me`

Model: Opus · effort high. Wave 1 (2026-11-14, seventh round): runs alongside WP104 (OpenTofu, chart values), WP105
(web shell and theme) and WP107 (seed script, which only calls the API). You own `services/core-service/**`,
`libs/contracts/openapi/core.yaml`, the generated `apps/web/packages/core` (regenerate only yours:
`scripts/gen-api.sh core`), the roster-export row of `docs/domain/authz-matrix.md` and the amendment in
`docs/adr/0048-*.md`. You change no other web file: the web follows in WP108. Depends on: decisions 83 and 84,
ADR-0048 (exports), ADR-0042 (season history, `wasStaffOf`), ADR-0029 (audit), the WP96 and WP99 handovers. Skills:
quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp106-core-export-me`, branch `wp106-core-export-me`.

Decision 83 of 2026-11-14 (owner): the roster CSV with the guardians' contact data
(`GET /api/core/teams/{id}/roster:export`) is for the **team's current staff and ADMIN only**. A former coach keeps
the screens of an ended season (ADR-0042) but not the export. Amend ADR-0048; no new ADR.

Decision 84 of 2026-11-14 (owner): `/me` returns the **given and family name per membership**, so the web's "Your
name" form no longer splits the display name at the first space.

## Scope
1. **Export rule**: the role-matrix test for the export goes red first (a coach who was staff of the team in an ended
   season, a coach of another team, an assistant coach, ADMIN, PARENT, PLAYER, a non-member: 404, never 403 for a
   non-member, rule 3). Then the `Authz` check. The denied attempt is a security event like the other authorisation
   denials (ADR-0043). The matrix row and the ADR-0048 amendment say the same as the test.
2. **`/me`**: `givenName` and `familyName` per membership, additive, core minor version (3.5.0 → 3.6.0); the response
   stays valid against the contract in the tests; `PATCH /me` keeps working as it does. Contract first, then the
   resource.
3. **Dart package**: `scripts/gen-api.sh core`, commit `apps/web/packages/core` only; the web must still analyse and
   pass its tests unchanged (the change is additive).
4. **Docs**: the authz-matrix row, the ADR-0048 amendment (dated), nothing else.

## Acceptance
- [ ] Core contract 3.6.0 validated; Dart package regenerated and committed (only `packages/core`)
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [ ] `just mutation core-service` at or above baseline (record the score)
- [ ] Handover appended: the exact status a former coach gets from the export (WP108 hides the button on it), the
      shape of the new `/me` fields, anything the e2e journey or the seed (WP107) relies on that changed

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with a
  `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them.
  `apps/web/pubspec.lock`: commit it only with the generated package's version bump; revert other drift.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- **Built** (a red test commit before each change):
  - **Roster export, current staff only** (decision 83): `ExportTeamRoster` allows ADMIN (any team, ended seasons
    included) or a COACH with `isStaffOf(team)`; `wasStaffOf` no longer grants it. A former coach of an ended season
    gets **403** (`AccessDeniedException`, so a `fine_grained` security event, ADR-0043) and no audit row; a coach of
    another team 403; ASSISTANT_COACH, PARENT, PLAYER 403 (tenant role); a non-member 404. `TeamRosterExportTest`:
    the role matrix now takes the relation (current staff / former staff / none, 13 rows),
    `theFormerCoachOfAnEndedSeasonNoLongerExportsItsRosterButTheAdminDoes` (real ended season, security event fields),
    `aNonMemberGetsNotFoundNeverForbidden`. The authz-matrix row and an ADR-0048 amendment (2026-11-14) say the same;
    `ExportsContractTest` checks the operation's text.
  - **`/me` names** (decision 84), **contract core 3.6.0** (minor): `Membership.givenName` and `Membership.familyName`
    (string, never null) as that academy stores the caller's person, on GET and PATCH `/me`. Optional in the schema
    (not in `required`) so that a 3.5-shaped response, e.g. the web's demo mock, still parses; core always sends
    them. `MeView.OwnName`; `MeLookup` reads the person once per academy (also for the invitation acceptance).
    Tests: `MeNamesContractTest` (new), `MeResourceTest.eachMembershipCarriesTheGivenAndFamilyNameAsThatAcademyStoresThem`,
    `MeOwnNameTest` (the PATCH response carries the new name in the renamed academy only).
  - **Dart**: `scripts/gen-api.sh core`; `hoops_core_api` 3.6.0, `Membership.givenName` / `familyName` are `String?`;
    `pubspec.lock` only the version bump. Commits ran the git pre-commit hooks (gitleaks, whitespace fixers), which
    trimmed trailing whitespace in the touched generated files (`teams_api.dart`, `membership.dart`, `README.md`):
    the next regeneration shows whitespace-only diffs there; discard them.
- **Verified** (fresh, 2026-11-14): `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` BUILD SUCCESS, 3,388
  tests, 0 failures, 0 errors, 26 skipped, coverage gates met; `flutter analyze` no issues; `flutter test` (just
  web-test) 1,436 passed; `just mutation core-service` 925/926 killed (99 %, baseline 99; the changed classes are
  application code outside the PIT scope).
- **For WP108**:
  - Export: show the button only for ADMIN or a COACH whose `staffTeamIds` holds the team; a former coach
    (`historicStaffTeamIds`) now gets **403** Problem (`application/problem+json`, detail "Only ADMIN or the team's
    current coach may export its roster"). The web mock still allows it: `apps/web/lib/core/mock/mock_core_api.dart`
    `_exportRoster` must drop `authz.historicStaffTeamIds.contains(teamId)`.
  - `/me`: each `memberships[]` item now has `"givenName": "Ana María", "familyName": "de la Cruz"` next to
    `personId` (`api.Membership.givenName` / `.familyName`, nullable in Dart); the "Your name" form reads them instead
    of splitting `displayName`, falling back only when null. `lib/core/mock/mock_platform_api.dart` should add both to
    its `/me` memberships.
  - e2e journey and the WP107 seed: nothing they rely on changed (the journey reads `memberships.tenant.id`, roles
    and authz; no former-coach export).
- **Decisions/ADRs**: ADR-0048 amended (decision 83); no new ADR. Names optional in the schema (additive) is recorded
  in the contract's field descriptions.
- **Open points**: `docs/domain/audit-events.md` still reads "ADMIN or the team's COACH" for `team.roster_exported`
  (true; left as is, outside this brief's docs scope). No TODOs added.
