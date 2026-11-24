import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/core/time/dates.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'core_fixtures.dart';
import 'core_seed.dart';
import 'finance_seed.dart';
import 'harness.dart';
import 'mock_backend.dart';
import 'pump_helpers.dart';

/// The academy's zone in the finance tests: the demo mock reads "today" in it.
const financeTestZone = 'Europe/Madrid';

/// The players of Mini A the finance seed charges (`standardFinance`), and
/// Mini B's one player, by id.
const miniAPlayers = {
  'p-ana': 'Ana Ruiz',
  'p-leo': 'Leo Gil',
  'p-sara': 'Sara Vidal',
  'p-iker': 'Iker Sanz',
  'p-noa': 'Noa Pardo',
  'p-hugo': 'Hugo Rey',
  'p-lia': 'Lía Marín',
};
const miniBPlayer = ('p-mia', 'Mía Soto');

/// The core data the finance seed refers to (Mini A with its seven players,
/// Mini B with one, Infantil A without); [roster] false leaves the teams
/// without players.
FakeCore financeCore({
  Map<String, List<api.TeamStaffMember>>? staff,
  bool roster = true,
}) => FakeCore(
  // The demo mock's two seasons: last season's, ended, and this one.
  seasons: [
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
  ],
  teams: TeamsData(
    teams: [
      team('team-mini-a', 'Mini A', alias: 'Leones', players: 7),
      team('team-mini-b', 'Mini B', players: 1),
      team('team-inf-a', 'Infantil A', cat: u14),
    ],
    staff: staff,
  ),
  players: PlayersData([
    if (roster) ...[
      for (final MapEntry(key: id, value: name) in miniAPlayers.entries)
        player(
          id,
          name,
          cat: u12,
          teams: [assignment('team-mini-a', 'Mini A')],
        ),
      player(
        miniBPlayer.$1,
        miniBPlayer.$2,
        cat: u12,
        teams: [assignment('team-mini-b', 'Mini B')],
      ),
    ],
  ]),
);

/// Today in the academy's zone as `YYYY-MM-DD`, from the same clock the app
/// uses (never a fixed day or the device's zone).
String academyToday([DateTime? now]) =>
    isoDate(TenantZone.of(financeTestZone).today(now ?? DateTime.now()));

/// Pumps the app as an ADMIN of the academy, with [finance] seeded into its
/// backend, and opens [location].
Future<Harness> pumpFinance(
  WidgetTester tester, {
  required FinanceData finance,
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
  prepare: finance.seedInto,
  overrides: extraOverrides,
);

/// A backend with [core] (`financeCore` by default) and [finance] seeded,
/// for tests of the finance providers without the app.
MockBackend financeBackend(
  FinanceData finance, {
  Set<TenantRole> roles = const {TenantRole.admin},
  FakeCore? core,
}) {
  final backend = MockBackend(roles: roles);
  (core ?? financeCore()).seed(backend);
  finance.seedInto(backend);
  return backend;
}

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

/// Lets the mock answer a reload that keeps the previous page on screen (it
/// schedules no frame meanwhile).
Future<void> settleMock(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
