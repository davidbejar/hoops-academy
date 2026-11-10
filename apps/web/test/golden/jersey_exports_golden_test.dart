import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/core_fixtures.dart';
import '../support/fake_repos.dart';
import '../support/harness.dart';
import '../support/pump_helpers.dart';

/// The jersey dialogs and the wish of the family (WP101). Regenerate with
/// `flutter test --update-goldens test/golden/jersey_exports_golden_test.dart`.
FakeCore _core() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [team('t1', 'Mini A', alias: 'Leones', players: 4)],
    rosters: {
      't1': [
        teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'),
        teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10'),
        teamPlayer('t1', 'p5', 'Noa Pardo', jersey: '4'),
        teamPlayer('t1', 'p6', 'Hugo Rey', jersey: '11'),
      ],
    },
  ),
  players: FakePlayersRepository([
    player(
      'p1',
      'Ana Ruiz',
      cat: u12,
      teams: [assignment('t1', 'Mini A', jersey: '7')],
    ).rebuild((b) => b.preferredJerseyNumber = '7'),
    player('p3', 'Mia Soto', cat: u12),
  ]),
);

Future<Harness> _pump(
  WidgetTester tester,
  Size size, {
  Brightness brightness = Brightness.light,
  Set<TenantRole> roles = const {TenantRole.admin},
  required String location,
  Set<String> linkedPlayerIds = const {},
  FakeCore? core,
}) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  return pumpAs(
    tester,
    roles: roles,
    core: core ?? _core(),
    location: location,
    linkedPlayerIds: linkedPlayerIds,
    size: size,
  );
}

Future<void> _openJerseyDialog(WidgetTester tester) async {
  await tapKey(tester, 'roster-menu-p1');
  await tester.tap(find.text('Cambiar dorsal'));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size, brightness) in [
    ('jersey_dialog_360x780', const Size(360, 780), Brightness.light),
    ('jersey_dialog_360x780_dark', const Size(360, 780), Brightness.dark),
    ('jersey_dialog_1024x768', const Size(1024, 768), Brightness.light),
  ]) {
    testWidgets('jersey dialog with taken and free numbers, $name', (
      tester,
    ) async {
      await _pump(tester, size, brightness: brightness, location: '/teams/t1');
      await _openJerseyDialog(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }

  testWidgets('assignment outcome, the number of the previous team', (
    tester,
  ) async {
    final core = _core()
      ..teams.assignSource = api.JerseySource.PREVIOUS
      ..teams.carriedNumber = '12';
    await _pump(
      tester,
      const Size(360, 780),
      location: '/teams/t1',
      core: core,
    );
    await tapKey(tester, 'roster-assign');
    await tapKey(tester, 'assign-candidate-p3');
    await tapKey(tester, 'assign-confirm');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/assignment_outcome_360x780.png'),
    );
  });

  testWidgets('assignment outcome, nothing free: the jersey dialog opens', (
    tester,
  ) async {
    final core = _core()..teams.assignSource = api.JerseySource.NONE;
    await _pump(
      tester,
      const Size(360, 780),
      location: '/teams/t1',
      core: core,
    );
    await tapKey(tester, 'roster-assign');
    await tapKey(tester, 'assign-candidate-p3');
    await tapKey(tester, 'assign-confirm');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/assignment_none_360x780.png'),
    );
  });

  testWidgets('wish dialog of a parent, 360x780', (tester) async {
    await _pump(
      tester,
      const Size(360, 780),
      roles: {TenantRole.parent},
      location: '/my-players',
      linkedPlayerIds: {'p1'},
    );
    await tapKey(tester, 'preferred-jersey-edit');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/preferred_jersey_wish_360x780.png'),
    );
  });
}
