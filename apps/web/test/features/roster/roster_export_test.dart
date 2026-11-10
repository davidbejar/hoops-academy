import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/export_overrides.dart';
import '../../support/fake_export.dart';
import '../../support/fake_repos.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

FakeCore _core() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [team('t1', 'Mini A', players: 1)],
    rosters: {
      't1': [teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7')],
    },
  ),
);

const _button = Key('roster-export');
final _icon = find.descendant(
  of: find.byKey(_button),
  matching: find.byType(IconButton),
);

Future<Harness> _pump(
  WidgetTester tester,
  FakeCore core,
  FakeFileDownloader downloader, {
  required Set<TenantRole> roles,
  Set<String> staffTeamIds = const {},
  Set<String> historicStaffTeamIds = const {},
}) => pumpAs(
  tester,
  roles: roles,
  core: core,
  location: '/teams/t1',
  staffTeamIds: staffTeamIds,
  historicStaffTeamIds: historicStaffTeamIds,
  overrides: exportOverrides(downloader),
);

void main() {
  group('who sees the roster export', () {
    final cases = <String, (Set<TenantRole>, Set<String>, bool)>{
      'admin': ({TenantRole.admin}, const {}, true),
      'coach of the team': ({TenantRole.coach}, const {'t1'}, true),
      'coach of another team': ({TenantRole.coach}, const {'t9'}, false),
      'assistant coach of the team': (
        {TenantRole.assistantCoach},
        const {'t1'},
        false,
      ),
      'parent': ({TenantRole.parent}, const {}, false),
      'player': ({TenantRole.player}, const {}, false),
    };
    for (final MapEntry(key: name, value: (roles, staff, visible))
        in cases.entries) {
      testWidgets('$name: ${visible ? 'visible' : 'hidden'}', (tester) async {
        await _pump(
          tester,
          _core(),
          FakeFileDownloader(),
          roles: roles,
          staffTeamIds: staff,
        );
        expect(find.byKey(_button), visible ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('the former coach of an ended season may export it', (
      tester,
    ) async {
      await _pump(
        tester,
        _core(),
        FakeFileDownloader(),
        roles: {TenantRole.coach},
        historicStaffTeamIds: const {'t1'},
      );
      expect(find.byKey(_button), findsOneWidget);
    });
  });

  group('the download', () {
    testWidgets('asks the server for the app language and saves its bytes', (
      tester,
    ) async {
      final core = _core();
      final downloader = FakeFileDownloader();
      await _pump(tester, core, downloader, roles: {TenantRole.admin});

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(core.teams.rosterExports, [('t1', 'es')]);
      final file = downloader.saved.single;
      expect(file.fileName, 'hoops-role-test-roster-mini-a-20261110.csv');
      expect(file.bytes, core.teams.rosterCsv);
      expect(file.mediaType, startsWith('text/csv'));
      expect(
        find.textContaining('hoops-role-test-roster-mini-a'),
        findsOneWidget,
      );
    });

    testWidgets('an error Problem is shown like the other screens do', (
      tester,
    ) async {
      final core = _core()
        ..teams.exportFailure = const AppError(
          kind: AppErrorKind.forbidden,
          status: 403,
        );
      final downloader = FakeFileDownloader();
      await _pump(tester, core, downloader, roles: {TenantRole.admin});

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(downloader.saved, isEmpty);
      expect(find.text('No tienes permiso para hacer esto.'), findsOneWidget);
    });

    testWidgets('offline the button is disabled and says why', (tester) async {
      final core = _core();
      final h = await _pump(
        tester,
        core,
        FakeFileDownloader(),
        roles: {TenantRole.admin},
      );
      h.online.add(false);
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(_icon).onPressed, isNull);
      expect(
        tester.widget<IconButton>(_icon).tooltip,
        'Exportar necesita conexión: el archivo lo genera el servidor.',
      );
      h.online.add(true);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(_icon).onPressed, isNotNull);
    });
  });
}
