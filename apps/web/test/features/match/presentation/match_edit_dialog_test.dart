import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/fake_game.dart';
import '../../../support/pump_helpers.dart';
import 'match_screens_test.dart';

const sched = 'm-sched';

FakeGame scheduledGame({String? venue}) => FakeGame(
  matches: FakeMatchesRepository(
    matches: [
      gameMatch(
        sched,
        status: gen.MatchStatus.SCHEDULED,
        opponent: 'Águilas',
        at: DateTime.utc(2026, 11, 14, 10),
      ).rebuild((b) => b.venue = venue),
      gameMatch(
        'm-fin',
        status: gen.MatchStatus.FINISHED,
        opponent: 'Lobos',
        at: DateTime.utc(2026, 10, 31, 10),
      ),
    ],
    rosters: {sched: demoRoster, 'm-fin': demoRoster},
  ),
);

Future<void> openEdit(WidgetTester tester) async {
  await tapKey(tester, 'match-menu');
  await tapKey(tester, 'menu-edit');
}

void main() {
  testWidgets('opens with the current values', (tester) async {
    final game = scheduledGame(venue: 'Pabellón');
    await pumpCoach(tester, game, '/matches/$sched');
    await openEdit(tester);
    String text(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
    expect(text('match-edit-opponent'), 'Águilas');
    expect(text('match-edit-venue'), 'Pabellón');
    expect(text('match-edit-period-count'), '4');
    expect(text('match-edit-period-minutes'), '10');
  });

  testWidgets('saves changed fields', (tester) async {
    final game = scheduledGame(venue: 'Pabellón');
    await pumpCoach(tester, game, '/matches/$sched');
    await openEdit(tester);
    await tester.enterText(
      find.byKey(const Key('match-edit-opponent')),
      'Osos',
    );
    await tester.enterText(
      find.byKey(const Key('match-edit-period-minutes')),
      '8',
    );
    await tester.tap(find.text('Visitante'));
    await tester.pump();
    await tapKey(tester, 'form-submit');
    await tester.pumpAndSettle();
    final u = game.matches.updates.single;
    expect(u.opponentName, 'Osos');
    expect(u.venue, 'Pabellón');
    expect(u.homeAway, gen.HomeAway.AWAY);
    expect(u.periodMinutes, 8);
    expect(u.scheduledAt, DateTime.utc(2026, 11, 14, 10));
    expect(find.byKey(const Key('match-edit-opponent')), findsNothing);
  });

  testWidgets('an emptied venue is sent as null (the repository adds clear)', (
    tester,
  ) async {
    final game = scheduledGame(venue: 'Pabellón');
    await pumpCoach(tester, game, '/matches/$sched');
    await openEdit(tester);
    await tester.enterText(find.byKey(const Key('match-edit-venue')), '  ');
    await tapKey(tester, 'form-submit');
    await tester.pumpAndSettle();
    expect(game.matches.updates.single.venue, isNull);
  });

  testWidgets('a server error keeps the dialog open', (tester) async {
    final game = scheduledGame();
    await pumpCoach(tester, game, '/matches/$sched');
    await openEdit(tester);
    game.matches.failWith = const AppError(kind: AppErrorKind.server);
    await tapKey(tester, 'form-submit');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('match-edit-opponent')), findsOneWidget);
  });

  testWidgets('the periods are locked once the match has started', (
    tester,
  ) async {
    final game = scheduledGame();
    await pumpCoach(tester, game, '/matches/m-fin');
    await openEdit(tester);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('match-edit-period-count')),
          )
          .enabled,
      isFalse,
    );
    await tapKey(tester, 'form-submit');
    await tester.pumpAndSettle();
    final u = game.matches.updates.single;
    expect(u.periodCount, isNull);
    expect(u.periodMinutes, isNull);
  });

  testWidgets('parents and players do not get the edit action', (tester) async {
    await pumpParent(tester, scheduledGame(), '/matches/$sched');
    expect(find.byKey(const Key('match-menu')), findsNothing);
  });

  testWidgets('a coach of another team cannot edit', (tester) async {
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {'other-team'},
      core: coreWithTeam(),
      game: scheduledGame(),
      location: '/matches/$sched',
    );
    expect(find.byKey(const Key('match-menu')), findsNothing);
  });

  group('from the list tile', () {
    testWidgets('staff edit a match without opening it; the list refreshes', (
      tester,
    ) async {
      final game = scheduledGame();
      final h = await pumpCoach(tester, game, '/matches');
      await tapKey(tester, 'match-edit-$sched');
      expect(find.byKey(const Key('match-edit-opponent')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('match-edit-opponent')),
        'Osos',
      );
      await tapKey(tester, 'form-submit');
      await tester.pumpAndSettle();
      expect(game.matches.updates.single.matchId, sched);
      expect(find.byKey(const Key('match-edit-opponent')), findsNothing);
      expect(find.textContaining('Osos'), findsOneWidget);
      expect(h.container.read(routerProvider).state.uri.path, '/matches');
    });

    testWidgets('a cancelled match offers no edit', (tester) async {
      final game = FakeGame(
        matches: FakeMatchesRepository(
          matches: [
            gameMatch('m-x', status: gen.MatchStatus.CANCELLED, opponent: 'X'),
          ],
        ),
      );
      await pumpCoach(tester, game, '/matches');
      expect(find.byKey(const Key('match-edit-m-x')), findsNothing);
    });

    testWidgets('a parent sees no edit', (tester) async {
      await pumpParent(tester, scheduledGame(), '/matches');
      expect(find.byKey(const Key('match-edit-$sched')), findsNothing);
    });
  });
}
