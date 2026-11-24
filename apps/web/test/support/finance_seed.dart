import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/finance/data/finance_repository.dart';
import 'package:hoops_app/features/finance/data/mock_finance_api.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_app/features/finance/domain/expense_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import 'mock_backend.dart';

/// The finance data of a test (ADR-0070), seeded explicitly into the empty
/// academy of the backend (never the demo's), then what the app asked of it
/// and what the mock answered. Failures the mock cannot produce are injected
/// in front of it.
class FinanceData {
  /// An academy that keeps its accounts: [currency] and what [data] seeds
  /// ([standardFinance] by default).
  FinanceData({this.currency = 'EUR', this.data = standardFinance});

  /// An academy that has not started: no plans, dues or expenses, and no
  /// currency unless [currency] is given.
  FinanceData.empty({this.currency}) : data = null;

  final String? currency;
  final void Function(MockFinanceApi finance)? data;

  static const settingsPath = '/api/finance/settings';
  static const plansPath = '/api/finance/fee-plans';
  static const duesPath = '/api/finance/dues';
  static const expensesPath = '/api/finance/expenses';
  static const balancePath = '/api/finance/balance';
  static const exportDuesPath = '/api/finance/dues:export';
  static const exportExpensesPath = '/api/finance/expenses:export';
  static final generatePath = RegExp(r'/dues:generate$');
  static final payPath = RegExp(r'^/api/finance/dues/[^/]+:pay$');
  static final teamStatusPath = RegExp(
    r'^/api/finance/teams/[^/]+/due-status$',
  );
  static final playerDuesPath = RegExp(r'^/api/finance/players/[^/]+/dues$');
  static final anyPath = RegExp('^/api/finance/');

  /// What finance-service did not serve before WP119 and WP123 (it answered
  /// 501 `NOT_IMPLEMENTED`): everything but the settings and the fee plans.
  static final _notYetServed = RegExp(
    r'^/api/finance/(dues|payments|expenses|balance|teams|players)'
    r'|/dues:generate$',
  );

  MockBackend? _backend;
  final List<void Function(MockBackend)> _pending = [];

  /// The backend it was seeded into.
  MockBackend get backend => _backend!;

  /// Seeds the academy of [backend], whose core already holds the teams,
  /// rosters and seasons the plans refer to.
  void seedInto(MockBackend backend) {
    _backend = backend;
    final finance = backend.academyApis.finance..seedCurrency(currency);
    data?.call(finance);
    for (final fault in _pending) {
      fault(backend);
    }
  }

  void _fault(void Function(MockBackend) fault) =>
      _backend == null ? _pending.add(fault) : fault(_backend!);

  /// Holds every finance request (the loading state).
  void hang() => _fault((b) => b.hang(anyPath));

  /// Answers the requests to [path] (every finance path: null) with a
  /// Problem+JSON of [status] and [code], until [heal].
  void fail({Pattern? path, String? method, int status = 500, String? code}) =>
      _fault(
        (b) =>
            b.fail(path ?? anyPath, method: method, status: status, code: code),
      );

  /// The service before it served dues, expenses and the reads (501).
  void notYetServed() =>
      fail(path: _notYetServed, status: 501, code: 'NOT_IMPLEMENTED');

  /// Forgets the injected failures.
  void heal() {
    _pending.clear();
    _backend?.heal();
  }

  /// The requests the app sent to [path] with [method] (any: null).
  List<RequestOptions> requests(Pattern path, {String? method = 'GET'}) =>
      backend.requestsTo(path, method: method);

  /// Whether the app sent anything to finance-service at all.
  bool get askedAnything =>
      backend.requestsTo(anyPath, method: null).isNotEmpty;

  /// The body of the last request to [path], as the generated model [T].
  T sent<T>(Pattern path, {String method = 'POST'}) =>
      _model<T>(backend.lastBody(path, method: method));

  /// What the mock answered the last request to [path], as the model [T].
  T answered<T>(Pattern path, {String? method = 'GET'}) =>
      _model<T>(backend.lastAnswer(path, method: method));

  /// The id in the path of the last request to [path]
  /// (`/api/finance/dues/{id}:pay`, `/fee-plans/{id}/dues:generate`).
  String lastId(Pattern path, {String? method = 'GET'}) =>
      requests(path, method: method).last.path.split('/')[4].split(':').first;

  /// The filters and page of the last dues list the app asked for.
  DueQuery get dueQuery => _dueQuery(duesPath);

  /// Those of the last dues export.
  DueQuery get exportedDueQuery => _dueQuery(exportDuesPath);

  DueQuery _dueQuery(String path) {
    final q = backend.lastQuery(path);
    final status = q.text('status');
    return DueQuery(
      planId: q.text('feePlanId'),
      teamId: q.text('teamId'),
      period: q.text('period'),
      status: status == null ? null : fin.DueStatus.valueOf(status),
      page: q.integer('page', 0),
      size: q.integer('size', DueQuery.defaultSize),
    );
  }

  /// The filters and page of the last expenses list the app asked for.
  ExpenseQuery get expenseQuery => _expenseQuery(expensesPath);

  /// Those of the last expenses export.
  ExpenseQuery get exportedExpenseQuery => _expenseQuery(exportExpensesPath);

  ExpenseQuery _expenseQuery(String path) {
    final q = backend.lastQuery(path);
    fin.Date? day(String key) {
      final d = q.date(key);
      return d == null ? null : _model<fin.Date>(d);
    }

    final category = q.text('category');
    return ExpenseQuery(
      from: day('from'),
      to: day('to'),
      category: category == null ? null : fin.ExpenseCategory.valueOf(category),
      page: q.integer('page', 0),
      size: q.integer('size', ExpenseQuery.defaultSize),
    );
  }

  /// The language the last request to [path] asked for.
  String? languageOf(Pattern path) =>
      requests(path).last.headers['Accept-Language'] as String?;

  /// The first seeded due with [status] in [period], in the order of the
  /// list (by player), as the service keeps it.
  fin.Due due(fin.DueStatus status, {String period = '2026-11'}) {
    final all = [
      for (final d in backend.academyApis.finance.dues)
        if (d['status'] == status.name && d['period'] == period) d,
    ]..sort((a, b) => '${a['playerName']}'.compareTo('${b['playerName']}'));
    return _model<fin.Due>({
      for (final e in all.first.entries)
        if (e.key != 'payments') e.key: e.value,
    });
  }

  /// The app's own finance repository on the backend, for tests of the
  /// providers without the app.
  FinanceRepository repository() => ApiFinanceRepository(
    fin.HoopsFinanceApi(dio: backend.dio(), interceptors: const []),
    backend.tenantAId,
  );

  /// The finance repository of the providers, on the backend.
  List<Override> get overrides => [
    financeRepositoryProvider.overrideWithValue(repository()),
  ];

  static T _model<T>(Object? json) =>
      fin.standardSerializers.deserialize(json, specifiedType: FullType(T))
          as T;
}

/// The finance academy of the tests: EUR, a monthly plan of Mini A with dues
/// from September to November 2026 (September settled with one waived,
/// October four paid, November one), a season plan of the Mini category
/// without dues, an archived plan of last season, and eight expenses of the
/// season (more spent than collected). Fixed days, so nothing depends on the
/// day the test runs.
void standardFinance(MockFinanceApi f) {
  f
    ..seedPlan(
      id: MockFinanceApi.monthlyPlanId,
      name: 'Cuota mensual Mini A',
      seasonId: 'season-2026',
      teamId: 'team-mini-a',
      amount: 4500,
      cadence: 'MONTHLY',
      first: '2026-09',
    )
    ..seedPlan(
      id: MockFinanceApi.seasonPlanId,
      name: 'Matrícula Mini',
      seasonId: 'season-2026',
      categoryId: 'cat-u12',
      amount: 12000,
      cadence: 'SEASON',
    )
    ..seedPlan(
      id: MockFinanceApi.archivedPlanId,
      name: 'Cuota Premini 2025/26',
      seasonId: 'season-2025',
      teamId: 'team-mini-a-2025',
      amount: 3000,
      cadence: 'MONTHLY',
      first: '2025-09',
      archived: true,
    )
    ..seedDues(MockFinanceApi.monthlyPlanId, '2026-09', paid: 7, waived: 5)
    ..seedDues(MockFinanceApi.monthlyPlanId, '2026-10', paid: 4)
    ..seedDues(MockFinanceApi.monthlyPlanId, '2026-11', paid: 1)
    ..seedExpense(
      '2026-09-02',
      'COURT_RENTAL',
      9000,
      'Alquiler del pabellón, septiembre',
    )
    ..seedExpense(
      '2026-09-15',
      'KIT',
      6000,
      'Equipaciones de la temporada',
      note: 'Factura 2026-114',
    )
    ..seedExpense(
      '2026-10-02',
      'COURT_RENTAL',
      9000,
      'Alquiler del pabellón, octubre',
    )
    ..seedExpense(
      '2026-10-20',
      'TOURNAMENT_FEES',
      3500,
      'Inscripción del torneo de otoño',
    )
    ..seedExpense(
      '2026-10-28',
      'TRAVEL',
      2500,
      'Autobús al partido fuera de casa',
    )
    ..seedExpense(
      '2026-11-03',
      'COURT_RENTAL',
      9000,
      'Alquiler del pabellón, noviembre',
    )
    ..seedExpense('2026-11-10', 'SALARIES', 15000, 'Entrenadores, noviembre')
    ..seedExpense('2026-11-12', 'OTHER', 1500, 'Material de oficina');
}
