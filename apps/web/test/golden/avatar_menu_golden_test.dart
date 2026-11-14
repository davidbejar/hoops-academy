import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/avatar_menu.dart';
import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// The menu behind the avatar (WP105). Regenerate with
/// `flutter test --update-goldens test/golden/avatar_menu_golden_test.dart`.
void main() {
  const sizes = {'360x780': Size(360, 780), '1024x768': Size(1024, 768)};

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('avatar menu, $name, ${brightness.name}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final h = Harness(
          me: FakeMeRepository(
            userWith([
              membershipWithRoles({TenantRole.admin}),
            ]),
          ),
          core: FakeCore(),
        );
        await h.pump(tester, size: size);
        await openAvatarMenu(tester);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/avatar_menu_${name}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}
