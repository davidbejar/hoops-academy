import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'athlete_seed.dart';
import 'core_seed.dart';
import 'fixtures.dart';
import 'game_seed.dart';
import 'harness.dart';
import 'mock_backend.dart';

/// Pumps the whole app as a user with [roles] and navigates to [location].
Future<Harness> pumpAs(
  WidgetTester tester, {
  required Set<TenantRole> roles,
  required FakeCore core,
  String? location,
  Set<String> staffTeamIds = const {},
  Set<String> historicStaffTeamIds = const {},
  Set<String> linkedPlayerIds = const {},
  Size size = const Size(360, 780),
  bool settle = true,
  FakeTenantRepository? tenant,
  GameData? game,
  FakeAthlete? athlete,
  bool superAdmin = false,
  String? ownPlayerId,
  String? timezone,
  MockBackend? backend,
  void Function(MockBackend backend)? prepare,
  List<Override> overrides = const [],
}) async {
  final h = Harness(
    backend: backend,
    me: FakeMeRepository(
      userWith([
        membershipWithRoles(
          roles,
          staffTeamIds: staffTeamIds,
          historicStaffTeamIds: historicStaffTeamIds,
          linkedPlayerIds: linkedPlayerIds,
          ownPlayerId: ownPlayerId,
          timezone: timezone,
        ),
      ], superAdmin: superAdmin),
    ),
    core: core,
    game: game,
    athlete: athlete,
    tenant: tenant,
    extraOverrides: overrides,
  );
  prepare?.call(h.backend);
  await h.pump(tester, size: size);
  if (location != null) {
    settle ? await h.go(tester, location) : await h.goAndPump(tester, location);
  }
  return h;
}

/// Pumps the whole app as the application admin (a super admin without any
/// academy membership) and, with a [location], navigates there.
Future<Harness> pumpAsSuperAdmin(
  WidgetTester tester, {
  String? location,
  Size size = const Size(360, 780),
  bool settle = true,
  MockBackend? backend,
  List<Override> overrides = const [],
}) async {
  final h = Harness(
    backend: backend,
    me: FakeMeRepository(userWith(const [], superAdmin: true)),
    core: FakeCore(),
    extraOverrides: overrides,
  );
  await h.pump(tester, size: size);
  if (location != null) {
    settle ? await h.go(tester, location) : await h.goAndPump(tester, location);
  }
  return h;
}

/// Scrolls the widget with [key] to the middle of its Scrollable and taps it.
Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  // Centred, so a floating action button or a snack bar never covers it.
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.pump(); // lay the scrolled page out before hitting it
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}
