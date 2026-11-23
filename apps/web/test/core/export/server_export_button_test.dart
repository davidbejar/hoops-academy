import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/connectivity/connectivity_providers.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/export/export_context.dart';
import 'package:hoops_app/core/export/server_export_button.dart';
import 'package:hoops_app/core/export/server_file.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/export_overrides.dart';
import '../../support/fake_export.dart';
import '../../support/kit_harness.dart';

const _button = Key('export');
final _bytes = Uint8List.fromList([1, 2, 3]);

AppError _problem(int status, String code) => AppError(
  kind: status >= 500 ? AppErrorKind.server : AppErrorKind.validation,
  status: status,
  code: code,
);

Future<FakeFileDownloader> _pump(
  WidgetTester tester,
  ServerExportButton button, {
  bool online = true,
}) async {
  final downloader = FakeFileDownloader();
  await pumpKit(
    tester,
    ProviderScope(
      overrides: [
        ...exportOverrides(downloader),
        academySlugProvider.overrideWithValue('club'),
        onlineProvider.overrideWith((ref) => Stream.value(online)),
      ],
      child: button,
    ),
  );
  return downloader;
}

Future<void> _tap(WidgetTester tester) async {
  await tester.tap(find.byKey(_button));
  await tester.pumpAndSettle();
}

void main() {
  const tooLarge =
      'Hay más de 10.000 filas: acota el rango de fechas o las acciones e '
      'inténtalo de nuevo.';

  group('CSV', () {
    testWidgets('saves the bytes under the shared file name', (tester) async {
      final downloader = await _pump(
        tester,
        ServerExportButton.csv(
          key: _button,
          what: 'dues',
          tooltip: 'Exportar',
          fetch: (language) async => _bytes,
        ),
      );
      await _tap(tester);
      expect(downloader.saved.single.fileName, 'hoops-club-dues-20261110.csv');
      expect(downloader.saved.single.mediaType, 'text/csv; charset=utf-8');
      expect(
        find.text('Descargado hoops-club-dues-20261110.csv'),
        findsOneWidget,
      );
    });

    testWidgets('EXPORT_TOO_LARGE asks to narrow the filters', (tester) async {
      final downloader = await _pump(
        tester,
        ServerExportButton.csv(
          key: _button,
          what: 'audit',
          tooltip: 'Exportar',
          fetch: (language) async => throw _problem(422, 'EXPORT_TOO_LARGE'),
        ),
      );
      await _tap(tester);
      expect(downloader.saved, isEmpty);
      expect(find.text(tooLarge), findsOneWidget);
    });

    testWidgets('offline: disabled, and the tooltip says why', (tester) async {
      await _pump(
        tester,
        ServerExportButton.csv(
          key: _button,
          what: 'audit',
          tooltip: 'Exportar',
          fetch: (language) async => _bytes,
        ),
        online: false,
      );
      final icon = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(_button),
          matching: find.byType(IconButton),
        ),
      );
      expect(icon.onPressed, isNull);
      expect(
        icon.tooltip,
        'Exportar necesita conexión: el archivo lo genera el servidor.',
      );
    });
  });

  group('PDF', () {
    ServerExportButton pdf({
      required Future<ServerFile> Function(String) fetch,
      String? tooLargeMessage,
    }) => ServerExportButton.pdf(
      key: _button,
      what: 'sheet',
      tooltip: 'PDF',
      unavailableMessage: 'Vuelve más tarde',
      tooLargeMessage: tooLargeMessage,
      fetch: fetch,
    );

    testWidgets('keeps the name the server gave', (tester) async {
      final downloader = await _pump(
        tester,
        pdf(fetch: (l) async => ServerFile(_bytes, fileName: 'acta.pdf')),
      );
      await _tap(tester);
      expect(downloader.saved.single.fileName, 'acta.pdf');
      expect(downloader.saved.single.mediaType, 'application/pdf');
    });

    testWidgets('503 shows the try-later message', (tester) async {
      await _pump(
        tester,
        pdf(fetch: (l) async => throw _problem(503, 'UPSTREAM_UNAVAILABLE')),
      );
      await _tap(tester);
      expect(find.text('Vuelve más tarde'), findsOneWidget);
    });

    testWidgets('EXPORT_TOO_LARGE shows the message of the screen', (
      tester,
    ) async {
      await _pump(
        tester,
        pdf(
          tooLargeMessage: 'Demasiado grande: usa el CSV',
          fetch: (l) async => throw _problem(422, 'EXPORT_TOO_LARGE'),
        ),
      );
      await _tap(tester);
      expect(find.text('Demasiado grande: usa el CSV'), findsOneWidget);
    });

    testWidgets('EXPORT_TOO_LARGE without its own message says the same as '
        'the CSV button', (tester) async {
      await _pump(
        tester,
        pdf(fetch: (l) async => throw _problem(422, 'EXPORT_TOO_LARGE')),
      );
      await _tap(tester);
      expect(find.text(tooLarge), findsOneWidget);
    });
  });
}
