import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;

import '../support/fake_platform.dart';
import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// The platform console: the academy list and one academy's usage (counters per
/// service with bars, trend chart). The usage screen is one of the four screens
/// showcased on the landing page (`assets/landing/platform_usage.png`).
/// Regenerate with `flutter test --update-goldens test/golden/platform_usage_golden_test.dart`.
void main() {
  api.TenantUsageSnapshot snap(int day, int players) => api.TenantUsageSnapshot(
    (b) => b
      ..date = api.Date(2026, 11, day)
      ..collectedAt = DateTime.utc(2026, 11, day, 3)
      ..services.replace([
        usageReport('core', {'players': players, 'members': 10}),
      ]),
  );

  final usage = api.TenantUsage(
    (b) => b
      ..tenantId = 't-a'
      ..collectedAt = DateTime.utc(2026, 11, 3)
      ..services.replace([
        usageReport('core', {'members': 12, 'players': 42, 'teams': 5}),
        usageReport('game', {'matches': 14, 'finishedMatches': 11}),
        usageReport('athlete', {
          'trainingPlans': 9,
          'physicalTestResults': 60,
          'injuries': 7,
        }),
      ]),
  );

  Future<void> pump(
    WidgetTester tester,
    Size size,
    String location, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repo =
        FakePlatformRepository(
            tenants: [
              tenantOf('t-a', 'Academia Demo'),
              tenantOf('t-b', 'Club Norte', status: api.TenantStatus.SUSPENDED),
              tenantOf(
                't-c',
                'Escuela Sur',
                status: api.TenantStatus.WITHDRAWN,
              ),
            ],
            admins: {'t-a': <api.TenantAdmin>[]},
          )
          ..usageResult = usage
          ..history = [for (var i = 0; i < 6; i++) snap(i + 1, 13 + i * 6)];
    final h = Harness(
      me: FakeMeRepository(userWith(const [], superAdmin: true)),
      core: FakeCore(),
      platform: FakePlatform(repo: repo),
    );
    await h.pump(tester, size: size);
    await h.go(tester, location);
  }

  Future<void> expectGolden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  testWidgets('platform usage, 360x1900', (tester) async {
    await pump(tester, const Size(360, 1900), '/platform/t-a');
    await expectGolden('platform_usage_360x1900');
  });

  testWidgets('platform usage, 360x1900, dark', (tester) async {
    await pump(
      tester,
      const Size(360, 1900),
      '/platform/t-a',
      brightness: Brightness.dark,
    );
    await expectGolden('platform_usage_360x1900_dark');
  });

  testWidgets('platform usage, 1024x1400', (tester) async {
    await pump(tester, const Size(1024, 1400), '/platform/t-a');
    await expectGolden('platform_usage_1024x1400');
  });

  testWidgets('academies list, 360x780', (tester) async {
    await pump(tester, const Size(360, 780), '/platform');
    await expectGolden('platform_list_360x780');
  });

  testWidgets('academies list, 360x780, dark', (tester) async {
    await pump(
      tester,
      const Size(360, 780),
      '/platform',
      brightness: Brightness.dark,
    );
    await expectGolden('platform_list_360x780_dark');
  });
}
