import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/core_seed.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// The academy chooser with its language and theme pickers (WP115). Regenerate with
/// `flutter test --update-goldens test/golden/chooser_golden_test.dart`.
void main() {
  const sizes = {'360x780': Size(360, 780), '1024x768': Size(1024, 768)};

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('academy chooser, $name, ${brightness.name}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final h = Harness(
          me: FakeMeRepository(userWith([tenantNorth, tenantSouth])),
          core: FakeCore(),
        );
        await h.pump(tester, size: size);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/chooser_${name}_${brightness.name}.png'),
        );
      });
    }
  }
}
