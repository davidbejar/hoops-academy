import 'dart:typed_data';

import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../../core/api/fetch_all.dart';
import '../domain/due_query.dart';
import '../domain/expense_query.dart';

/// Settings, fee plans, dues, payments, expenses, the season balance, the
/// coach's and the family's reads and the CSV exports (`/api/finance/**`, finance.yaml
/// 1.0.0). Failures surface as the transport's exceptions; screens map them
/// with `AppError.of`.
abstract class FinanceRepository {
  Future<fin.FinanceSettings> settings();
  Future<fin.FinanceSettings> chooseCurrency(String currency);

  /// Every fee plan (all pages, ADR-0061).
  Future<List<fin.FeePlan>> feePlans({bool includeArchived = false});
  Future<fin.FeePlan> createFeePlan(fin.CreateFeePlanRequest request);
  Future<fin.FeePlan> updateFeePlan(
    String feePlanId,
    fin.UpdateFeePlanRequest request,
  );
  Future<fin.FeePlan> setFeePlanArchived(
    String feePlanId, {
    required bool archived,
  });
  Future<void> deleteFeePlan(String feePlanId);

  /// The dues of [period] a plan creates (or, with [preview], would create).
  Future<fin.DueGeneration> generateDues(
    String feePlanId, {
    required String period,
    bool preview = false,
  });

  Future<fin.DuePage> dues(DueQuery query);
  Future<fin.DueDetail> due(String dueId);
  Future<fin.Due> changeDueAmount(
    String dueId, {
    required int amountMinor,
    required String reason,
  });
  Future<fin.Due> waiveDue(String dueId, String reason);
  Future<fin.Due> payDue(
    String dueId, {
    required fin.Date paidOn,
    required fin.PaymentMethod method,
    String? note,
  });
  Future<fin.Due> voidPayment(String paymentId, String reason);

  // ---------------------------------------------------------------- expenses
  Future<fin.ExpensePage> expenses(ExpenseQuery query);
  Future<fin.Expense> createExpense(fin.CreateExpenseRequest request);
  Future<fin.Expense> updateExpense(
    String expenseId,
    fin.UpdateExpenseRequest request,
  );
  Future<void> deleteExpense(String expenseId);

  /// The balance of one season: dues by state, expenses by category.
  Future<fin.SeasonBalance> balance(String seasonId);

  // ------------------------------------------------- coach's and family's reads
  /// Who of a team is up to date: a flag per player, no amounts (ADMIN and the
  /// team's current COACH).
  Future<fin.TeamDueStatus> teamDueStatus(String teamId);

  /// A player's dues as the family sees them (ADMIN, a linked PARENT, the
  /// PLAYER themself); every page (ADR-0061).
  Future<List<fin.PlayerDue>> playerDues(String playerId);

  // ----------------------------------------------------------------- exports
  /// The CSV of the dues the filters of [query] select (no paging), in
  /// [language] (`es`, `en`, `id`).
  Future<Uint8List> exportDues(DueQuery query, {required String language});

  /// The CSV of the expenses the filters of [query] select.
  Future<Uint8List> exportExpenses(
    ExpenseQuery query, {
    required String language,
  });
}

class ApiFinanceRepository implements FinanceRepository {
  ApiFinanceRepository(fin.HoopsFinanceApi client, this._tenant)
    : _settings = client.getSettingsApi(),
      _plans = client.getFeePlansApi(),
      _dues = client.getDuesApi(),
      _payments = client.getPaymentsApi(),
      _expenses = client.getExpensesApi(),
      _balance = client.getBalanceApi();

  final fin.SettingsApi _settings;
  final fin.FeePlansApi _plans;
  final fin.DuesApi _dues;
  final fin.PaymentsApi _payments;
  final fin.ExpensesApi _expenses;
  final fin.BalanceApi _balance;
  final String _tenant;

  @override
  Future<fin.FinanceSettings> settings() async =>
      (await _settings.getFinanceSettings(xTenantId: _tenant)).data!;

  @override
  Future<fin.FinanceSettings> chooseCurrency(String currency) async =>
      (await _settings.updateFinanceSettings(
        xTenantId: _tenant,
        updateFinanceSettingsRequest: fin.UpdateFinanceSettingsRequest(
          (b) => b.currency = currency,
        ),
      )).data!;

  @override
  Future<List<fin.FeePlan>> feePlans({bool includeArchived = false}) =>
      fetchAll((page, size) async {
        final p = (await _plans.listFeePlans(
          xTenantId: _tenant,
          includeArchived: includeArchived,
          page: page,
          size: size,
        )).data!;
        return (items: p.items, totalPages: p.page.totalPages);
      });

  @override
  Future<fin.FeePlan> createFeePlan(fin.CreateFeePlanRequest request) async =>
      (await _plans.createFeePlan(
        xTenantId: _tenant,
        createFeePlanRequest: request,
      )).data!;

  @override
  Future<fin.FeePlan> updateFeePlan(
    String feePlanId,
    fin.UpdateFeePlanRequest request,
  ) async => (await _plans.updateFeePlan(
    xTenantId: _tenant,
    feePlanId: feePlanId,
    updateFeePlanRequest: request,
  )).data!;

  @override
  Future<fin.FeePlan> setFeePlanArchived(
    String feePlanId, {
    required bool archived,
  }) async =>
      (archived
              ? await _plans.archiveFeePlan(
                  xTenantId: _tenant,
                  feePlanId: feePlanId,
                )
              : await _plans.unarchiveFeePlan(
                  xTenantId: _tenant,
                  feePlanId: feePlanId,
                ))
          .data!;

  @override
  Future<void> deleteFeePlan(String feePlanId) async {
    await _plans.deleteFeePlan(xTenantId: _tenant, feePlanId: feePlanId);
  }

  @override
  Future<fin.DueGeneration> generateDues(
    String feePlanId, {
    required String period,
    bool preview = false,
  }) async => (await _dues.generateDues(
    xTenantId: _tenant,
    feePlanId: feePlanId,
    generateDuesRequest: fin.GenerateDuesRequest(
      (b) => b
        ..period = period
        ..preview = preview,
    ),
  )).data!;

  @override
  Future<fin.DuePage> dues(DueQuery query) async => (await _dues.listDues(
    xTenantId: _tenant,
    feePlanId: query.planId,
    teamId: query.teamId,
    period: query.period,
    status: query.status,
    page: query.page,
    size: query.size,
  )).data!;

  @override
  Future<fin.DueDetail> due(String dueId) async =>
      (await _dues.getDue(xTenantId: _tenant, dueId: dueId)).data!;

  @override
  Future<fin.Due> changeDueAmount(
    String dueId, {
    required int amountMinor,
    required String reason,
  }) async => (await _dues.changeDueAmount(
    xTenantId: _tenant,
    dueId: dueId,
    changeDueAmountRequest: fin.ChangeDueAmountRequest(
      (b) => b
        ..amountMinor = amountMinor
        ..reason = reason,
    ),
  )).data!;

  @override
  Future<fin.Due> waiveDue(String dueId, String reason) async =>
      (await _dues.waiveDue(
        xTenantId: _tenant,
        dueId: dueId,
        reasonRequest: fin.ReasonRequest((b) => b.reason = reason),
      )).data!;

  @override
  Future<fin.Due> payDue(
    String dueId, {
    required fin.Date paidOn,
    required fin.PaymentMethod method,
    String? note,
  }) async => (await _payments.payDue(
    xTenantId: _tenant,
    dueId: dueId,
    payDueRequest: fin.PayDueRequest(
      (b) => b
        ..paidOn = paidOn
        ..method = method
        ..note = note,
    ),
  )).data!;

  @override
  Future<fin.Due> voidPayment(String paymentId, String reason) async =>
      (await _payments.voidPayment(
        xTenantId: _tenant,
        paymentId: paymentId,
        reasonRequest: fin.ReasonRequest((b) => b.reason = reason),
      )).data!;

  @override
  Future<fin.ExpensePage> expenses(ExpenseQuery query) async =>
      (await _expenses.listExpenses(
        xTenantId: _tenant,
        from: query.from,
        to: query.to,
        category: query.category,
        page: query.page,
        size: query.size,
      )).data!;

  @override
  Future<fin.Expense> createExpense(fin.CreateExpenseRequest request) async =>
      (await _expenses.createExpense(
        xTenantId: _tenant,
        createExpenseRequest: request,
      )).data!;

  @override
  Future<fin.Expense> updateExpense(
    String expenseId,
    fin.UpdateExpenseRequest request,
  ) async => (await _expenses.updateExpense(
    xTenantId: _tenant,
    expenseId: expenseId,
    updateExpenseRequest: request,
  )).data!;

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _expenses.deleteExpense(xTenantId: _tenant, expenseId: expenseId);
  }

  @override
  Future<fin.SeasonBalance> balance(String seasonId) async =>
      (await _balance.getSeasonBalance(
        xTenantId: _tenant,
        seasonId: seasonId,
      )).data!;

  @override
  Future<fin.TeamDueStatus> teamDueStatus(String teamId) async =>
      (await _dues.getTeamDueStatus(xTenantId: _tenant, teamId: teamId)).data!;

  @override
  Future<List<fin.PlayerDue>> playerDues(String playerId) =>
      fetchAll((page, size) async {
        final p = (await _dues.listPlayerDues(
          xTenantId: _tenant,
          playerId: playerId,
          page: page,
          size: size,
        )).data!;
        return (items: p.items, totalPages: p.page.totalPages);
      });

  @override
  Future<Uint8List> exportDues(
    DueQuery query, {
    required String language,
  }) async => (await _dues.exportDues(
    xTenantId: _tenant,
    feePlanId: query.planId,
    teamId: query.teamId,
    period: query.period,
    status: query.status,
    acceptLanguage: language,
  )).data!;

  @override
  Future<Uint8List> exportExpenses(
    ExpenseQuery query, {
    required String language,
  }) async => (await _expenses.exportExpenses(
    xTenantId: _tenant,
    from: query.from,
    to: query.to,
    category: query.category,
    acceptLanguage: language,
  )).data!;
}
