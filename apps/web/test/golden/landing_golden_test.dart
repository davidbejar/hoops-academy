import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/landing/presentation/landing_screen.dart';
import 'package:hoops_app/features/landing/presentation/widgets/device_frame.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

/// Regenerate with `flutter test --update-goldens test/golden`.
/// The anonymous root (WP70) at the phone and desktop breakpoints, in the
/// system's light and dark theme. The device mock-ups are decoded before the
/// frame is captured so the screenshots are part of the picture.
Future<void> _pumpLanding(
  WidgetTester tester,
  Size size,
  Brightness brightness, {
  String? language,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final h = Harness(
    me: FakeMeRepository(userWith([tenantNorth])),
    signedIn: false,
    prefs: {'hoops.locale': ?language},
  );
  await h.pump(tester, size: size);
  final context = tester.element(find.byType(LandingScreen));
  await tester.runAsync(
    () => Future.wait([
      for (final shot in LandingShot.values)
        for (final code in const ['es', 'en', 'id'])
          precacheImage(AssetImage(shot.assetFor(code)), context),
    ]),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (size, name) in const [
    (Size(360, 780), 'landing_360x780'),
    (Size(1280, 800), 'landing_1280x800'),
  ]) {
    for (final brightness in Brightness.values) {
      final suffix = brightness == Brightness.dark ? '_dark' : '';
      testWidgets('landing, ${brightness.name}, $name', (tester) async {
        await _pumpLanding(tester, size, brightness);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$name$suffix.png'),
        );
      });
    }
  }

  // The language shows in the header code, the copy and the screenshots.
  for (final language in const ['en', 'id']) {
    testWidgets('landing, light, 360x780, $language', (tester) async {
      await _pumpLanding(
        tester,
        const Size(360, 780),
        Brightness.light,
        language: language,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/landing_360x780_$language.png'),
      );
    });
  }
}
