import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:material_ui/material_ui.dart';

import '../support/core_fixtures.dart';
import '../support/fake_finance.dart';
import '../support/finance_pump.dart';
import '../support/pump_helpers.dart';

/// Regenerate with `flutter test --update-goldens test/golden/finance_views_golden_test.dart`.
///
/// What the coach and the family see of the dues (WP124): the demo mock's
/// seed, whose dues are all of September to November 2026, so the picture
/// does not depend on the day the test runs (from 1 Nov 2026 on).
void main() {
  const phone = Size(360, 780);
  const tallPhone = Size(360, 1250);
  const wide = Size(1024, 768);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Size size,
    Brightness brightness,
    Future<void> Function(Size size) pump,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pump(size);
    final tag = brightness == Brightness.dark ? '_dark' : '';
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'goldens/finance_${name}_${size.width.toInt()}x${size.height.toInt()}$tag.png',
      ),
    );
  }

  for (final (size, brightness) in [
    (tallPhone, Brightness.light),
    (tallPhone, Brightness.dark),
    (wide, Brightness.light),
    (wide, Brightness.dark),
  ]) {
    testWidgets(
      "finance coach's view on the team screen, "
      '${size.width.toInt()}x${size.height.toInt()}'
      '${brightness == Brightness.dark ? ', dark' : ''}',
      (tester) => shoot(
        tester,
        'coach',
        size,
        brightness,
        (size) => pumpFinance(
          tester,
          repo: FakeFinanceRepository(roles: ['COACH']),
          roles: {TenantRole.coach},
          location: '/teams/team-mini-a',
          staffTeamIds: {'team-mini-a'},
          size: size,
          core: financeCore(
            staff: {
              'team-mini-a': [
                api.TeamStaffMember(
                  (b) => b
                    ..person.replace(personRef('person-me', 'Casey Coach'))
                    ..role = api.StaffRole.COACH
                    ..since = api.Date(2026, 9, 1),
                ),
              ],
            },
          ),
        ),
      ),
    );
  }

  for (final (size, brightness) in [
    (phone, Brightness.light),
    (phone, Brightness.dark),
    (wide, Brightness.light),
    (wide, Brightness.dark),
  ]) {
    testWidgets(
      "finance family's dues, ${size.width.toInt()}x${size.height.toInt()}"
      '${brightness == Brightness.dark ? ', dark' : ''}',
      (tester) => shoot(tester, 'family', size, brightness, (size) async {
        await pumpFinance(
          tester,
          repo: FakeFinanceRepository(roles: ['PARENT']),
          roles: {TenantRole.parent},
          location: '/my-players',
          linkedPlayerIds: {'p-ana'},
          size: size,
        );
        await tapKey(tester, 'hub-tab-dues');
      }),
    );
  }
}
