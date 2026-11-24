import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_app/features/finance/domain/expense_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../support/export_overrides.dart';
import '../../support/fake_export.dart';
import '../../support/finance_seed.dart';
import '../../support/finance_pump.dart';
import '../../support/pump_helpers.dart';

/// The two CSV exports of the finance area (dues, expenses): the existing
/// server export button, with the filters on screen, online only.
void main() {
  late FinanceData finance;
  late FakeFileDownloader downloader;
  setUp(() {
    finance = FinanceData();
    downloader = FakeFileDownloader();
  });

  Future<void> pump(WidgetTester tester, String path) => pumpFinance(
    tester,
    finance: finance,
    location: path,
    extraOverrides: exportOverrides(downloader),
  );

  group('dues', () {
    const path = '/admin/finance/dues';

    testWidgets('saves the CSV of the filters on screen', (tester) async {
      await pump(tester, path);
      await tapKey(tester, 'dues-status-OPEN');
      await tester.tap(find.byKey(const Key('dues-export')));
      await tester.pumpAndSettle();
      expect(
        finance.exportedDueQuery,
        const DueQuery(status: fin.DueStatus.OPEN),
      );
      expect(finance.languageOf(FinanceData.exportDuesPath), 'es');
      final file = downloader.saved.single;
      expect(file.fileName, 'hoops-role-test-dues-20261110.csv');
      expect(file.mediaType, startsWith('text/csv'));
      expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(find.textContaining('hoops-role-test-dues'), findsOneWidget);
    });

    testWidgets('too many rows asks to narrow the filters', (tester) async {
      finance.fail(
        path: FinanceData.exportDuesPath,
        status: 422,
        code: 'EXPORT_TOO_LARGE',
      );
      await pump(tester, path);
      await tester.tap(find.byKey(const Key('dues-export')));
      await tester.pumpAndSettle();
      expect(downloader.saved, isEmpty);
      expect(find.textContaining('Hay más de 10.000 filas'), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      // The list itself is served; only the export is not.
      finance.fail(
        path: FinanceData.exportDuesPath,
        status: 501,
        code: 'NOT_IMPLEMENTED',
      );
      await pump(tester, path);
      await tester.tap(find.byKey(const Key('dues-export')));
      await tester.pumpAndSettle();
      expect(downloader.saved, isEmpty);
      expect(
        find.text(
          'Esta parte de las finanzas todavía no está disponible en el '
          'servidor. Inténtalo más tarde.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('offline the button is disabled and says why', (tester) async {
      final h = await pumpFinance(
        tester,
        finance: finance,
        location: path,
        extraOverrides: exportOverrides(downloader),
      );
      h.online.add(false);
      await tester.pumpAndSettle();
      final button = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(const Key('dues-export')),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(button.tooltip, contains('Exportar necesita conexión'));
    });
  });

  group('expenses', () {
    const path = '/admin/finance/expenses';

    testWidgets('saves the CSV of the filters on screen', (tester) async {
      await pump(tester, path);
      await pickDropdown(tester, 'expenses-filter-category', 'Equipación');
      await tester.tap(find.byKey(const Key('expenses-export')));
      await tester.pumpAndSettle();
      expect(
        finance.exportedExpenseQuery,
        const ExpenseQuery(category: fin.ExpenseCategory.KIT),
      );
      expect(finance.languageOf(FinanceData.exportExpensesPath), 'es');
      final file = downloader.saved.single;
      expect(file.fileName, 'hoops-role-test-expenses-20261110.csv');
      expect(file.mediaType, startsWith('text/csv'));
    });

    testWidgets('a failure is worded like on other screens', (tester) async {
      finance.fail(path: FinanceData.exportExpensesPath, status: 403);
      await pump(tester, path);
      await tester.tap(find.byKey(const Key('expenses-export')));
      await tester.pumpAndSettle();
      expect(find.text('No tienes permiso para hacer esto.'), findsOneWidget);
    });
  });
}
