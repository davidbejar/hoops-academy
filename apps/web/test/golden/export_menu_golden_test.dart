import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../support/core_fixtures.dart';
import '../support/fake_export.dart';
import '../support/export_overrides.dart';
import '../support/fake_game.dart';
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';

/// The export menu (WP97) is the kit's action sheet behind the download icon
/// of the matches list; its entries are the formats of that screen.
/// Regenerate with
/// `flutter test --update-goldens test/golden/export_menu_golden_test.dart`.
void main() {
  Future<void> expectGolden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final (name, size, brightness) in [
    ('export_menu_360x780', const Size(360, 780), Brightness.light),
    ('export_menu_360x780_dark', const Size(360, 780), Brightness.dark),
    ('export_menu_1024x768', const Size(1024, 768), Brightness.light),
  ]) {
    testWidgets('matches list, calendar export menu open, $name', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {teamA},
        core: FakeCore(
          teams: FakeTeamsRepository(teams: [team(teamA, 'Mini A')]),
        ),
        game: FakeGame(
          matches: FakeMatchesRepository(
            matches: [
              gameMatch(
                'm1',
                status: gen.MatchStatus.SCHEDULED,
                opponent: 'Lobos',
                at: DateTime.utc(2026, 11, 14, 10),
                seasonId: seasonId,
              ),
            ],
          ),
        ),
        timezone: 'Europe/Madrid',
        size: size,
        overrides: exportOverrides(FakeFileDownloader()),
        location: '/matches',
      );
      await tapKey(tester, 'export-menu');
      await expectGolden(name);
    });
  }
}
