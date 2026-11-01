import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'fake_athlete.dart';
import 'fake_game.dart';
import 'fake_platform.dart';
import 'fake_repos.dart';
import 'fixtures.dart';
import 'harness.dart';

/// Pumps the whole app as a user with [roles] and navigates to [location].
Future<Harness> pumpAs(
  WidgetTester tester, {
  required Set<TenantRole> roles,
  required FakeCore core,
  String? location,
  Set<String> staffTeamIds = const {},
  Set<String> linkedPlayerIds = const {},
  Size size = const Size(360, 780),
  bool settle = true,
  FakeTenantRepository? tenant,
  FakeGame? game,
  FakeAthlete? athlete,
  FakePlatform? platform,
  bool superAdmin = false,
  String? ownPlayerId,
  List<Override> overrides = const [],
}) async {
  final h = Harness(
    me: FakeMeRepository(
      userWith([membershipWithRoles(roles, staffTeamIds: staffTeamIds, linkedPlayerIds: linkedPlayerIds, ownPlayerId: ownPlayerId)], superAdmin: superAdmin),
    ),
    core: core,
    game: game,
    athlete: athlete,
    platform: platform,
    tenant: tenant,
    extraOverrides: overrides,
  );
  await h.pump(tester, size: size);
  if (location != null) {
    settle ? await h.go(tester, location) : await h.goAndPump(tester, location);
  }
  return h;
}

/// Scrolls [finder] into view inside the first Scrollable and taps it.
Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}
