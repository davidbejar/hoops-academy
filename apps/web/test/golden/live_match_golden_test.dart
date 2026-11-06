import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fake_game.dart';
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';

/// Regenerate with `flutter test --update-goldens test/golden`.
EventMeta _meta(int n, int clock) => EventMeta(
  id: '0190b6a0-0000-7000-8000-${n.toString().padLeft(12, '0')}',
  deviceId: 'assistant-phone',
  clientSeq: n,
  period: 1,
  clockSecondsRemaining: clock,
  recordedAtClient: DateTime.utc(2026, 11, 7, 10, 0, n),
);

void main() {
  testWidgets('live match, COACH, 360x780', (tester) async {
    final game = FakeGame(
      matches: FakeMatchesRepository(
        matches: [gameMatch('m1', opponent: 'Tigres')],
        rosters: {'m1': demoRoster},
      ),
    );
    game.server.preload('m1', [
      RecordedEvent(PeriodStart(_meta(1, 600))),
      RecordedEvent(Shot(_meta(2, 540), playerId: 'p1', points: 3, made: true)),
      RecordedEvent(Assist(_meta(3, 540), playerId: 'p2')),
      RecordedEvent(OpponentScore(_meta(4, 500), points: 2)),
      RecordedEvent(Shot(_meta(5, 450), playerId: 'p3', points: 2, made: true)),
      RecordedEvent(
        Foul(_meta(6, 420), playerId: 'p4', kind: FoulKind.personal),
      ),
    ], personId: 'assistant');
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {teamA},
      core: FakeCore(),
      game: game,
      location: '/matches/m1',
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/live_match_360x780.png'),
    );
  });
}
