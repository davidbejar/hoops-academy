import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/features/health/application/health_providers.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/platform/application/platform_providers.dart';
import 'package:hoops_app/features/roster/application/roster_providers.dart';
import 'package:hoops_app/features/training/application/training_providers.dart';

import 'package:flutter_riverpod/misc.dart' show Override;

import '../support/athlete_scenarios.dart';
import '../support/fake_athlete.dart';
import '../support/fake_platform.dart';
import '../support/fake_repos.dart';

ProviderContainer _container(
  FakeAthlete a,
  Capabilities caps, {
  FakeCore? core,
  List<Override> more = const [],
}) {
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      capabilitiesProvider.overrideWithValue(caps),
      ...a.overrides,
      teamsRepositoryProvider.overrideWithValue((core ?? athleteCore()).teams),
      ...more,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('WeekSessionsNotifier', () {
    test('ADMIN: one query without team filter for the Monday..Sunday range', () async {
      final a = weekAthlete();
      final c = _container(a, const Capabilities(roles: {TenantRole.admin}));
      final list = await c.read(weekSessionsProvider.future);
      expect(list.map((s) => s.id), ['s1', 's3', 's2', 's4']); // by start time
      expect(a.training.sessionQueries.length, 1);
      final m = monday;
      final sun = m.add(const Duration(days: 6));
      String d(DateTime x) =>
          '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
      expect(a.training.sessionQueries.single, '*:${d(m)}..${d(sun)}');
    });

    test('results are sorted by start time', () async {
      final c = _container(
        weekAthlete(),
        const Capabilities(roles: {TenantRole.admin}),
      );
      final list = await c.read(weekSessionsProvider.future);
      expect(
        list.map((s) => s.startsAt).toList(),
        [...list.map((s) => s.startsAt)]..sort(),
      );
    });

    test('COACH of two teams queries both, not the whole academy', () async {
      final a = weekAthlete();
      final c = _container(
        a,
        const Capabilities(
          roles: {TenantRole.coach},
          staffTeamIds: {'t1', 't2'},
        ),
      );
      final list = await c.read(weekSessionsProvider.future);
      expect(a.training.sessionQueries.map((q) => q.split(':').first).toSet(), {
        't1',
        't2',
      });
      expect(list.length, 4);
    });

    test('team filter narrows to one team; week shift reloads', () async {
      final a = weekAthlete();
      final c = _container(a, const Capabilities(roles: {TenantRole.admin}));
      await c.read(weekSessionsProvider.future);
      c.read(calendarTeamProvider.notifier).select('t2');
      expect((await c.read(weekSessionsProvider.future)).map((s) => s.id), [
        's3',
      ]);
      c.read(weekStartProvider.notifier).shift(1);
      expect(await c.read(weekSessionsProvider.future), isEmpty);
    });

    test(
      'a repository failure surfaces as AsyncError and a retry recovers',
      () async {
        final a = weekAthlete()..training.failWith = StateError('down');
        final c = _container(a, const Capabilities(roles: {TenantRole.admin}));
        await expectLater(
          c.read(weekSessionsProvider.future),
          throwsStateError,
        );
        a.training.failWith = null;
        c.invalidate(weekSessionsProvider);
        expect((await c.read(weekSessionsProvider.future)).length, 4);
      },
    );
  });

  group('SessionDetailNotifier', () {
    test(
      'team staff gets the attendance and roster; a parent does not',
      () async {
        final a = weekAthlete()
          ..training.attendanceBySession['s1'] = [attEntry('p1')];
        final staff = _container(
          a,
          const Capabilities(roles: {TenantRole.coach}, staffTeamIds: {'t1'}),
        );
        final d = await staff.read(sessionDetailProvider('s1').future);
        expect(d.attendance!.entries.single.playerId, 'p1');
        expect(d.roster.map((p) => p.player.id), ['p1', 'p2', 'p3']);
        a.training.calls.clear();
        final parent = _container(
          a,
          const Capabilities(
            roles: {TenantRole.parent},
            linkedPlayerIds: {'p1'},
          ),
        );
        final pd = await parent.read(sessionDetailProvider('s1').future);
        expect(pd.attendance, isNull);
        expect(a.training.calls, ['session']);
      },
    );

    test('saveAttendance forwards the entries and refreshes', () async {
      final a = weekAthlete();
      final c = _container(a, const Capabilities(roles: {TenantRole.admin}));
      await c.read(sessionDetailProvider('s1').future);
      await c.read(sessionDetailProvider('s1').notifier).saveAttendance([
        ath.AttendanceInput(
          (b) => b
            ..playerId = 'p1'
            ..status = ath.AttendanceStatus.PRESENT,
        ),
      ]);
      expect(a.training.recorded!.single.playerId, 'p1');
      expect(
        (await c.read(sessionDetailProvider('s1').future))
            .attendance!
            .entries
            .single
            .status,
        ath.AttendanceStatus.PRESENT,
      );
    });
  });

  group('plans', () {
    test('PlanDetailNotifier.move sends the permutation and the library is invalidated', () async {
      final a = weekAthlete();
      final c = _container(a, const Capabilities(roles: {TenantRole.admin}));
      await c.read(planDetailProvider('plan-1').future);
      await c.read(planDetailProvider('plan-1').notifier).move(0, 1);
      expect(a.plans.lastOrder, ['i2', 'i1']);
      expect(
        (await c.read(planDetailProvider('plan-1').future)).items
            .map((i) => i.id),
        ['i2', 'i1'],
      );
    });

    test('library copy returns an editable copy of the template', () async {
      final plans = FakePlansRepository(
        plans: [
          planOf(
            'tpl',
            'Plantilla',
            template: true,
            items: [planItem('x', 'Bote', 0)],
          ),
        ],
      );
      final c = _container(
        FakeAthlete(plans: plans),
        const Capabilities(roles: {TenantRole.coach}, staffTeamIds: {'t1'}),
      );
      await c.read(planLibraryProvider(true).future);
      final copy = await c.read(planLibraryProvider(true).notifier).copy('tpl');
      expect(copy.template, isFalse);
      expect(copy.items.single.title, 'Bote');
      expect(
        (await c.read(planLibraryProvider(false).future)).map((p) => p.id),
        [copy.id],
      );
    });

    test(
      'AssignmentsView groups completions per assignment and player',
      () async {
        final plans = FakePlansRepository(plans: [planOf('p', 'P')]);
        plans.assignmentList.add(
          assignmentOf('as1', plans.planList.single, teamId: 't1'),
        );
        plans.completionList.addAll([
          completionOf('c1', 'as1', 'p1', ath.CompletionStatus.DONE),
          completionOf('c2', 'as1', 'p2', ath.CompletionStatus.DONE),
          completionOf('c3', 'as1', 'p3', ath.CompletionStatus.NOT_DONE),
        ]);
        final c = _container(
          FakeAthlete(plans: plans),
          const Capabilities(roles: {TenantRole.admin}),
        );
        final view = await c.read(assignmentsProvider(null).future);
        expect(view.countsFor('as1'), {
          ath.CompletionStatus.DONE: 2,
          ath.CompletionStatus.NOT_DONE: 1,
        });
        expect(
          view.completionOf('as1', 'p3')!.status,
          ath.CompletionStatus.NOT_DONE,
        );
        expect(view.completionOf('as1', 'p9'), isNull);
      },
    );

    test('record replaces the previous mark of the same player', () async {
      final plans = FakePlansRepository(plans: [planOf('p', 'P')]);
      plans.assignmentList.add(
        assignmentOf('as1', plans.planList.single, playerId: 'p1'),
      );
      final c = _container(
        FakeAthlete(plans: plans),
        const Capabilities(roles: {TenantRole.player}, ownPlayerId: 'p1'),
      );
      await c.read(assignmentsProvider('p1').future);
      final n = c.read(assignmentsProvider('p1').notifier);
      await n.record('as1', 'p1', ath.CompletionStatus.PARTIAL);
      await n.record('as1', 'p1', ath.CompletionStatus.DONE, comment: 'ok');
      final view = await c.read(assignmentsProvider('p1').future);
      expect(view.completions.single.status, ath.CompletionStatus.DONE);
    });
  });

  group('health', () {
    test('injuries newest first; recover refreshes the open-injury map used by the badge', () async {
      final health = FakeHealthRepository(
        injuries: [
          injury(
            'old',
            'p1',
            part: 'Tobillo',
            status: ath.InjuryStatus.RECOVERED,
          ),
          injury('open', 'p1', part: 'Rodilla'),
        ],
      );
      health.injuryList[0] = health.injuryList[0].rebuild(
        (b) => b.occurredOn = ath.Date(2026, 1, 1),
      );
      final c = _container(
        FakeAthlete(health: health),
        const Capabilities(roles: {TenantRole.admin}),
      );
      expect((await c.read(injuriesProvider('p1').future)).map((i) => i.id), [
        'open',
        'old',
      ]);
      expect((await c.read(openInjuriesProvider.future)).keys, ['p1']);
      await c
          .read(injuriesProvider('p1').notifier)
          .recover('open', DateTime(2026, 11, 2));
      expect((await c.read(openInjuriesProvider.future)), isEmpty);
    });

    test('measurements are ordered oldest first for the chart', () async {
      final health = FakeHealthRepository(
        measurements: [
          measurement('b', 'p1', ath.Date(2026, 6, 1), height: 144),
          measurement('a', 'p1', ath.Date(2026, 1, 1), height: 140),
        ],
      );
      final c = _container(
        FakeAthlete(health: health),
        const Capabilities(roles: {TenantRole.admin}),
      );
      expect(
        (await c.read(measurementsProvider('p1').future)).map((m) => m.id),
        ['a', 'b'],
      );
      await c
          .read(measurementsProvider('p1').notifier)
          .add(measuredOn: DateTime(2026, 11, 1), heightCm: 150);
      expect(
        (await c.read(measurementsProvider('p1').future))
            .map((m) => m.heightCm),
        [140, 144, 150],
      );
    });

    test(
      'adding a test result returns the stored result with its expected band',
      () async {
        final jump = testType('ty', 'VJ', 'Salto', 'cm');
        final fitness = FakeFitnessRepository(
          types: [jump],
          norms: [
            norm(
              'n',
              'ty',
              band: ath.NormBand.EXCELLENT,
              min: 40,
              max: 80,
              pending: true,
            ),
          ],
        );
        final c = _container(
          FakeAthlete(fitness: fitness),
          const Capabilities(roles: {TenantRole.admin}),
        );
        final r = await c
            .read(testResultsProvider('p1').notifier)
            .add(
              testTypeId: 'ty',
              measuredOn: DateTime(2026, 11, 1),
              value: 45,
            );
        expect(r.expectedBand, ath.NormBand.EXCELLENT);
        expect(r.referencePending, isTrue);
        expect(
          (await c.read(testResultsProvider('p1').future)).single.id,
          r.id,
        );
      },
    );

    test('norm filter drives the repository scope', () async {
      final fitness = FakeFitnessRepository(
        norms: [norm('g', 'ty'), norm('t', 'ty', global: false)],
      );
      final c = _container(
        FakeAthlete(fitness: fitness),
        const Capabilities(roles: {TenantRole.admin}),
      );
      expect((await c.read(normsProvider.future)).length, 2);
      c
          .read(normFilterProvider.notifier)
          .set(const NormFilter(scope: 'TENANT'));
      expect((await c.read(normsProvider.future)).map((n) => n.id), ['t']);
      expect(fitness.normScopes, ['EFFECTIVE', 'TENANT']);
    });
  });

  group('platform', () {
    ProviderContainer platformContainer(FakePlatformRepository repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [platformRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('create refreshes the list; filters are passed through', () async {
      final repo = FakePlatformRepository(tenants: [tenantOf('a', 'Alfa')]);
      final c = platformContainer(repo);
      expect((await c.read(tenantsProvider.future)).length, 1);
      await c
          .read(tenantsProvider.notifier)
          .create(
            name: 'Beta',
            slug: 'beta',
            timezone: 'Europe/Madrid',
            locale: api.ApiLocale.es,
            adminEmail: 'x@y.zz',
            adminGivenName: 'X',
            adminFamilyName: 'Y',
          );
      expect((await c.read(tenantsProvider.future)).length, 2);
      expect(repo.created!.firstAdmin.locale, api.ApiLocale.es);
      c
          .read(tenantFilterProvider.notifier)
          .set(
            const TenantFilter(
              status: api.TenantStatus.SUSPENDED,
              query: ' be ',
            ),
          );
      await c.read(tenantsProvider.future);
      expect(
        (repo.lastStatusFilter, repo.lastQuery),
        (api.TenantStatus.SUSPENDED, 'be'),
      );
    });

    test('detail keeps the tenant when usage fails; suspend/reactivate refresh both', () async {
      final repo = FakePlatformRepository(tenants: [tenantOf('a', 'Alfa')])
        ..usageFails = true;
      final c = platformContainer(repo);
      final d = await c.read(tenantDetailProvider('a').future);
      expect(d.usage, isNull);
      expect(d.usageError, isNotNull);
      repo.usageFails = false;
      await c.read(tenantDetailProvider('a').notifier).suspend('Impago');
      final after = await c.read(tenantDetailProvider('a').future);
      expect(after.tenant.status, api.TenantStatus.SUSPENDED);
      expect(after.usage, isNotNull);
      await c.read(tenantDetailProvider('a').notifier).reactivate();
      expect(
        (await c.read(tenantDetailProvider('a').future)).tenant.status,
        api.TenantStatus.ACTIVE,
      );
    });
  });

  group('Capabilities (athlete)', () {
    const admin = Capabilities(roles: {TenantRole.admin});
    const coach = Capabilities(roles: {TenantRole.coach}, staffTeamIds: {'t1'});
    const assistant = Capabilities(
      roles: {TenantRole.assistantCoach},
      staffTeamIds: {'t1'},
    );
    const parent = Capabilities(
      roles: {TenantRole.parent},
      linkedPlayerIds: {'p1'},
    );
    const player = Capabilities(roles: {TenantRole.player}, ownPlayerId: 'p9');

    test('training: admin all teams, staff own teams, family none', () {
      expect(admin.canManageTraining('any'), isTrue);
      expect(coach.canManageTraining('t1'), isTrue);
      expect(coach.canManageTraining('t2'), isFalse);
      expect(assistant.canManageTraining('t1'), isTrue);
      expect(parent.canManageTraining('t1'), isFalse);
      expect(player.canManageTraining('t1'), isFalse);
    });

    test('absences / completion: parent linked only, player self only, staff anyone', () {
      expect(parent.canFileAbsenceFor('p1'), isTrue);
      expect(parent.canFileAbsenceFor('p2'), isFalse);
      expect(player.canFileAbsenceFor('p9'), isTrue);
      expect(player.canFileAbsenceFor('p1'), isFalse);
      expect(coach.canFileAbsenceFor('x'), isTrue);
      expect(parent.canMarkCompletion('p1'), isTrue);
      expect(player.canMarkCompletion('p1'), isFalse);
    });

    test('health: parent writes for linked, player read-only; results staff only; norms admin only', () {
      expect(parent.canWriteHealth('p1'), isTrue);
      expect(parent.canWriteHealth('p2'), isFalse);
      expect(player.canWriteHealth('p9'), isFalse);
      expect(coach.canWriteHealth('p1'), isTrue);
      expect(parent.canEnterTestResults, isFalse);
      expect(assistant.canEnterTestResults, isTrue);
      expect(coach.canAdminFitness, isFalse);
      expect(admin.canAdminFitness, isTrue);
      expect(parent.canEditPlans, isFalse);
      expect(coach.canEditPlans, isTrue);
    });
  });
}
