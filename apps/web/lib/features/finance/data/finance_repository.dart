import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../domain/due_query.dart';

/// Settings, fee plans, dues and payments (`/api/finance/**`, finance.yaml
/// 1.0.0). Failures surface as the transport's exceptions; screens map them
/// with `AppError.of`.
abstract class FinanceRepository {
  Future<fin.FinanceSettings> settings();
  Future<fin.FinanceSettings> chooseCurrency(String currency);

  Future<fin.FeePlanPage> feePlans({
    bool includeArchived = false,
    int page = 0,
    int size = 200,
  });
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
}

class ApiFinanceRepository implements FinanceRepository {
  ApiFinanceRepository(fin.HoopsFinanceApi client, this._tenant)
    : _settings = client.getSettingsApi(),
      _plans = client.getFeePlansApi(),
      _dues = client.getDuesApi(),
      _payments = client.getPaymentsApi();

  final fin.SettingsApi _settings;
  final fin.FeePlansApi _plans;
  final fin.DuesApi _dues;
  final fin.PaymentsApi _payments;
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
  Future<fin.FeePlanPage> feePlans({
    bool includeArchived = false,
    int page = 0,
    int size = 200,
  }) async => (await _plans.listFeePlans(
    xTenantId: _tenant,
    includeArchived: includeArchived,
    page: page,
    size: size,
  )).data!;

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
}
