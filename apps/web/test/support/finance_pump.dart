import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/core/ui/date_field.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'core_fixtures.dart';
import 'fake_finance.dart';
import 'fake_repos.dart';
import 'harness.dart';
import 'pump_helpers.dart';

/// The academy's zone in the finance tests: the demo mock reads "today" in it.
const financeTestZone = 'Europe/Madrid';

/// The core data the demo finance seed refers to (Mini A, Mini B, Infantil A).
FakeCore financeCore() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [
      team('team-mini-a', 'Mini A', alias: 'Leones', players: 7),
      team('team-mini-b', 'Mini B', players: 1),
      team('team-inf-a', 'Infantil A', cat: u14),
    ],
  ),
);

/// Today in the academy's zone as `YYYY-MM-DD`, from the same clock the app
/// uses (never a fixed day or the device's zone).
String academyToday([DateTime? now]) => DateField.format(
  TenantZone.of(financeTestZone).today(now ?? DateTime.now()),
);

/// Pumps the app as an ADMIN of the academy and opens [location].
Future<Harness> pumpFinance(
  WidgetTester tester, {
  required FakeFinanceRepository repo,
  String? location,
  Set<TenantRole> roles = const {TenantRole.admin},
  Size size = const Size(360, 780),
  bool settle = true,
  FakeCore? core,
}) => pumpAs(
  tester,
  roles: roles,
  core: core ?? financeCore(),
  location: location,
  size: size,
  settle: settle,
  timezone: financeTestZone,
  overrides: repo.overrides,
);

/// Opens the dropdown with [key] and picks the entry that reads [text].
Future<void> pickDropdown(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
  await tester.pump();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}
