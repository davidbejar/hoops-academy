import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

void main() {
  group('schedule editor', () {
    FakeAthlete athlete() => FakeAthlete(training: FakeTrainingRepository(schedules: [schedule('sch1'), schedule('sch2', teamId: 't2', day: ath.DayOfWeek.FRIDAY, time: '17:30:00', minutes: 60)]));

    testWidgets('lists schedules with weekday, time and duration', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete(), location: '/training/schedules');
      expect(find.textContaining('Martes 18:00'), findsOneWidget);
      expect(find.textContaining('Viernes 17:30'), findsOneWidget);
    });

    testWidgets('empty, loading and error states', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(), location: '/training/schedules');
      expect(find.text('Aún no hay horarios'), findsOneWidget);
      final hung = FakeAthlete()..training.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: hung, location: '/training/schedules', settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      final a = athlete()..training.failWith = StateError('x');
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/schedules');
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('creating validates the time and sends weekday / time / duration / dates', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/schedules');
      await tapKey(tester, 'schedule-new');
      await tapKey(tester, 'schedule-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await enter(tester, 'schedule-time', '25:99');
      await tapKey(tester, 'form-submit');
      expect(find.text('Usa el formato HH:MM'), findsOneWidget);
      await enter(tester, 'schedule-time', '19:30');
      await tapKey(tester, 'schedule-day');
      await tester.tap(find.text('Jueves').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      final sent = a.training.createdSchedule!;
      expect(sent.teamId, 't1');
      expect(sent.dayOfWeek, ath.DayOfWeek.THURSDAY);
      expect(sent.startTime, '19:30');
      expect(sent.durationMinutes, 90);
      expect(sent.validUntil, isNull);
    });

    testWidgets('delete asks for confirmation', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/schedules');
      await tapKey(tester, 'schedule-delete-sch1');
      await tapKey(tester, 'dialog-confirm');
      expect(a.training.scheduleList.map((s) => s.id), ['sch2']);
    });

    testWidgets('a coach only edits schedules of the own team; parents are blocked by the route guard', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: athlete(), location: '/training/schedules');
      expect(find.byKey(const Key('schedule-delete-sch1')), findsOneWidget);
      expect(find.byKey(const Key('schedule-delete-sch2')), findsNothing);
      await pumpAs(tester, roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, core: athleteCore(), athlete: athlete(), location: '/training/schedules');
      expect(find.byKey(const Key('forbidden')), findsOneWidget);
      expect(find.byKey(const Key('schedule-new')), findsNothing);
    });
  });

  group('planned absences', () {
    FakeAthlete athlete() => FakeAthlete(training: FakeTrainingRepository(absences: [absence('a1', 'p1', reason: 'Viaje')]));

    testWidgets('list with reason; empty state', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete(), location: '/training/absences');
      expect(find.textContaining('Viaje'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(), location: '/training/absences');
      expect(find.text('No hay ausencias previstas'), findsOneWidget);
    });

    testWidgets('PARENT files an absence for the linked child (single child preselected)', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, core: athleteCore(), athlete: a, location: '/training/absences');
      await tapKey(tester, 'absence-new');
      await enter(tester, 'absence-reason', 'Médico');
      await tapKey(tester, 'form-submit');
      expect(a.training.createdAbsence!.playerId, 'p1');
      expect(a.training.createdAbsence!.reason, 'Médico');
      expect(find.text('Ausencia registrada'), findsOneWidget);
    });

    testWidgets('PLAYER files for self', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.player}, ownPlayerId: 'p2', core: athleteCore(), athlete: a, location: '/training/absences');
      await tapKey(tester, 'absence-new');
      await tapKey(tester, 'form-submit');
      expect(a.training.createdAbsence!.playerId, 'p2');
    });

    testWidgets('PARENT with two children must choose one', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.parent}, linkedPlayerIds: {'p1', 'p2'}, core: athleteCore(), athlete: a, location: '/training/absences');
      await tapKey(tester, 'absence-new');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      expect(a.training.createdAbsence, isNull);
      await tapKey(tester, 'player-picker');
      await tester.tap(find.text('Leo Gil').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(a.training.createdAbsence!.playerId, 'p2');
    });

    testWidgets('end date before start is rejected', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, core: athleteCore(), athlete: a, location: '/training/absences');
      await tapKey(tester, 'absence-new');
      // From = 28th, To = 1st of the visible month: To is always before From.
      await tapKey(tester, 'absence-from');
      await tester.tap(find.text('28').last);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'absence-to');
      await tester.tap(find.text('1').last);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(find.text('La fecha final no puede ser anterior a la inicial'), findsOneWidget);
      expect(a.training.createdAbsence, isNull);
    });

    testWidgets('delete', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/absences');
      await tapKey(tester, 'absence-delete-a1');
      await tapKey(tester, 'dialog-confirm');
      expect(a.training.absenceList, isEmpty);
    });
  });
}
