import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/kit.dart';
import 'package:hoops_app/features/finance/domain/expense_query.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../support/finance_seed.dart';
import '../../support/finance_pump.dart';
import '../../support/pump_helpers.dart';

/// The finance area for ADMIN, third part: the expenses (list, filters,
/// create, correct, delete) and how the hub leads to them and to the balance.
/// Data comes from the finance seed (EUR, eight expenses from September to
/// November 2026).
void main() {
  const path = '/admin/finance/expenses';
  const notYet =
      'Esta parte de las finanzas todavía no está disponible en el '
      'servidor. Inténtalo más tarde.';

  late FinanceData finance;
  setUp(() => finance = FinanceData());

  /// The expenses the mock answered the screen with, newest first (all of
  /// the seed: fewer than a page).
  List<fin.Expense> listed() => finance
      .answered<fin.ExpensePage>(FinanceData.expensesPath)
      .items
      .toList();

  final oneExpense = RegExp(r'^/api/finance/expenses/[^/:]+$');

  group('reaching it', () {
    testWidgets('the hub has Expenses and Balance rows', (tester) async {
      await pumpFinance(tester, finance: finance, location: '/admin/finance');
      expect(find.byKey(const Key('finance-expenses')), findsOneWidget);
      expect(find.byKey(const Key('finance-balance')), findsOneWidget);
      await tapKey(tester, 'finance-expenses');
      expect(find.byKey(const Key('expense-new')), findsOneWidget);
    });

    testWidgets('a coach does not get there', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        roles: {TenantRole.coach},
        location: path,
      );
      expect(find.byKey(const Key('expense-new')), findsNothing);
      expect(finance.askedAnything, isFalse);
    });
  });

  group('the list', () {
    testWidgets('newest first, with category, amount and count', (
      tester,
    ) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1800),
      );
      final expenses = listed();
      expect(find.text('${expenses.length} gastos'), findsOneWidget);
      final first = expenses.first;
      expect(find.byKey(Key('expense-${first.id}')), findsOneWidget);
      expect(find.text(first.description), findsOneWidget);
      expect(find.textContaining('Alquiler de pista · '), findsWidgets);
      expect(find.text('90,00 €'), findsWidgets);
      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      expect(rows.first.title, first.description);
    });

    testWidgets('loading, then an error with a retry', (tester) async {
      finance.hang();
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a failure shows the generic error and retries', (
      tester,
    ) async {
      finance.fail(path: FinanceData.expensesPath, method: 'GET');
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
      finance.heal();
      await tapKey(tester, 'retry-button');
      expect(find.byKey(const Key('retry-button')), findsNothing);
      expect(find.byKey(const Key('expenses-count')), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      finance.notYetServed();
      await pumpFinance(tester, finance: finance, location: path);
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('an academy without expenses says so', (tester) async {
      final other = FinanceData.empty(currency: 'EUR');
      await pumpFinance(tester, finance: other, location: path);
      expect(find.text('Aún no hay gastos'), findsOneWidget);
    });

    testWidgets('without a currency it asks to choose one first', (
      tester,
    ) async {
      final other = FinanceData.empty();
      await pumpFinance(tester, finance: other, location: path);
      expect(find.byKey(const Key('finance-no-currency')), findsOneWidget);
      expect(find.byKey(const Key('expense-new')), findsNothing);
    });

    testWidgets('offline it can be read but not changed', (tester) async {
      final h = await pumpFinance(tester, finance: finance, location: path);
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finance-offline')), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byKey(const Key('expense-new')))
            .onPressed,
        isNull,
      );
      final first = listed().first;
      expect(find.byKey(Key('expense-${first.id}')), findsOneWidget);
      await tester.tap(find.byKey(Key('expense-${first.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet-action-edit')), findsNothing);
    });
  });

  group('the filters', () {
    testWidgets('by category', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      await pickDropdown(tester, 'expenses-filter-category', 'Equipación');
      expect(
        finance.expenseQuery,
        const ExpenseQuery(category: fin.ExpenseCategory.KIT),
      );
      expect(find.text('1 gasto'), findsOneWidget);
    });

    testWidgets('a filter without matches says so', (tester) async {
      final other = FinanceData.empty(currency: 'EUR');
      await pumpFinance(tester, finance: other, location: path);
      await pickDropdown(tester, 'expenses-filter-category', 'Viajes');
      expect(find.text('No hay gastos con estos filtros'), findsOneWidget);
    });

    testWidgets('from a day on', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      await tapKey(tester, 'expenses-filter-from');
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(finance.expenseQuery.from, isNotNull);
    });

    testWidgets('the days can be cleared again', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      await tapKey(tester, 'expenses-filter-to');
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(finance.expenseQuery.to, isNotNull);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('expenses-filter-to')),
          matching: find.byIcon(Icons.clear),
        ),
      );
      await tester.pumpAndSettle();
      expect(finance.expenseQuery.to, isNull);
    });

    testWidgets('pages of 25 with previous and next', (tester) async {
      finance = FinanceData(
        data: (f) {
          standardFinance(f);
          for (var i = 0; i < 20; i++) {
            f.seedExpense(
              '2026-08-${'${1 + i}'.padLeft(2, '0')}',
              'OTHER',
              100 + i,
              'Gasto $i',
            );
          }
        },
      );
      await pumpFinance(tester, finance: finance, location: path);
      expect(find.text('28 gastos'), findsOneWidget);
      expect(find.text('Página 1 de 2'), findsOneWidget);
      await tapKey(tester, 'expenses-next');
      expect(finance.expenseQuery, const ExpenseQuery(page: 1));
      expect(find.text('Página 2 de 2'), findsOneWidget);
      await tapKey(tester, 'expenses-previous');
      expect(find.text('Página 1 de 2'), findsOneWidget);
    });
  });

  group('recording an expense', () {
    testWidgets('create one', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await pickDropdown(tester, 'expense-category', 'Viajes');
      await enter(tester, 'expense-amount', '25,50');
      await enter(tester, 'expense-description', 'Autobús a Zaragoza');
      await enter(tester, 'expense-note', 'Factura 77');
      await tapKey(tester, 'form-submit');

      final request = finance.sent<fin.CreateExpenseRequest>(
        FinanceData.expensesPath,
      );
      expect(request.category, fin.ExpenseCategory.TRAVEL);
      expect(request.amountMinor, 2550);
      expect(request.description, 'Autobús a Zaragoza');
      expect(request.note, 'Factura 77');
      expect(request.spentOn.toString(), academyToday());
      expect(find.text('Gasto guardado'), findsOneWidget);
      expect(find.text('Autobús a Zaragoza'), findsOneWidget);
    });

    testWidgets('the note is optional and goes as absent', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await pickDropdown(tester, 'expense-category', 'Otros');
      await enter(tester, 'expense-amount', '10');
      await enter(tester, 'expense-description', 'Llaves');
      await tapKey(tester, 'form-submit');
      final request = finance.sent<fin.CreateExpenseRequest>(
        FinanceData.expensesPath,
      );
      expect(request.note, isNull);
    });

    testWidgets('the form says what is missing or wrong', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await enter(tester, 'expense-amount', '0');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsWidgets);
      expect(
        find.text('Introduce un importe mayor que cero, por ejemplo 45,00'),
        findsOneWidget,
      );
      expect(
        finance.requests(FinanceData.expensesPath, method: 'POST'),
        isEmpty,
      );
    });

    testWidgets('a refusal of the server is worded, not shown raw', (
      tester,
    ) async {
      finance.fail(
        path: FinanceData.expensesPath,
        method: 'POST',
        status: 409,
        code: 'CURRENCY_NOT_SET',
      );
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await pickDropdown(tester, 'expense-category', 'Otros');
      await enter(tester, 'expense-amount', '10');
      await enter(tester, 'expense-description', 'Llaves');
      await tapKey(tester, 'form-submit');
      expect(
        find.text('Elige primero la moneda de la academia'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('form-submit')), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      finance.fail(
        path: FinanceData.expensesPath,
        method: 'POST',
        status: 501,
        code: 'NOT_IMPLEMENTED',
      );
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await pickDropdown(tester, 'expense-category', 'Otros');
      await enter(tester, 'expense-amount', '10');
      await enter(tester, 'expense-description', 'Llaves');
      await tapKey(tester, 'form-submit');
      expect(find.text(notYet), findsOneWidget);
    });
  });

  group('correcting and deleting', () {
    testWidgets('only what changed is sent', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1800),
      );
      final target = listed().firstWhere((e) => e.note != null);
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-edit')));
      await tester.pumpAndSettle();
      expect(find.text(target.description), findsWidgets);
      await enter(tester, 'expense-amount', '70');
      await tapKey(tester, 'form-submit');
      final request = finance.sent<fin.UpdateExpenseRequest>(
        oneExpense,
        method: 'PATCH',
      );
      expect(finance.lastId(oneExpense, method: 'PATCH'), target.id);
      expect(request.amountMinor, 7000);
      expect(request.description, isNull);
      expect(request.category, isNull);
      expect(request.spentOn, isNull);
      expect(request.clear, isNull);
      expect(find.text('Gasto guardado'), findsOneWidget);
      expect(find.text('70,00 €'), findsWidgets);
    });

    testWidgets('emptying the note clears it', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      final target = listed().firstWhere((e) => e.note != null);
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-edit')));
      await tester.pumpAndSettle();
      await enter(tester, 'expense-note', '');
      await tapKey(tester, 'form-submit');
      final request = finance.sent<fin.UpdateExpenseRequest>(
        oneExpense,
        method: 'PATCH',
      );
      expect(request.note, isNull);
      expect(request.clear, {fin.UpdateExpenseRequestClearEnum.note});
    });

    testWidgets('saving without changes sends nothing', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1100),
      );
      final target = listed().first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-edit')));
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(finance.requests(oneExpense, method: 'PATCH'), isEmpty);
      expect(find.byKey(const Key('form-submit')), findsNothing);
    });

    testWidgets('delete one after confirming', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      final target = listed().first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-delete')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '¿Eliminar este gasto? Hazlo solo con uno registrado por error.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(finance.lastId(oneExpense, method: 'DELETE'), target.id);
      expect(find.text('Gasto eliminado'), findsOneWidget);
      expect(find.byKey(Key('expense-${target.id}')), findsNothing);
    });

    testWidgets('cancelling the confirmation keeps it', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      final target = listed().first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-cancel')));
      await tester.pumpAndSettle();
      expect(finance.requests(oneExpense, method: 'DELETE'), isEmpty);
      expect(find.byKey(Key('expense-${target.id}')), findsOneWidget);
    });

    testWidgets('a sheet closed with escape does nothing', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      final target = listed().first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(finance.requests(oneExpense, method: 'DELETE'), isEmpty);
    });
  });
}
