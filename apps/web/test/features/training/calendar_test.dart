import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/training/domain/week.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

void main() {
  group('week helpers', () {
    test('startOfWeek is the Monday of the week, also for a Sunday', () {
      expect(startOfWeek(DateTime(2026, 11, 4)), DateTime(2026, 11, 2)); // Wednesday
      expect(startOfWeek(DateTime(2026, 11, 8, 23, 59)), DateTime(2026, 11, 2)); // Sunday
      expect(startOfWeek(DateTime(2026, 11, 2)), DateTime(2026, 11, 2));
    });

    test('weekDays gives seven consecutive days and addWeeks crosses month ends', () {
      final days = weekDays(DateTime(2026, 11, 30));
      expect(days.length, 7);
      expect(days.first, DateTime(2026, 11, 30));
      expect(days.last, DateTime(2026, 12, 6));
      expect(addWeeks(DateTime(2026, 11, 30), -1), DateTime(2026, 11, 23));
    });

    test('groupByDay groups by local day and sorts by time', () {
      final a = DateTime(2026, 11, 3, 19);
      final b = DateTime(2026, 11, 3, 9);
      final c = DateTime(2026, 11, 4, 9);
      final g = groupByDay([a, b, c], (d) => d);
      expect(g[DateTime(2026, 11, 3)], [b, a]);
      expect(g[DateTime(2026, 11, 4)], [c]);
    });
  });

  group('week calendar', () {
    testWidgets('loading', (tester) async {
      final athlete = weekAthlete()..training.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete, location: '/training', settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final athlete = weekAthlete()..training.failWith = StateError('boom');
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete, location: '/training');
      expect(find.text('Reintentar'), findsOneWidget);
      athlete.training.failWith = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('session-s1')), findsOneWidget);
    });

    testWidgets('empty week', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(), location: '/training');
      expect(find.text('No hay entrenamientos esta semana'), findsOneWidget);
    });

    testWidgets('ADMIN sees every team, team names, status chip and the create button', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: weekAthlete(), location: '/training', size: const Size(360, 2000));
      for (final id in ['s1', 's2', 's3', 's4']) {
        expect(find.byKey(Key('session-$id')), findsOneWidget, reason: id);
      }
      expect(find.text('Mini A'), findsWidgets);
      expect(find.text('Infantil B'), findsWidgets);
      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.byKey(const Key('session-new')), findsOneWidget);
      expect(find.byKey(const Key('menu-schedules')), findsOneWidget);
      expect(find.byKey(const Key('team-filter')), findsOneWidget);
    });

    testWidgets('COACH of t1 only queries the own team and keeps the create button', (tester) async {
      final athlete = weekAthlete();
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: athlete, location: '/training');
      expect(athlete.training.sessionQueries.every((q) => q.startsWith('t1:')), isTrue, reason: athlete.training.sessionQueries.join(','));
      expect(find.byKey(const Key('session-s1')), findsOneWidget);
      expect(find.byKey(const Key('session-s3')), findsNothing);
      expect(find.byKey(const Key('session-new')), findsOneWidget);
    });

    testWidgets('PARENT sees the calendar read-only (no create, no schedules, absences allowed)', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: athleteCore(),
        athlete: weekAthlete(),
        location: '/training',
      );
      expect(find.byKey(const Key('session-s1')), findsOneWidget);
      expect(find.byKey(const Key('session-new')), findsNothing);
      expect(find.byKey(const Key('menu-schedules')), findsNothing);
      expect(find.byKey(const Key('menu-plans')), findsNothing);
      expect(find.byKey(const Key('menu-absences')), findsOneWidget);
    });

    testWidgets('PLAYER sees the calendar and can file own absences', (tester) async {
      await pumpAs(tester, roles: {TenantRole.player}, ownPlayerId: 'p1', core: athleteCore(), athlete: weekAthlete(), location: '/training');
      expect(find.byKey(const Key('session-s2')), findsOneWidget);
      expect(find.byKey(const Key('session-new')), findsNothing);
      expect(find.byKey(const Key('menu-absences')), findsOneWidget);
    });

    testWidgets('week navigation queries the next week and Today comes back', (tester) async {
      final athlete = weekAthlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete, location: '/training');
      await tester.tap(find.byKey(const Key('week-next')));
      await tester.pumpAndSettle();
      final next = addWeeks(monday, 1);
      expect(athlete.training.sessionQueries.last, contains('${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}'));
      expect(find.text('No hay entrenamientos esta semana'), findsOneWidget);
      await tester.tap(find.byKey(const Key('week-today')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('session-s1')), findsOneWidget);
    });

    testWidgets('ad-hoc session: validation then creation', (tester) async {
      final athlete = weekAthlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete, location: '/training');
      await tapKey(tester, 'session-new');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget); // no team chosen
      await tapKey(tester, 'session-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await enter(tester, 'session-location', 'Pista 2');
      await tapKey(tester, 'form-submit');
      expect(athlete.training.createdSession, isNotNull);
      expect(athlete.training.createdSession!.teamId, 't1');
      expect(athlete.training.createdSession!.location, 'Pista 2');
      expect(athlete.training.createdSession!.durationMinutes, 90);
      expect(find.text('Sesión creada'), findsOneWidget);
    });
  });
}
