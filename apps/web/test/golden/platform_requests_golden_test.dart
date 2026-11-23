import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;

import '../support/mock_backend.dart';
import '../support/platform_seed.dart';
import '../support/pump_helpers.dart';

/// The academy requests workbench (WP90). Regenerate with
/// `flutter test --update-goldens test/golden/platform_requests_golden_test.dart`.
void main() {
  Future<void> pumpWorkbench(
    WidgetTester tester,
    Size size, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final backend = MockBackend()
      ..seedAcademyRequests([
        academyRequestOf('r-1', 'Escuela de Baloncesto Valle'),
        academyRequestOf(
          'r-2',
          'Hoops Bali',
          name: null,
          email: 'admin@hoopsbali.example',
          role: api.AcademyRequestRole.ADMIN,
          locale: api.ApiLocale.id,
        ),
      ]);
    await pumpAsSuperAdmin(
      tester,
      backend: backend,
      size: size,
      location: '/platform/requests',
    );
  }

  testWidgets('academy requests, 360x780', (tester) async {
    await pumpWorkbench(tester, const Size(360, 780));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_requests_360x780.png'),
    );
  });

  testWidgets('academy requests, 360x780, dark', (tester) async {
    await pumpWorkbench(
      tester,
      const Size(360, 780),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_requests_360x780_dark.png'),
    );
  });

  testWidgets('academy requests, 1024x768', (tester) async {
    await pumpWorkbench(tester, const Size(1024, 768));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_requests_1024x768.png'),
    );
  });
}
