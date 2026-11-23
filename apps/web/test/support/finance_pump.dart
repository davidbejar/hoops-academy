import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/core/time/dates.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'core_fixtures.dart';
import 'fake_finance.dart';
import 'fake_repos.dart';
import 'harness.dart';
import 'pump_helpers.dart';

/// The academy's zone in the finance tests: the demo mock reads "today" in it.
const financeTestZone = 'Europe/Madrid';

/// The core data the demo finance seed refers to (Mini A, Mini B, Infantil A).
FakeCore financeCore({Map<String, List<api.TeamStaffMember>>? staff}) =>
    FakeCore(
      // The demo mock's two seasons: last season's, ended, and this one.
      seasons: FakeSeasonsRepository([
        api.Season(
          (b) => b
            ..id = 'season-2025'
            ..name = '2025/26'
            ..startsOn = api.Date(2025, 9, 1)
            ..endsOn = api.Date(2026, 6, 30)
            ..referenceYear = 2025
            ..current = false,
        ),
        season(seasonId, '2026/27', current: true),
      ]),
      teams: FakeTeamsRepository(
        teams: [
          team('team-mini-a', 'Mini A', alias: 'Leones', players: 7),
          team('team-mini-b', 'Mini B', players: 1),
          team('team-inf-a', 'Infantil A', cat: u14),
        ],
        staff: staff,
      ),
    );

/// Today in the academy's zone as `YYYY-MM-DD`, from the same clock the app
/// uses (never a fixed day or the device's zone).
String academyToday([DateTime? now]) =>
    isoDate(TenantZone.of(financeTestZone).today(now ?? DateTime.now()));

/// Pumps the app as an ADMIN of the academy and opens [location].
Future<Harness> pumpFinance(
  WidgetTester tester, {
  required FakeFinanceRepository repo,
  String? location,
  Set<TenantRole> roles = const {TenantRole.admin},
  Size size = const Size(360, 780),
  bool settle = true,
  FakeCore? core,
  Set<String> staffTeamIds = const {},
  Set<String> linkedPlayerIds = const {},
  String? ownPlayerId,
  List<Override> extraOverrides = const [],
}) => pumpAs(
  tester,
  roles: roles,
  core: core ?? financeCore(),
  location: location,
  size: size,
  settle: settle,
  timezone: financeTestZone,
  staffTeamIds: staffTeamIds,
  linkedPlayerIds: linkedPlayerIds,
  ownPlayerId: ownPlayerId,
  overrides: [...repo.overrides, ...extraOverrides],
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

/// Lets the demo mock answer: it takes 150 ms of the test's clock, and a
/// reload that keeps the previous page on screen schedules no frame meanwhile.
Future<void> settleMock(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
