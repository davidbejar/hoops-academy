import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/pump_helpers.dart';

void main() {
  group('plan picker on ad-hoc sessions', () {
    testWidgets('the chosen plan is sent with the new session', (tester) async {
      final athlete = weekAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training',
      );
      await tapKey(tester, 'session-new');
      await tapKey(tester, 'session-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'session-plan');
      await tester.tap(find.text('Tiro básico').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(athlete.training.createdSession!.planId, 'plan-1');
    });

    testWidgets('no plan is the default', (tester) async {
      final athlete = weekAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training',
      );
      await tapKey(tester, 'session-new');
      await tapKey(tester, 'session-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(athlete.training.createdSession!.planId, isNull);
    });
  });

  group('session edit', () {
    testWidgets(
      'staff edit location, duration and plan; the detail refreshes',
      (tester) async {
        final athlete = weekAthlete();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: athlete,
          location: '/training/session/s2',
        );
        await tapKey(tester, 'session-edit');
        expect(find.text('Pabellón Norte'), findsWidgets); // prefilled
        await tester.enterText(
          find.byKey(const Key('session-location')),
          'Pista 3',
        );
        await tester.enterText(find.byKey(const Key('session-duration')), '75');
        await tapKey(tester, 'session-plan');
        await tester.tap(find.text('Tiro básico').last);
        await tester.pumpAndSettle();
        await tapKey(tester, 'form-submit');
        final sent = athlete.training.updatedSession!;
        expect(sent.location, 'Pista 3');
        expect(sent.durationMinutes, 75);
        expect(sent.planId, 'plan-1');
        expect(
          find.byKey(const Key('form-submit')),
          findsNothing,
        ); // dialog closed
        expect(find.text('Sesión actualizada'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Pista 3', skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'emptying the location and choosing no plan clears both; untouched notes stay',
      (tester) async {
        final athlete = weekAthlete();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: athlete,
          location: '/training/session/s1',
        );
        await tapKey(tester, 'session-edit');
        await tester.enterText(find.byKey(const Key('session-location')), '  ');
        await tapKey(tester, 'session-plan');
        await tester.tap(find.text('Sin plan asignado').last);
        await tester.pumpAndSettle();
        await tapKey(tester, 'form-submit');
        final sent = athlete.training.updatedSession!;
        expect(sent.clear, {
          ath.UpdateTrainingSessionRequestClearEnum.location,
          ath.UpdateTrainingSessionRequestClearEnum.planId,
        });
        expect(sent.notes, 'Traer botella');
        final stored = athlete.training.sessionList.firstWhere(
          (s) => s.id == 's1',
        );
        expect(
          (stored.location, stored.planId, stored.notes),
          (null, null, 'Traer botella'),
        );
      },
    );

    testWidgets(
      'a session without a plan sends no clear when the fields keep their values',
      (tester) async {
        final athlete = weekAthlete();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: athlete,
          location: '/training/session/s2',
        );
        await tapKey(tester, 'session-edit');
        await tester.enterText(find.byKey(const Key('session-notes')), 'Petos');
        await tapKey(tester, 'session-plan');
        await tester.tap(find.text('Tiro básico').last);
        await tester.pumpAndSettle();
        await tapKey(tester, 'form-submit');
        expect(athlete.training.updatedSession!.clear, isNull);
      },
    );

    testWidgets('invalid duration is rejected before sending', (tester) async {
      final athlete = weekAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/session/s2',
      );
      await tapKey(tester, 'session-edit');
      await tester.enterText(find.byKey(const Key('session-duration')), '5');
      await tapKey(tester, 'form-submit');
      expect(athlete.training.updatedSession, isNull);
    });

    testWidgets('parents and cancelled sessions have no edit button', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: athleteCore(),
        athlete: weekAthlete(),
        location: '/training/session/s2',
      );
      expect(find.byKey(const Key('session-edit')), findsNothing);
    });

    testWidgets('a cancelled session cannot be edited', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: weekAthlete(),
        location: '/training/session/s4',
      );
      expect(find.byKey(const Key('session-edit')), findsNothing);
    });

    testWidgets('coach of another team cannot edit', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {'t2'},
        core: athleteCore(),
        athlete: weekAthlete(),
        location: '/training/session/s2',
      );
      expect(find.byKey(const Key('session-edit')), findsNothing);
    });
  });
}
