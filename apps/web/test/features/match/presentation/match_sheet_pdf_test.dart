import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/export_overrides.dart';
import '../../../support/fake_export.dart';
import '../../../support/fake_game.dart';
import '../../../support/fake_repos.dart';
import '../../../support/pump_helpers.dart';

const _fin = 'm-fin';
const _button = Key('match-sheet-pdf');
final _icon = find.descendant(
  of: find.byKey(_button),
  matching: find.byType(IconButton),
);

FakeGame _game() => FakeGame(
  matches: FakeMatchesRepository(
    matches: [
      gameMatch(
        _fin,
        status: gen.MatchStatus.FINISHED,
        opponent: 'Lobos',
        at: DateTime.utc(2026, 10, 31, 10),
      ),
    ],
    rosters: {_fin: demoRoster},
  ),
);

Future<(FakeGame, dynamic)> _pump(
  WidgetTester tester,
  FakeFileDownloader downloader, {
  Set<TenantRole> roles = const {TenantRole.coach},
  Set<String> linked = const {},
  String? ownPlayer,
}) async {
  final game = _game();
  final h = await pumpAs(
    tester,
    roles: roles,
    staffTeamIds: roles.contains(TenantRole.coach) ? {teamA} : {},
    linkedPlayerIds: linked,
    ownPlayerId: ownPlayer,
    core: FakeCore(),
    game: game,
    location: '/matches/$_fin',
    overrides: exportOverrides(downloader),
  );
  return (game, h);
}

void main() {
  group('who sees the match sheet button (everyone with a box score)', () {
    final cases = <String, (Set<TenantRole>, Set<String>, String?)>{
      'coach': ({TenantRole.coach}, const {}, null),
      'admin': ({TenantRole.admin}, const {}, null),
      'parent': ({TenantRole.parent}, const {'p1'}, null),
      'player': ({TenantRole.player}, const {}, 'p1'),
    };
    for (final MapEntry(key: name, value: (roles, linked, own))
        in cases.entries) {
      testWidgets('$name sees it', (tester) async {
        await _pump(
          tester,
          FakeFileDownloader(),
          roles: roles,
          linked: linked,
          ownPlayer: own,
        );
        expect(find.byKey(_button), findsOneWidget);
        expect(find.byKey(const Key('export-menu')), findsOneWidget);
      });
    }
  });

  group('the download', () {
    testWidgets('asks for the app language, saves under the server name', (
      tester,
    ) async {
      final downloader = FakeFileDownloader();
      final (game, _) = await _pump(tester, downloader);

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(game.matches.sheets, [(_fin, 'es')]);
      final file = downloader.saved.single;
      expect(
        file.fileName,
        'hoops-role-test-match-sheet-mini-a-lobos-20261116.pdf',
      );
      expect(file.bytes, game.matches.sheet.bytes);
      expect(file.mediaType, 'application/pdf');
      expect(find.textContaining('Descargado hoops-role-test'), findsOneWidget);
    });

    testWidgets('503 shows a try-later message and no crash', (tester) async {
      final downloader = FakeFileDownloader();
      final (game, _) = await _pump(tester, downloader);
      game.matches.sheetFailure = const AppError(
        kind: AppErrorKind.server,
        status: 503,
        code: 'UPSTREAM_UNAVAILABLE',
      );

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(downloader.saved, isEmpty);
      expect(
        find.text(
          'La hoja del partido no está disponible ahora. Inténtalo más tarde.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a 404 is shown like on other screens', (tester) async {
      final downloader = FakeFileDownloader();
      final (game, _) = await _pump(tester, downloader);
      game.matches.sheetFailure = const AppError(
        kind: AppErrorKind.notFound,
        status: 404,
      );

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(downloader.saved, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('offline the button is disabled and says why', (tester) async {
      final (_, h) = await _pump(tester, FakeFileDownloader());
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
