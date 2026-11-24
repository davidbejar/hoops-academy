import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/export_overrides.dart';
import '../../support/fake_export.dart';
import '../../support/core_seed.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

FakeCore _core() => FakeCore(
  teams: TeamsData(
    teams: [team('t1', 'Mini A', players: 1)],
    rosters: {
      't1': [teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7')],
    },
  ),
);

const _button = Key('roster-export-pdf');
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
  group('who sees the roster PDF button (same rule as the CSV)', () {
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

    testWidgets('a former coach of an ended season has no PDF button', (
      tester,
    ) async {
      await _pump(
        tester,
        _core(),
        FakeFileDownloader(),
        roles: {TenantRole.coach},
        historicStaffTeamIds: const {'t1'},
      );
      expect(find.byKey(_button), findsNothing);
    });

    testWidgets('it sits next to the CSV button', (tester) async {
      await _pump(
        tester,
        _core(),
        FakeFileDownloader(),
        roles: {TenantRole.admin},
      );
      expect(find.byKey(const Key('roster-export')), findsOneWidget);
      expect(find.byKey(_button), findsOneWidget);
    });
  });

  group('the download', () {
    testWidgets('asks for the app language, saves under the server name', (
      tester,
    ) async {
      final core = _core();
      final downloader = FakeFileDownloader();
      await _pump(tester, core, downloader, roles: {TenantRole.admin});

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(core.teams.rosterPdfs, [('t1', 'es')]);
      expect(core.teams.rosterExports, isEmpty, reason: 'not the CSV');
      final file = downloader.saved.single;
      final serverName = core.teams.lastExportName!;
      expect(serverName, startsWith('hoops-demo-roster-mini-a-'));
      expect(file.fileName, serverName);
      expect(file.bytes, core.teams.lastExport.bytes);
      expect(file.mediaType, 'application/pdf');
      expect(find.textContaining('Descargado $serverName'), findsOneWidget);
    });

    testWidgets('without a name from the server the app names the file', (
      tester,
    ) async {
      final core = _core();
      core.teams.noServerFileName = true;
      final downloader = FakeFileDownloader();
      await _pump(tester, core, downloader, roles: {TenantRole.admin});

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(
        downloader.saved.single.fileName,
        'hoops-role-test-roster-mini-a-20261110.pdf',
      );
    });

    testWidgets('422 EXPORT_TOO_LARGE offers the CSV instead', (tester) async {
      final core = _core()
        ..teams.exportFailure = const AppError(
          kind: AppErrorKind.validation,
          status: 422,
          code: 'EXPORT_TOO_LARGE',
        );
      final downloader = FakeFileDownloader();
      await _pump(tester, core, downloader, roles: {TenantRole.admin});

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(downloader.saved, isEmpty);
      expect(
        find.text(
          'La plantilla es demasiado grande para una hoja: usa el archivo CSV.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('503 shows a try-later message and no crash', (tester) async {
      final core = _core()
        ..teams.exportFailure = const AppError(
          kind: AppErrorKind.server,
          status: 503,
          code: 'UPSTREAM_UNAVAILABLE',
        );
      final downloader = FakeFileDownloader();
      await _pump(tester, core, downloader, roles: {TenantRole.admin});

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(downloader.saved, isEmpty);
      expect(
        find.text(
          'El PDF no está disponible ahora. Inténtalo más tarde o usa el '
          'archivo CSV.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<IconButton>(_icon).onPressed, isNotNull);
    });

    testWidgets('offline the button is disabled and says why', (tester) async {
      final h = await _pump(
        tester,
        _core(),
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
    });
  });
}
