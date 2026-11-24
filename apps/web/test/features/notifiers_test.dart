import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/admin/application/admin_providers.dart';
import 'package:hoops_app/features/admin/application/logo_revision.dart';
import 'package:hoops_app/features/admin/data/academy_repository.dart';
import 'package:hoops_app/features/admin/data/age_categories_repository.dart';
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/admin/data/seasons_repository.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/roster/application/roster_providers.dart';
import 'package:hoops_app/features/roster/data/approvals_repository.dart';
import 'package:hoops_app/features/roster/data/cases_repository.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

import '../support/core_fixtures.dart';
import '../support/core_seed.dart';
import '../support/mock_backend.dart';

/// The providers over [core]: the migrated repositories are the app's own on a
/// backend seeded with it (ADR-0070), the rest still fakes.
ProviderContainer containerFor(FakeCore core, {MockBackend? backend}) {
  final b = backend ?? MockBackend();
  core.seed(b);
  const tenant = MockBackend.testTenantId;
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      academyRepositoryProvider.overrideWithValue(
        ApiAcademyRepository(b.coreApi(), tenant),
      ),
      membersRepositoryProvider.overrideWithValue(
        ApiMembersRepository(b.coreApi(), tenant),
      ),
      seasonsRepositoryProvider.overrideWithValue(
        ApiSeasonsRepository(b.coreApi(), tenant),
      ),
      ageCategoriesRepositoryProvider.overrideWithValue(
        ApiAgeCategoriesRepository(b.coreApi(), tenant),
      ),
      teamsRepositoryProvider.overrideWithValue(
        ApiTeamsRepository(b.coreApi(), tenant),
      ),
      playersRepositoryProvider.overrideWithValue(
        ApiPlayersRepository(b.coreApi(), tenant),
      ),
      approvalsRepositoryProvider.overrideWithValue(
        ApiApprovalsRepository(b.coreApi(), tenant),
      ),
      casesRepositoryProvider.overrideWithValue(
        ApiCasesRepository(b.coreApi(), tenant),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('members: invite refreshes the list; a failure surfaces and leaves state intact', () async {
    final core = FakeCore(members: MembersData([member('m1', 'Casey Coach')]));
    final c = containerFor(core);
    expect((await c.read(membersProvider.future)).length, 1);

    await c
        .read(membersProvider.notifier)
        .invite(
          givenName: 'Nora',
          familyName: 'Vega',
          email: 'n@x.io',
          roles: {api.TenantRole.PARENT},
        );
    expect(
      c.read(membersProvider).requireValue.map((m) => m.displayName),
      contains('Nora Vega'),
    );

    core.members.failWith = const AppError(kind: AppErrorKind.conflict);
    await expectLater(
      c.read(membersProvider.notifier).deactivate('m1'),
      // the repositories throw what Dio throws; the screens read it with
      // AppError.of
      throwsA(
        predicate((Object e) => AppError.of(e).kind == AppErrorKind.conflict),
      ),
    );
  });

  test('member search query drives the list request', () async {
    final core = FakeCore(
      members: MembersData([
        member('m1', 'Casey Coach'),
        member('m2', 'Pat Parent'),
      ]),
    );
    final c = containerFor(core);
    await c.read(membersProvider.future);
    c.read(memberQueryProvider.notifier).set('pat');
    final result = await c.read(membersProvider.future);
    expect(result.map((m) => m.displayName), ['Pat Parent']);
  });

  test('active season: selection beats current beats newest', () async {
    final core = FakeCore(
      seasons: [
        season('a', '2024/25'),
        season('b', '2025/26', current: true),
        season('c', '2026/27'),
      ],
    );
    final c = containerFor(core);
    expect((await c.read(activeSeasonProvider.future))!.id, 'b');
    c.read(selectedSeasonIdProvider.notifier).select('c');
    expect((await c.read(activeSeasonProvider.future))!.id, 'c');

    final none = containerFor(FakeCore(seasons: [season('x', 'x')]));
    expect((await none.read(activeSeasonProvider.future))!.id, 'x');
    final empty = containerFor(FakeCore(seasons: []));
    expect(await empty.read(activeSeasonProvider.future), isNull);
  });

  test('teams are listed for the active season only', () async {
    final core = FakeCore(
      teams: TeamsData(
        teams: [
          team('t1', 'Mini A'),
          team('t0', 'Old', sid: pastSeasonId),
        ],
      ),
    );
    final c = containerFor(core);
    expect((await c.read(teamsProvider.future)).map((t) => t.id), ['t1']);
  });

  test('rollover returns the orphan list and reloads seasons', () async {
    // Mini A (U12) with a player born in 2014: too old for it next season.
    final backend = MockBackend()
      ..seedTeams([team('t1', 'Mini A')])
      ..seedPlayers([
        player(
          'p1',
          'Ana Ruiz',
          teams: [assignment('t1', 'Mini A')],
        ).rebuild((b) => b.birthDate = api.Date(2014, 3, 4)),
      ]);
    final core = FakeCore(
      seasons: [
        season(seasonId, 'S', current: true),
        season(
          'season-2027',
          'Next',
          startsOn: api.Date(2027, 9, 1),
          endsOn: api.Date(2028, 6, 30),
          referenceYear: 2027,
        ),
      ],
    );
    final c = containerFor(core, backend: backend);
    await c.read(seasonsProvider.future);
    final r = await c
        .read(seasonsProvider.notifier)
        .rollover('season-2027', fromSeasonId: seasonId);
    expect(r.toSeasonId, 'season-2027');
    expect(r.orphans.single.player.displayName, 'Ana Ruiz');
    expect(r.openedCaseIds, hasLength(1));
    expect(backend.requestsTo('/api/core/seasons'), hasLength(2));
  });

  test(
    'roster: assign adds the player and refreshes the team list counts',
    () async {
      final core = FakeCore(
        teams: TeamsData(teams: [team('t1', 'Mini A')]),
        players: PlayersData([player('p9', 'Nico Paz')]),
      );
      final c = containerFor(core);
      await c.read(teamsProvider.future);
      c.listen(
        teamDetailProvider('t1'),
        (_, _) {},
      ); // auto-dispose, as on screen
      c.listen(
        teamDetailProvider('t1'),
        (_, _) {},
      ); // auto-dispose, as on screen
      await c.read(teamDetailProvider('t1').future);
      final notifier = c.read(teamDetailProvider('t1').notifier);

      await notifier.assign('p9', jerseyNumber: '4');
      expect(
        c
            .read(teamDetailProvider('t1'))
            .requireValue
            .roster
            .single
            .jerseyNumber,
        '4',
      );

      await notifier.setJersey('p9', '5');
      expect(
        c
            .read(teamDetailProvider('t1'))
            .requireValue
            .roster
            .single
            .jerseyNumber,
        '5',
      );

      await notifier.unassign('p9');
      expect(c.read(teamDetailProvider('t1')).requireValue.roster, isEmpty);
    },
  );

  test('eligibility check is forwarded without mutating the roster', () async {
    // Born in 2012: too old for Mini A (U12), the mock's verdict.
    final core = FakeCore(
      teams: TeamsData(teams: [team('t1', 'Mini A')]),
      players: PlayersData([
        player('p1', 'Ana').rebuild((b) => b.birthDate = api.Date(2012, 3, 4)),
      ]),
    );
    final c = containerFor(core);
    c.listen(teamDetailProvider('t1'), (_, _) {}); // auto-dispose, as on screen
    await c.read(teamDetailProvider('t1').future);
    final verdict = await c.read(teamDetailProvider('t1').notifier).check('p1');
    expect(verdict.result, api.EligibilityResult.INELIGIBLE);
    expect(verdict.reasons, [api.EligibilityReason.CATEGORY_TOO_LOW]);
    expect(core.teams.rosters['t1'] ?? [], isEmpty);
  });

  test('players: category filter is applied client-side, status/team go to the API', () async {
    final core = FakeCore(
      players: PlayersData([
        player('p1', 'Ana', cat: u12),
        // born in 2013: the mock places him in U14 (Infantil)
        player(
          'p2',
          'Leo',
          cat: u14,
          status: api.PlayerStatus.ORPHAN,
        ).rebuild((b) => b.birthDate = api.Date(2013, 3, 4)),
      ]),
    );
    final c = containerFor(core);
    expect((await c.read(playersProvider.future)).length, 2);

    c
        .read(playerFilterProvider.notifier)
        .set(const PlayerFilter(categoryId: catU14Id));
    expect((await c.read(playersProvider.future)).map((p) => p.id), ['p2']);

    c
        .read(playerFilterProvider.notifier)
        .set(const PlayerFilter(status: api.PlayerStatus.ORPHAN));
    await c.read(playersProvider.future);
    expect(core.players.lastStatus, api.PlayerStatus.ORPHAN);
  });

  test(
    'creating a player returns the command result (APPROVED vs PENDING)',
    () async {
      for (final pending in [false, true]) {
        // An admin's player is approved at once; a coach's is a request.
        final c = containerFor(
          FakeCore(),
          backend: MockBackend(
            roles: pending ? {TenantRole.coach} : {TenantRole.admin},
          ),
        );
        final r = await c
            .read(playersProvider.notifier)
            .create(
              api.CreatePlayerRequest(
                (b) => b
                  ..givenName = 'A'
                  ..familyName = 'B'
                  ..birthDate = api.Date(2014, 1, 1)
                  ..gender = api.Gender.FEMALE,
              ),
            );
        expect(
          r.approvalRequest.status,
          pending ? api.ApprovalStatus.PENDING : api.ApprovalStatus.APPROVED,
        );
      }
    },
  );

  test(
    'approvals: approve, reject and cancel update the request status',
    () async {
      final core = FakeCore(
        approvals: [approval('a1'), approval('a2'), approval('a3')],
      );
      final c = containerFor(core);
      await c.read(approvalsProvider.future);
      final n = c.read(approvalsProvider.notifier);
      await n.approve('a1');
      await n.reject('a2', note: 'no');
      await n.cancel('a3');
      expect(c.read(approvalsProvider).requireValue.map((r) => r.status), [
        api.ApprovalStatus.APPROVED,
        api.ApprovalStatus.REJECTED,
        api.ApprovalStatus.CANCELLED,
      ]);
    },
  );

  test('cases: only OPEN are listed; reassign sends the target team', () async {
    final backend = MockBackend()
      ..seedTeams([team('t1', 'Mini A'), team('t2', 'Mini B')])
      ..seedPlayers([player('p1', 'Ana')]);
    final core = FakeCore(
      cases: [eligibilityCase('c1', 'p1', 'Ana', 't1', 'Mini A')],
    );
    final c = containerFor(core, backend: backend);
    final open = await c.read(casesProvider.future);
    await c.read(casesProvider.notifier).reassign(open.single, 't2');
    expect(
      backend.lastBody(
        '/api/core/eligibility-cases/c1/resolve',
      )['targetTeamId'],
      't2',
    );
    expect(c.read(casesProvider).requireValue, isEmpty);
  });

  test(
    'academy: logo upload and removal bump the logo revision (cache busting)',
    () async {
      final core = FakeCore();
      final c = containerFor(core);
      await c.read(academyProvider.future);
      expect(c.read(logoRevisionProvider), 0);

      await c
          .read(academyProvider.notifier)
          .uploadLogo(
            PickedFile(name: 'a.png', bytes: Uint8List.fromList([1, 2, 3])),
            'image/png',
          );
      expect(c.read(logoRevisionProvider), 1);
      expect(c.read(academyProvider).requireValue.profile.hasLogo, isTrue);

      await c.read(academyProvider.notifier).removeLogo();
      expect(c.read(logoRevisionProvider), 2);
      expect(c.read(academyProvider).requireValue.profile.hasLogo, isFalse);
    },
  );
}
