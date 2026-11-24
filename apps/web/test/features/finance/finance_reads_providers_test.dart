import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/l10n/locale_controller.dart';
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/finance/domain/expense_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../support/finance_pump.dart';
import '../../support/finance_seed.dart';

/// The state of expenses, the balance and the coach's and the family's reads,
/// over the finance seed.
void main() {
  /// A 501 as the screens read it (`AppError.of`, like the app's error
  /// mapping).
  final notYetServed = predicate<Object>(
    (e) => AppError.of(e).status == 501,
    'a 501 AppError',
  );

  late FinanceData finance;
  late ProviderContainer container;

  setUp(() {
    finance = FinanceData();
    financeBackend(finance);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...finance.overrides,
        effectiveLocaleProvider.overrideWithValue(const Locale('es')),
      ],
    );
    addTearDown(container.dispose);
  });

  fin.CreateExpenseRequest request({int amount = 2500}) =>
      fin.CreateExpenseRequest(
        (b) => b
          ..spentOn = fin.Date(2026, 12, 1)
          ..category = fin.ExpenseCategory.TRAVEL
          ..amountMinor = amount
          ..description = 'Autobús',
      );

  group('expenses', () {
    test('the list follows the query, newest first', () async {
      final page = await container.read(expensesProvider.future);
      expect(page.items.length, greaterThanOrEqualTo(6));
      expect(finance.expenseQuery, const ExpenseQuery());
      container
          .read(expenseQueryProvider.notifier)
          .filter(category: fin.ExpenseCategory.KIT);
      final kit = await container.read(expensesProvider.future);
      expect(kit.items, isNotEmpty);
      expect(
        kit.items.every((e) => e.category == fin.ExpenseCategory.KIT),
        isTrue,
      );
      expect(
        finance.expenseQuery,
        const ExpenseQuery(category: fin.ExpenseCategory.KIT),
      );
    });

    test('a filter goes back to the first page', () async {
      final notifier = container.read(expenseQueryProvider.notifier);
      notifier.goToPage(2);
      expect(container.read(expenseQueryProvider).page, 2);
      notifier.filter(from: fin.Date(2026, 10, 1));
      expect(container.read(expenseQueryProvider).page, 0);
      expect(container.read(expenseQueryProvider).from, fin.Date(2026, 10, 1));
      notifier.filter(from: null);
      expect(container.read(expenseQueryProvider).from, isNull);
    });

    test('create, edit and delete reload the list and the balance', () async {
      final before = (await container.read(expensesProvider.future)).items;
      final notifier = container.read(expensesProvider.notifier);
      final made = await notifier.create(request());
      expect(
        container.read(expensesProvider).requireValue.items.first.id,
        made.id,
      );
      expect(
        container.read(expensesProvider).requireValue.page.totalElements,
        before.length + 1,
      );
      await notifier.edit(
        made.id,
        fin.UpdateExpenseRequest((b) => b..amountMinor = 3000),
      );
      expect(
        container
            .read(expensesProvider)
            .requireValue
            .items
            .firstWhere((e) => e.id == made.id)
            .amountMinor,
        3000,
      );
      await notifier.delete(made.id);
      expect(
        container
            .read(expensesProvider)
            .requireValue
            .items
            .any((e) => e.id == made.id),
        isFalse,
      );
    });

    test('a write refreshes the balance that was on screen', () async {
      final first = await container.read(
        seasonBalanceProvider('season-2026').future,
      );
      await container.read(expensesProvider.future);
      await container
          .read(expensesProvider.notifier)
          .create(
            fin.CreateExpenseRequest(
              (b) => b
                ..spentOn = fin.Date(2026, 12, 1)
                ..category = fin.ExpenseCategory.OTHER
                ..amountMinor = 700
                ..description = 'Otro',
            ),
          );
      final second = await container.read(
        seasonBalanceProvider('season-2026').future,
      );
      expect(second.expenses.totalMinor, first.expenses.totalMinor + 700);
    });

    test('a refused write is thrown and leaves the list as it was', () async {
      final before = await container.read(expensesProvider.future);
      finance.fail(
        path: FinanceData.expensesPath,
        method: 'POST',
        status: 501,
        code: 'NOT_IMPLEMENTED',
      );
      await expectLater(
        container.read(expensesProvider.notifier).create(request()),
        throwsA(notYetServed),
      );
      expect(container.read(expensesProvider).requireValue, before);
    });

    test('a service that does not serve them yet is a 501', () async {
      finance.notYetServed();
      await expectLater(
        container.read(expensesProvider.future),
        throwsA(notYetServed),
      );
      expect(isNotYetServed(container.read(expensesProvider).error!), isTrue);
    });
  });

  group('the balance', () {
    test('reads the season asked for', () async {
      final b = await container.read(
        seasonBalanceProvider('season-2026').future,
      );
      expect(b.seasonId, 'season-2026');
      expect(
        finance.backend.lastQuery(FinanceData.balancePath).text('seasonId'),
        'season-2026',
      );
      expect(b.income.paidMinor, greaterThan(0));
    });
  });

  group("the coach's and the family's reads", () {
    test('who is up to date, per team', () async {
      final status = await container.read(
        teamDueStatusProvider('team-mini-a').future,
      );
      expect(status.players, hasLength(7));
      expect(finance.lastId(FinanceData.teamStatusPath), 'team-mini-a');
    });

    test("a player's dues", () async {
      final dues = await container.read(playerDuesProvider('p-ana').future);
      expect(dues, hasLength(3));
      expect(finance.lastId(FinanceData.playerDuesPath), 'p-ana');
    });
  });
}
