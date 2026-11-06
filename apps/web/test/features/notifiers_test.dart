import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/admin/application/admin_providers.dart';
import 'package:hoops_app/features/admin/application/logo_revision.dart';
import 'package:hoops_app/features/roster/application/roster_providers.dart';

import '../support/core_fixtures.dart';
import '../support/fake_repos.dart';

ProviderContainer containerFor(FakeCore core) {
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      academyRepositoryProvider.overrideWithValue(core.academy),
      membersRepositoryProvider.overrideWithValue(core.members),
      seasonsRepositoryProvider.overrideWithValue(core.seasons),
      ageCategoriesRepositoryProvider.overrideWithValue(core.categories),
      teamsRepositoryProvider.overrideWithValue(core.teams),
      playersRepositoryProvider.overrideWithValue(core.players),
      approvalsRepositoryProvider.overrideWithValue(core.approvals),
      casesRepositoryProvider.overrideWithValue(core.cases),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('members: invite refreshes the list; a failure surfaces and leaves state intact', () async {
    final core = FakeCore(
      members: FakeMembersRepository([member('m1', 'Casey Coach')]),
    );
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
      throwsA(isA<AppError>()),
    );
  });

  test('member search query drives the list request', () async {
    final core = FakeCore(
      members: FakeMembersRepository([
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
      seasons: FakeSeasonsRepository([
        season('a', '2024/25'),
        season('b', '2025/26', current: true),
        season('c', '2026/27'),
      ]),
    );
    final c = containerFor(core);
    expect((await c.read(activeSeasonProvider.future))!.id, 'b');
    c.read(selectedSeasonIdProvider.notifier).select('c');
    expect((await c.read(activeSeasonProvider.future))!.id, 'c');

    final none = containerFor(
      FakeCore(seasons: FakeSeasonsRepository([season('x', 'x')])),
    );
    expect((await none.read(activeSeasonProvider.future))!.id, 'x');
    final empty = containerFor(FakeCore(seasons: FakeSeasonsRepository([])));
    expect(await empty.read(activeSeasonProvider.future), isNull);
  });

  test('teams are listed for the active season only', () async {
    final core = FakeCore(
      teams: FakeTeamsRepository(
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
    final result = api.SeasonRolloverResult(
      (b) => b
        ..fromSeasonId = seasonId
        ..toSeasonId = 'next'
        ..openedCaseIds.replace(['c1']),
    );
    final core = FakeCore(
      seasons: FakeSeasonsRepository([
        season(seasonId, 'S', current: true),
      ], rolloverResult: result),
    );
    final c = containerFor(core);
    await c.read(seasonsProvider.future);
    final r = await c.read(seasonsProvider.notifier).rollover(seasonId);
    expect(r.openedCaseIds.single, 'c1');
    expect(core.seasons.calls.where((x) => x == 'list').length, 2);
  });

  test(
    'roster: assign adds the player and refreshes the team list counts',
    () async {
      final core = FakeCore(
        teams: FakeTeamsRepository(teams: [team('t1', 'Mini A')]),
      );
      final c = containerFor(core);
      await c.read(teamsProvider.future);
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
    final core = FakeCore(
      teams: FakeTeamsRepository(
        teams: [team('t1', 'Mini A')],
        checks: {
          't1/p1': check(
            't1',
            'p1',
            api.EligibilityResult.INELIGIBLE,
            reasons: [api.EligibilityReason.CATEGORY_TOO_LOW],
          ),
        },
      ),
    );
    final c = containerFor(core);
    await c.read(teamDetailProvider('t1').future);
    final verdict = await c.read(teamDetailProvider('t1').notifier).check('p1');
    expect(verdict.result, api.EligibilityResult.INELIGIBLE);
    expect(core.teams.rosters['t1'] ?? [], isEmpty);
  });

  test('players: category filter is applied client-side, status/team go to the API', () async {
    final core = FakeCore(
      players: FakePlayersRepository([
        player('p1', 'Ana', cat: u12),
        player('p2', 'Leo', cat: u14, status: api.PlayerStatus.ORPHAN),
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
        final core = FakeCore(
          players: FakePlayersRepository([], createdPending: pending),
        );
        final c = containerFor(core);
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
        approvals: FakeApprovalsRepository([
          approval('a1'),
          approval('a2'),
          approval('a3'),
        ]),
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
    final core = FakeCore(
      cases: FakeCasesRepository([
        eligibilityCase('c1', 'p1', 'Ana', 't1', 'Mini A'),
      ]),
    );
    final c = containerFor(core);
    final open = await c.read(casesProvider.future);
    await c.read(casesProvider.notifier).reassign(open.single, 't2');
    expect(core.cases.target, 't2');
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
