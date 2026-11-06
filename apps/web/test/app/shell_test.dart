import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/list_row.dart';
import 'package:hoops_app/core/ui/notice_banner.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

/// The restyled shell (WP72): look-related structure; the behaviour is
/// covered by navigation_roles, tenant_switcher, offline_banner and
/// update_prompt tests.
void main() {
  Future<Harness> pumpShell(
    WidgetTester tester, {
    Size size = const Size(360, 780),
    Set<TenantRole> roles = const {TenantRole.admin},
  }) async {
    final h = Harness(
      me: FakeMeRepository(userWith([membershipWithRoles(roles)])),
    );
    await h.pump(tester, size: size);
    return h;
  }

  testWidgets('app bar: academy name in the brand style, profile initials', (
    tester,
  ) async {
    await pumpShell(tester);
    final chip = find.byKey(const Key('tenant-chip'));
    final name = find.descendant(of: chip, matching: find.text('Role Test'));
    expect(name, findsOneWidget);
    expect(tester.widget<Text>(name).style!.fontWeight, FontWeight.w800);
    final profile = find.byKey(const Key('profile-button'));
    expect(
      find.descendant(of: profile, matching: find.byType(InitialsAvatar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profile, matching: find.text('CC')),
      findsOneWidget,
    );
  });

  testWidgets('phones: bottom bar on a surface with a top hairline', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('nav-bar-frame')), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablets: compact rail with labels under the icons', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(800, 900));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(find.byKey(const Key('rail-brand')), findsOneWidget);
  });

  testWidgets('desktops: extended rail with the brand mark', (tester) async {
    await pumpShell(tester, size: const Size(1280, 800));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.byKey(const Key('rail-brand')), findsOneWidget);
    expect(navLabel('Equipos'), findsOneWidget);
  });

  testWidgets('offline banner is a warning notice', (tester) async {
    final h = await pumpShell(tester);
    h.online.add(false);
    await tester.pumpAndSettle();
    final banner = tester.widget<NoticeBanner>(
      find.byKey(const Key('offline-banner')),
    );
    expect(banner.tone, HoopsTone.warning);
    expect(banner.icon, Icons.cloud_off);
  });
}
