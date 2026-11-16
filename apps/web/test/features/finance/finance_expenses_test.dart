import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/ui/kit.dart';
import 'package:hoops_app/features/finance/domain/expense_query.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../support/fake_finance.dart';
import '../../support/finance_pump.dart';
import '../../support/pump_helpers.dart';

/// The finance area for ADMIN, third part: the expenses (list, filters,
/// create, correct, delete) and how the hub leads to them and to the balance.
/// Data comes from the demo mock's seed (EUR, eight expenses from September to
/// November 2026).
void main() {
  const path = '/admin/finance/expenses';
  const notYet =
      'Esta parte de las finanzas todavía no está disponible en el '
      'servidor. Inténtalo más tarde.';

  late FakeFinanceRepository repo;
  setUp(() => repo = FakeFinanceRepository());

  /// The expenses the seed has, newest first, read through a repository of
  /// their own (the demo mock answers in real time, hence `runAsync`).
  Future<List<fin.Expense>> seed(
    WidgetTester tester, [
    ExpenseQuery query = const ExpenseQuery(size: 50),
  ]) async =>
      (await tester.runAsync(() => FakeFinanceRepository().expenses(query)))!
          .items
          .toList();

  group('reaching it', () {
    testWidgets('the hub has Expenses and Balance rows', (tester) async {
      await pumpFinance(tester, repo: repo, location: '/admin/finance');
      expect(find.byKey(const Key('finance-expenses')), findsOneWidget);
      expect(find.byKey(const Key('finance-balance')), findsOneWidget);
      await tapKey(tester, 'finance-expenses');
      expect(find.byKey(const Key('expense-new')), findsOneWidget);
    });

    testWidgets('a coach does not get there', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        roles: {TenantRole.coach},
        location: path,
      );
      expect(find.byKey(const Key('expense-new')), findsNothing);
      expect(repo.calls, isEmpty);
    });
  });

  group('the list', () {
    testWidgets('newest first, with category, amount and count', (
      tester,
    ) async {
      await pumpFinance(tester, repo: repo, location: path);
      final expenses = await seed(tester);
      expect(find.text('${expenses.length} gastos'), findsOneWidget);
      final first = expenses.first;
      expect(find.byKey(Key('expense-${first.id}')), findsOneWidget);
      expect(find.text(first.description), findsOneWidget);
      expect(find.textContaining('Alquiler de pista · '), findsWidgets);
      expect(find.text('90,00 €'), findsWidgets);
      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      expect(rows.first.title, first.description);
    });

    testWidgets('loading, then an error with a retry', (tester) async {
      repo.hang = true;
      await pumpFinance(tester, repo: repo, location: path, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a failure shows the generic error and retries', (
      tester,
    ) async {
      repo.failOn['expenses'] = const AppError(
        kind: AppErrorKind.server,
        status: 500,
      );
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
      repo.failOn.clear();
      await tapKey(tester, 'retry-button');
      expect(find.byKey(const Key('retry-button')), findsNothing);
      expect(find.byKey(const Key('expenses-count')), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      repo.notYetServed();
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('an academy without expenses says so', (tester) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await tester.runAsync(() => other.chooseCurrency('EUR'));
      await pumpFinance(tester, repo: other, location: path);
      expect(find.text('Aún no hay gastos'), findsOneWidget);
    });

    testWidgets('without a currency it asks to choose one first', (
      tester,
    ) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await pumpFinance(tester, repo: other, location: path);
      expect(find.byKey(const Key('finance-no-currency')), findsOneWidget);
      expect(find.byKey(const Key('expense-new')), findsNothing);
    });

    testWidgets('offline it can be read but not changed', (tester) async {
      final h = await pumpFinance(tester, repo: repo, location: path);
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finance-offline')), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byKey(const Key('expense-new')))
            .onPressed,
        isNull,
      );
      final first = (await seed(tester)).first;
      expect(find.byKey(Key('expense-${first.id}')), findsOneWidget);
      await tester.tap(find.byKey(Key('expense-${first.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet-action-edit')), findsNothing);
    });
  });

  group('the filters', () {
    testWidgets('by category', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await pickDropdown(tester, 'expenses-filter-category', 'Equipación');
      expect(
        repo.last['expenses'],
        const ExpenseQuery(category: fin.ExpenseCategory.KIT),
      );
      expect(find.text('1 gasto'), findsOneWidget);
    });

    testWidgets('a filter without matches says so', (tester) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await tester.runAsync(() => other.chooseCurrency('EUR'));
      await pumpFinance(tester, repo: other, location: path);
      await pickDropdown(tester, 'expenses-filter-category', 'Viajes');
      expect(find.text('No hay gastos con estos filtros'), findsOneWidget);
    });

    testWidgets('from a day on', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await tapKey(tester, 'expenses-filter-from');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect((repo.last['expenses']! as ExpenseQuery).from, isNotNull);
    });

    testWidgets('the days can be cleared again', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await tapKey(tester, 'expenses-filter-to');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect((repo.last['expenses']! as ExpenseQuery).to, isNotNull);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('expenses-filter-to')),
          matching: find.byIcon(Icons.clear),
        ),
      );
      await tester.pumpAndSettle();
      expect((repo.last['expenses']! as ExpenseQuery).to, isNull);
    });

    testWidgets('pages of 25 with previous and next', (tester) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 20; i++) {
          await repo.createExpense(
            fin.CreateExpenseRequest(
              (b) => b
                ..spentOn = fin.Date(2026, 8, 1 + i)
                ..category = fin.ExpenseCategory.OTHER
                ..amountMinor = 100 + i
                ..description = 'Gasto $i',
            ),
          );
        }
      });
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.text('28 gastos'), findsOneWidget);
      expect(find.text('Página 1 de 2'), findsOneWidget);
      await tapKey(tester, 'expenses-next');
      expect(repo.last['expenses'], const ExpenseQuery(page: 1));
      expect(find.text('Página 2 de 2'), findsOneWidget);
      await tapKey(tester, 'expenses-previous');
      expect(find.text('Página 1 de 2'), findsOneWidget);
    });
  });

  group('recording an expense', () {
    testWidgets('create one', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await pickDropdown(tester, 'expense-category', 'Viajes');
      await enter(tester, 'expense-amount', '25,50');
      await enter(tester, 'expense-description', 'Autobús a Zaragoza');
      await enter(tester, 'expense-note', 'Factura 77');
      await tapKey(tester, 'form-submit');

      final request = repo.last['createExpense']! as fin.CreateExpenseRequest;
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
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'expense-new');
      await pickDropdown(tester, 'expense-category', 'Otros');
      await enter(tester, 'expense-amount', '10');
      await enter(tester, 'expense-description', 'Llaves');
      await tapKey(tester, 'form-submit');
      final request = repo.last['createExpense']! as fin.CreateExpenseRequest;
      expect(request.note, isNull);
    });

    testWidgets('the form says what is missing or wrong', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
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
      expect(repo.calls, isNot(contains('createExpense')));
    });

    testWidgets('a refusal of the server is worded, not shown raw', (
      tester,
    ) async {
      repo.failOn['createExpense'] = const AppError(
        kind: AppErrorKind.conflict,
        code: 'CURRENCY_NOT_SET',
        status: 409,
      );
      await pumpFinance(
        tester,
        repo: repo,
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
      repo.failOn['createExpense'] = notImplemented;
      await pumpFinance(
        tester,
        repo: repo,
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
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      final target = (await seed(tester)).firstWhere((e) => e.note != null);
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-edit')));
      await tester.pumpAndSettle();
      expect(find.text(target.description), findsWidgets);
      await enter(tester, 'expense-amount', '70');
      await tapKey(tester, 'form-submit');
      final (id, request) =
          repo.last['updateExpense']! as (String, fin.UpdateExpenseRequest);
      expect(id, target.id);
      expect(request.amountMinor, 7000);
      expect(request.description, isNull);
      expect(request.category, isNull);
      expect(request.spentOn, isNull);
      expect(request.clear, isNull);
      expect(find.text('Gasto guardado'), findsOneWidget);
      expect(find.text('70,00 €'), findsWidgets);
    });

    testWidgets('emptying the note clears it', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      final target = (await seed(tester)).firstWhere((e) => e.note != null);
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-edit')));
      await tester.pumpAndSettle();
      await enter(tester, 'expense-note', '');
      await tapKey(tester, 'form-submit');
      final (_, request) =
          repo.last['updateExpense']! as (String, fin.UpdateExpenseRequest);
      expect(request.note, isNull);
      expect(request.clear, {fin.UpdateExpenseRequestClearEnum.note});
    });

    testWidgets('saving without changes sends nothing', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      final target = (await seed(tester)).first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-edit')));
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(repo.calls, isNot(contains('updateExpense')));
      expect(find.byKey(const Key('form-submit')), findsNothing);
    });

    testWidgets('delete one after confirming', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      final target = (await seed(tester)).first;
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
      expect(repo.last['deleteExpense'], target.id);
      expect(find.text('Gasto eliminado'), findsOneWidget);
      expect(find.byKey(Key('expense-${target.id}')), findsNothing);
    });

    testWidgets('cancelling the confirmation keeps it', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      final target = (await seed(tester)).first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.tap(find.byKey(const Key('sheet-action-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-cancel')));
      await tester.pumpAndSettle();
      expect(repo.calls, isNot(contains('deleteExpense')));
      expect(find.byKey(Key('expense-${target.id}')), findsOneWidget);
    });

    testWidgets('a sheet closed with escape does nothing', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      final target = (await seed(tester)).first;
      await tapKey(tester, 'expense-${target.id}');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(repo.calls, isNot(contains('deleteExpense')));
    });
  });
}
