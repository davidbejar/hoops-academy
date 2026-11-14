import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the menu behind the avatar in the top bar.
Future<void> openAvatarMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('profile-button')));
  await tester.pumpAndSettle();
}

/// Opens the profile screen through the avatar menu.
Future<void> openProfile(WidgetTester tester) async {
  await openAvatarMenu(tester);
  await tester.tap(find.byKey(const Key('avatar-menu-profile')));
  await tester.pumpAndSettle();
}
