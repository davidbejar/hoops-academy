import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/locale_controller.dart';
import '../data/finance_api.dart';
import '../data/finance_repository.dart';
import '../domain/due_query.dart';
import '../domain/expense_query.dart';
import '../domain/money.dart';

// ---------------------------------------------------------------- repository

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => ApiFinanceRepository(
    ref.watch(financeApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);

/// True for the answer of a service that does not serve an operation yet
/// (501 `NOT_IMPLEMENTED`): the screens say so instead of a generic failure.
bool isNotYetServed(Object error) => AppError.of(error).status == 501;

// ------------------------------------------------------------------ settings

class FinanceSettingsNotifier extends AsyncNotifier<fin.FinanceSettings> {
  @override
  Future<fin.FinanceSettings> build() =>
      ref.watch(financeRepositoryProvider).settings();

  /// Chooses the academy's currency. A refusal (unknown code, locked by the
  /// first due) is thrown and leaves the state as it was.
  Future<void> chooseCurrency(String currency) async {
    final settings = await ref
        .read(financeRepositoryProvider)
        .chooseCurrency(currency);
    state = AsyncData(settings);
    ref.invalidate(feePlansProvider);
  }
}

final financeSettingsProvider =
    AsyncNotifierProvider<FinanceSettingsNotifier, fin.FinanceSettings>(
      FinanceSettingsNotifier.new,
    );

/// How to show and read amounts: the academy's currency in the user's
/// language. Null while the settings load or no currency is chosen yet.
final moneyFormatProvider = Provider<MoneyFormat?>((ref) {
  final settings = ref.watch(financeSettingsProvider).value;
  final currency = settings?.currency;
  final digits = settings?.minorDigits;
  if (currency == null || digits == null) return null;
  return MoneyFormat(
    currency: currency,
    minorDigits: digits,
    locale: ref.watch(effectiveLocaleProvider).languageCode,
  );
});

// ---------------------------------------------------------------- fee plans

class ShowArchivedPlans extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final showArchivedPlansProvider = NotifierProvider<ShowArchivedPlans, bool>(
  ShowArchivedPlans.new,
);

class FeePlansNotifier extends AsyncNotifier<List<fin.FeePlan>> {
  @override
  Future<List<fin.FeePlan>> build() async {
    final archived = ref.watch(showArchivedPlansProvider);
    final page = await ref
        .watch(financeRepositoryProvider)
        .feePlans(includeArchived: archived);
    return page.items.toList();
  }

  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<fin.FeePlan> create(fin.CreateFeePlanRequest request) async {
    final plan = await _repo.createFeePlan(request);
    await _reload();
    return plan;
  }

  Future<fin.FeePlan> edit(
    String feePlanId,
    fin.UpdateFeePlanRequest request,
  ) async {
    final plan = await _repo.updateFeePlan(feePlanId, request);
    await _reload();
    return plan;
  }

  Future<void> setArchived(String feePlanId, bool archived) async {
    await _repo.setFeePlanArchived(feePlanId, archived: archived);
    await _reload();
  }

  Future<void> delete(String feePlanId) async {
    await _repo.deleteFeePlan(feePlanId);
    await _reload();
  }
}

final feePlansProvider =
    AsyncNotifierProvider<FeePlansNotifier, List<fin.FeePlan>>(
      FeePlansNotifier.new,
    );

// --------------------------------------------------------------------- dues

class DueQueryNotifier extends Notifier<DueQuery> {
  @override
  DueQuery build() => const DueQuery();

  void set(DueQuery query) => state = query;

  /// Changes the filters given (pass `null` to clear one) and goes back to the
  /// first page.
  void filter({
    Object? planId = _keep,
    Object? teamId = _keep,
    Object? period = _keep,
    Object? status = _keep,
  }) => state = state.copyWith(
    planId: identical(planId, _keep) ? state.planId : planId,
    teamId: identical(teamId, _keep) ? state.teamId : teamId,
    period: identical(period, _keep) ? state.period : period,
    status: identical(status, _keep) ? state.status : status,
    page: 0,
  );

  void goToPage(int page) => state = state.copyWith(page: page);
}

const _keep = Object();

final dueQueryProvider = NotifierProvider<DueQueryNotifier, DueQuery>(
  DueQueryNotifier.new,
);

class DuesNotifier extends AsyncNotifier<fin.DuePage> {
  @override
  Future<fin.DuePage> build() =>
      ref.watch(financeRepositoryProvider).dues(ref.watch(dueQueryProvider));

  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  Future<void> _reload() async {
    ref.invalidate(dueDetailProvider);
    ref.invalidateSelf();
    await future;
  }

  /// What generating [period] of a plan would create; writes nothing.
  Future<fin.DueGeneration> previewGeneration(
    String feePlanId,
    String period,
  ) => _repo.generateDues(feePlanId, period: period, preview: true);

  /// Creates the missing dues of [period]. The plan now has dues and the
  /// currency is locked, so both are read again.
  Future<fin.DueGeneration> generate(String feePlanId, String period) async {
    final result = await _repo.generateDues(feePlanId, period: period);
    ref.invalidate(feePlansProvider);
    ref.invalidate(financeSettingsProvider);
    await _reload();
    return result;
  }

  Future<void> changeAmount(
    String dueId, {
    required int amountMinor,
    required String reason,
  }) async {
    await _repo.changeDueAmount(
      dueId,
      amountMinor: amountMinor,
      reason: reason,
    );
    await _reload();
  }

  Future<void> waive(String dueId, String reason) async {
    await _repo.waiveDue(dueId, reason);
    await _reload();
  }

  Future<fin.Due> pay(
    String dueId, {
    required fin.Date paidOn,
    required fin.PaymentMethod method,
    String? note,
  }) async {
    final due = await _repo.payDue(
      dueId,
      paidOn: paidOn,
      method: method,
      note: note,
    );
    await _reload();
    return due;
  }

  Future<void> voidPayment(String paymentId, String reason) async {
    await _repo.voidPayment(paymentId, reason);
    await _reload();
  }
}

final duesProvider = AsyncNotifierProvider<DuesNotifier, fin.DuePage>(
  DuesNotifier.new,
);

/// One due with every payment it has had (voided ones included).
final dueDetailProvider = FutureProvider.family<fin.DueDetail, String>(
  (ref, dueId) => ref.watch(financeRepositoryProvider).due(dueId),
);

// ----------------------------------------------------------------- expenses

class ExpenseQueryNotifier extends Notifier<ExpenseQuery> {
  @override
  ExpenseQuery build() => const ExpenseQuery();

  /// Changes the filters given (pass `null` to clear one) and goes back to the
  /// first page.
  void filter({
    Object? from = _keep,
    Object? to = _keep,
    Object? category = _keep,
  }) => state = state.copyWith(from: from, to: to, category: category);

  void goToPage(int page) => state = state.copyWith(page: page);
}

final expenseQueryProvider =
    NotifierProvider<ExpenseQueryNotifier, ExpenseQuery>(
      ExpenseQueryNotifier.new,
    );

class ExpensesNotifier extends AsyncNotifier<fin.ExpensePage> {
  @override
  Future<fin.ExpensePage> build() => ref
      .watch(financeRepositoryProvider)
      .expenses(ref.watch(expenseQueryProvider));

  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  /// An expense changes the balance of its season.
  Future<void> _reload() async {
    ref.invalidate(seasonBalanceProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<fin.Expense> create(fin.CreateExpenseRequest request) async {
    final expense = await _repo.createExpense(request);
    await _reload();
    return expense;
  }

  Future<fin.Expense> edit(
    String expenseId,
    fin.UpdateExpenseRequest request,
  ) async {
    final expense = await _repo.updateExpense(expenseId, request);
    await _reload();
    return expense;
  }

  Future<void> delete(String expenseId) async {
    await _repo.deleteExpense(expenseId);
    await _reload();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, fin.ExpensePage>(
      ExpensesNotifier.new,
    );

// ------------------------------------------------------------------ balance

/// The balance of one season: dues by state, expenses by category.
final seasonBalanceProvider = FutureProvider.family<fin.SeasonBalance, String>(
  (ref, seasonId) => ref.watch(financeRepositoryProvider).balance(seasonId),
);

// ------------------------------------------- the coach's and the family's reads

/// Who of a team is up to date (a flag per player, no amounts).
final teamDueStatusProvider = FutureProvider.family<fin.TeamDueStatus, String>(
  (ref, teamId) => ref.watch(financeRepositoryProvider).teamDueStatus(teamId),
);

/// A player's dues as the family sees them.
final playerDuesProvider = FutureProvider.family<fin.PlayerDuePage, String>(
  (ref, playerId) => ref.watch(financeRepositoryProvider).playerDues(playerId),
);
