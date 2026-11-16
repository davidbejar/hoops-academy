import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/finance/data/finance_repository.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

/// What finance-service answers for an operation it does not serve yet
/// (WP118 handover: dues and payments, until WP119).
const notImplemented = AppError(
  kind: AppErrorKind.server,
  status: 501,
  code: 'NOT_IMPLEMENTED',
);

/// The finance repository of the widget tests: the real [ApiFinanceRepository]
/// over the demo mock's seed (the same plans and dues the demo shows), with the
/// hooks the screens' tests need: a call log, a hang, a failure for everything
/// or for one operation.
class FakeFinanceRepository implements FinanceRepository {
  FakeFinanceRepository({
    List<String> roles = const ['ADMIN'],
    String tenant = mockTenantAId,
  }) : _inner = ApiFinanceRepository(
         fin.HoopsFinanceApi(
           dio:
               Dio(
                   BaseOptions(
                     baseUrl: 'http://mock',
                     headers: {'Authorization': 'Bearer x'},
                   ),
                 )
                 ..httpClientAdapter = MockApiAdapter(
                   roles: roles,
                   norteRoles: roles,
                 ),
           interceptors: const [],
         ),
         tenant,
       );

  final FinanceRepository _inner;

  /// Names of the operations called, in order (`settings`, `dues`, `payDue`).
  final List<String> calls = [];

  /// Never answers (the loading state).
  bool hang = false;

  /// Thrown by every operation.
  Object? failWith;

  /// Thrown by the named operations only (`dues`, `due`, `generateDues`).
  final Map<String, Object> failOn = {};

  /// The arguments of the last call of an operation.
  final Map<String, Object?> last = {};

  /// Fails the operations a service without WP119 answers 501 to.
  void notYetServed() {
    for (final name in [
      'dues',
      'due',
      'generateDues',
      'changeDueAmount',
      'waiveDue',
      'payDue',
      'voidPayment',
    ]) {
      failOn[name] = notImplemented;
    }
  }

  Future<T> _call<T>(
    String name,
    Future<T> Function() body, [
    Object? arguments,
  ]) async {
    calls.add(name);
    last[name] = arguments;
    if (hang) await Completer<void>().future;
    final error = failOn[name] ?? failWith;
    if (error != null) throw error;
    return body();
  }

  @override
  Future<fin.FinanceSettings> settings() => _call('settings', _inner.settings);

  @override
  Future<fin.FinanceSettings> chooseCurrency(String currency) =>
      _call('chooseCurrency', () => _inner.chooseCurrency(currency), currency);

  @override
  Future<fin.FeePlanPage> feePlans({
    bool includeArchived = false,
    int page = 0,
    int size = 200,
  }) => _call(
    'feePlans',
    () => _inner.feePlans(
      includeArchived: includeArchived,
      page: page,
      size: size,
    ),
    includeArchived,
  );

  @override
  Future<fin.FeePlan> createFeePlan(fin.CreateFeePlanRequest request) =>
      _call('createFeePlan', () => _inner.createFeePlan(request), request);

  @override
  Future<fin.FeePlan> updateFeePlan(
    String feePlanId,
    fin.UpdateFeePlanRequest request,
  ) => _call(
    'updateFeePlan',
    () => _inner.updateFeePlan(feePlanId, request),
    request,
  );

  @override
  Future<fin.FeePlan> setFeePlanArchived(
    String feePlanId, {
    required bool archived,
  }) => _call(
    'setFeePlanArchived',
    () => _inner.setFeePlanArchived(feePlanId, archived: archived),
    archived,
  );

  @override
  Future<void> deleteFeePlan(String feePlanId) =>
      _call('deleteFeePlan', () => _inner.deleteFeePlan(feePlanId), feePlanId);

  @override
  Future<fin.DueGeneration> generateDues(
    String feePlanId, {
    required String period,
    bool preview = false,
  }) => _call(
    'generateDues',
    () => _inner.generateDues(feePlanId, period: period, preview: preview),
    (feePlanId, period, preview),
  );

  @override
  Future<fin.DuePage> dues(DueQuery query) =>
      _call('dues', () => _inner.dues(query), query);

  @override
  Future<fin.DueDetail> due(String dueId) =>
      _call('due', () => _inner.due(dueId), dueId);

  @override
  Future<fin.Due> changeDueAmount(
    String dueId, {
    required int amountMinor,
    required String reason,
  }) => _call(
    'changeDueAmount',
    () =>
        _inner.changeDueAmount(dueId, amountMinor: amountMinor, reason: reason),
    (dueId, amountMinor, reason),
  );

  @override
  Future<fin.Due> waiveDue(String dueId, String reason) =>
      _call('waiveDue', () => _inner.waiveDue(dueId, reason), (dueId, reason));

  @override
  Future<fin.Due> payDue(
    String dueId, {
    required fin.Date paidOn,
    required fin.PaymentMethod method,
    String? note,
  }) => _call(
    'payDue',
    () => _inner.payDue(dueId, paidOn: paidOn, method: method, note: note),
    (dueId, paidOn, method, note),
  );

  @override
  Future<fin.Due> voidPayment(String paymentId, String reason) => _call(
    'voidPayment',
    () => _inner.voidPayment(paymentId, reason),
    (paymentId, reason),
  );

  List<Override> get overrides => [
    financeRepositoryProvider.overrideWithValue(this),
  ];
}
