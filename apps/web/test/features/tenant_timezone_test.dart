import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_athlete_api/hoops_athlete_api.dart' as ath;

import '../support/athlete_scenarios.dart';
import '../support/fake_athlete.dart';
import '../support/pump_helpers.dart';
import 'match/presentation/match_screens_test.dart' show coreWithTeam, gameWith;
import '../support/fake_game.dart';

/// Academy zone Asia/Jakarta (UTC+7, no DST) differs from any test device zone
/// that is not UTC+7: times must follow the academy, not the device.
void main() {
  testWidgets(
    'training calendar shows session times in the academy zone, zone named once',
    (tester) async {
      final day = weekday(1);
      final noonUtc = DateTime.utc(day.year, day.month, day.day, 12);
      final athlete = FakeAthlete(
        training: FakeTrainingRepository(
          sessions: [
            ath.TrainingSession(
              (b) => b
                ..id = 'z1'
                ..teamId = 't1'
                ..startsAt = noonUtc
                ..durationMinutes = 90
                ..status = ath.TrainingSessionStatus.PLANNED,
            ),
          ],
        ),
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        timezone: 'Asia/Jakarta',
        location: '/training',
      );
      expect(find.text('19:00 – 20:30'), findsOneWidget);
      expect(find.textContaining('Asia/Jakarta'), findsOneWidget);
    },
  );

  testWidgets('without an academy zone the zone note is not shown', (
    tester,
  ) async {
    await pumpAs(
      tester,
      roles: {TenantRole.admin},
      core: athleteCore(),
      athlete: weekAthlete(),
      location: '/training',
    );
    expect(find.byKey(const Key('timezone-note')), findsNothing);
  });

  testWidgets('match list shows the kick-off in the academy zone', (
    tester,
  ) async {
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {teamA},
      core: coreWithTeam(),
      game: gameWith(),
      timezone: 'Asia/Jakarta',
      location: '/matches',
    );
    // 2026-11-14 10:00Z is 17:00 in Jakarta
    expect(find.textContaining('17:00'), findsWidgets);
    expect(find.textContaining('Asia/Jakarta'), findsOneWidget);
  });
}
