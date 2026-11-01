import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

FakeAthlete _athlete() => weekAthlete()
  ..training.attendanceBySession['s1'] = [
    attEntry('p1'),
    attEntry('p2', expected: true),
    attEntry('p3', injuryId: 'inj-1', status: ath.AttendanceStatus.ABSENT),
  ];

void main() {
  group('session detail', () {
    testWidgets('loading and error', (tester) async {
      final a = _athlete()..training.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/session/s1', settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error shows retry', (tester) async {
      final a = _athlete()..training.failWith = StateError('x');
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/session/s1');
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('shows location, plan name, notes and duration', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: _athlete(), location: '/training/session/s1');
      expect(find.textContaining('Pabellón Norte'), findsOneWidget);
      expect(find.textContaining('Tiro básico'), findsOneWidget);
      expect(find.textContaining('Traer botella'), findsOneWidget);
      expect(find.textContaining('90 min'), findsOneWidget);
    });

    testWidgets('PARENT sees the session but no attendance sheet nor cancel', (tester) async {
      final a = _athlete();
      await pumpAs(tester, roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, core: athleteCore(), athlete: a, location: '/training/session/s1');
      expect(find.textContaining('Pabellón Norte'), findsOneWidget);
      expect(find.byKey(const Key('attendance-save')), findsNothing);
      expect(find.byKey(const Key('session-cancel')), findsNothing);
      expect(a.training.calls, isNot(contains('attendance')));
    });

    testWidgets('coach of ANOTHER team does not get the sheet', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t2'}, core: athleteCore(), athlete: _athlete(), location: '/training/session/s1');
      expect(find.byKey(const Key('attendance-save')), findsNothing);
    });

    testWidgets('attendance sheet: overlay chips, EXCUSED prefill for planned absence, injured marker', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: _athlete(), location: '/training/session/s1', size: const Size(360, 1600));
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Ausencia prevista'), findsOneWidget);
      expect(find.text('Lesionado'), findsOneWidget);
      ChoiceChip chip(String id, ath.AttendanceStatus s) => tester.widget<ChoiceChip>(find.byKey(Key('att-$id-${s.name}')));
      expect(chip('p2', ath.AttendanceStatus.EXCUSED).selected, isTrue);
      expect(chip('p3', ath.AttendanceStatus.ABSENT).selected, isTrue);
      expect(chip('p1', ath.AttendanceStatus.PRESENT).selected, isFalse);
    });

    testWidgets('saving sends PRESENT / LATE(minutes) / ABSENT / EXCUSED and skips unmarked players', (tester) async {
      final a = _athlete();
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: a, location: '/training/session/s1', size: const Size(360, 1600));
      await tapKey(tester, 'att-p1-LATE');
      await enter(tester, 'late-minutes-p1', '12');
      await tapKey(tester, 'att-p3-PRESENT'); // overrides the pre-existing ABSENT
      await tapKey(tester, 'attendance-save');
      final sent = {for (final e in a.training.recorded!) e.playerId: e};
      expect(sent['p1']!.status, ath.AttendanceStatus.LATE);
      expect(sent['p1']!.minutesLate, 12);
      expect(sent['p2']!.status, ath.AttendanceStatus.EXCUSED);
      expect(sent['p3']!.status, ath.AttendanceStatus.PRESENT);
      expect(sent['p3']!.minutesLate, isNull);
      expect(find.text('Asistencia guardada'), findsOneWidget);
    });

    testWidgets('LATE needs valid minutes', (tester) async {
      final a = _athlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/session/s1', size: const Size(360, 1600));
      await tapKey(tester, 'att-p1-LATE');
      await enter(tester, 'late-minutes-p1', '0');
      await tapKey(tester, 'attendance-save');
      expect(find.text('Minutos entre 1 y 180'), findsOneWidget);
      expect(a.training.recorded, isNull);
    });

    testWidgets('cancel needs a reason, then marks the session cancelled', (tester) async {
      final a = _athlete();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: a, location: '/training/session/s1');
      await tapKey(tester, 'session-cancel');
      await tapKey(tester, 'dialog-confirm');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('note-field')), 'Lluvia');
      await tapKey(tester, 'dialog-confirm');
      expect(a.training.cancelledReason, 'Lluvia');
      expect(find.byKey(const Key('cancel-reason')), findsOneWidget);
      expect(find.byKey(const Key('session-cancel')), findsNothing);
      expect(find.byKey(const Key('attendance-save')), findsNothing);
    });
  });
}
