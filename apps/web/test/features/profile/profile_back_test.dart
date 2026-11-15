import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/profile/presentation/profile_screen.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/avatar_menu.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

/// The profile has no menu of its own (it lives outside the shell), so it
/// must offer its own way back.
void main() {
  String path(Harness h) => h.container.read(routerProvider).state.uri.path;

  testWidgets('back returns to the screen the profile was opened from', (
    tester,
  ) async {
    final h = await pumpAs(
      tester,
      roles: {TenantRole.coach},
      core: athleteCore(),
      location: '/training',
    );
    expect(path(h), '/training');

    await openProfile(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tapKey(tester, 'profile-back');

    expect(find.byType(ProfileScreen), findsNothing);
    expect(path(h), '/training');
  });

  testWidgets('opened by its address, back leads to the first menu entry', (
    tester,
  ) async {
    final h = await pumpAs(
      tester,
      roles: {TenantRole.coach},
      core: athleteCore(),
      location: '/profile',
    );
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tapKey(tester, 'profile-back');

    expect(find.byType(ProfileScreen), findsNothing);
    expect(path(h), '/teams');
  });

  testWidgets('the back button says what it does', (tester) async {
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      core: athleteCore(),
      location: '/profile',
    );

    final label = MaterialLocalizations.of(
      tester.element(find.byType(ProfileScreen)),
    ).backButtonTooltip;
    expect(label, isNotEmpty);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-back')),
        matching: find.byTooltip(label),
      ),
      findsOneWidget,
    );
  });
}
