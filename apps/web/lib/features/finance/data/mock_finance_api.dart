import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../../core/time/dates.dart';
import '../../../core/mock/mock_core_api.dart';
import '../../../core/time/tenant_zone.dart';
import '../../../core/mock/mock_query.dart';
import '../domain/currencies.dart';
import '../domain/money.dart';
import '../domain/periods.dart';

part 'mock_finance_reads.dart';

/// In-memory finance-service for the demo (`HOOPS_MOCK_API=true`): settings,
/// fee plans, dues and payments of finance.yaml 1.0.0 with the rules of
/// ADR-0056, JSON in and out like the real service behind the generated
/// client. The roster, the teams and the seasons come from [core], so the
/// demo's dues belong to the demo's players.
///
/// Expenses, the season balance, the coach's and the family's reads and the
/// CSV exports are in `mock_finance_reads.dart`. The service answered 501
/// `NOT_IMPLEMENTED` for them until WP123; the screens still degrade on that
/// answer (tested with a failure injected in front of this mock).
class MockFinanceApi {
  MockFinanceApi({required this.core, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _seed();
  }

  final MockCoreApi core;
  final DateTime Function() _now;

  static const monthlyPlanId = 'fp-mini-a';
  static const seasonPlanId = 'fp-u12-season';
  static const archivedPlanId = 'fp-premini-2025';

  static const _zone = 'Europe/Madrid';

  /// Only the core mock's tenant-scoped answers (the profile) use it; the
  /// reads here are of the roster, teams and seasons.
  static const _coreTenant = 'finance-mock';

  String? _currency;
  final List<Map<String, Object?>> _plans = [];
  final List<Map<String, Object?>> _dues = [];
  final List<Map<String, Object?>> _expenses = [];
  var _seq = 0;

  // ------------------------------------------------------------------- seed
  void _seed() {
    if (core.academy != MockAcademy.demo) return;
    seedCurrency('EUR');
    seedPlan(
      id: monthlyPlanId,
      name: 'Cuota mensual Mini A',
      seasonId: 'season-2026',
      teamId: MockCoreApi.ownTeamId,
      amount: 4500,
      cadence: 'MONTHLY',
      first: '2026-09',
    );
    seedPlan(
      id: seasonPlanId,
      name: 'Matrícula Mini',
      seasonId: 'season-2026',
      categoryId: 'cat-u12',
      amount: 12000,
      cadence: 'SEASON',
    );
    seedPlan(
      id: archivedPlanId,
      name: 'Cuota Premini 2025/26',
      seasonId: 'season-2025',
      teamId: MockCoreApi.pastTeamId,
      amount: 3000,
      cadence: 'MONTHLY',
      first: '2025-09',
      archived: true,
    );
    // Three months of the monthly plan: September settled (one waived),
    // October half paid, November just opened.
    seedDues(monthlyPlanId, '2026-09', paid: 7, waived: 5);
    seedDues(monthlyPlanId, '2026-10', paid: 4);
    seedDues(monthlyPlanId, '2026-11', paid: 1);
    _seedExpenses();
  }

  // ------------------------------------------------------------ test seeding
  // The demo seeds itself with these; the widget tests (ADR-0070) seed an
  // empty academy with them, explicitly, instead of reading the demo's data.

  /// The academy's currency (null: not chosen yet). Plans take the currency
  /// of the moment they are seeded.
  @visibleForTesting
  void seedCurrency(String? code) => _currency = code;

  /// A fee plan, as `POST /fee-plans` would have made it.
  @visibleForTesting
  void seedPlan({
    required String id,
    required String name,
    required String seasonId,
    String? teamId,
    String? categoryId,
    required int amount,
    required String cadence,
    String? first,
    String? last,
    bool archived = false,
  }) => _plans.add(
    _newPlan(
      id: id,
      name: name,
      seasonId: seasonId,
      teamId: teamId,
      categoryId: categoryId,
      amount: amount,
      cadence: cadence,
      first: first,
      last: last,
      archived: archived,
    ),
  );

  /// The dues of [planId] for [period], one per player the plan charges (its
  /// team's roster, in name order). The first [paid] players have paid (on
  /// day 3 to 6 of the month, by cash, transfer and card in turn), except
  /// the one at [waived], whose due is waived; the others are open.
  @visibleForTesting
  void seedDues(String planId, String period, {int paid = 0, int? waived}) {
    final plan = _plans.firstWhere((x) => x['id'] == planId);
    final p = Period.tryParse(period)!;
    for (final (i, player) in _rosterOf(planId).indexed) {
      final due = _newDue(plan, player, p);
      if (i == waived) {
        due['status'] = 'WAIVED';
        due['reason'] = 'Beca de la temporada';
      } else if (i < paid) {
        _addPayment(
          due,
          paidOn: isoDateOf(p.start.year, p.start.month, 3 + i % 4),
          method: ['CASH', 'BANK_TRANSFER', 'CARD'][i % 3],
        );
      }
      _dues.add(due);
    }
    plan['hasDues'] = true;
  }

  /// An expense, as `POST /expenses` would have made it.
  @visibleForTesting
  void seedExpense(
    String day,
    String category,
    int amount,
    String description, {
    String? note,
  }) => _expenses.add(_newExpense(day, category, amount, description, note));

  /// The dues as the service keeps them (with their payments), in the order
  /// they were made.
  @visibleForTesting
  List<Map<String, Object?>> get dues => _dues;

  // ------------------------------------------------------------------ model
  Map<String, Object?> _newPlan({
    required String id,
    required String name,
    required String seasonId,
    String? teamId,
    String? categoryId,
    required int amount,
    required String cadence,
    String? first,
    String? last,
    bool archived = false,
  }) {
    final at = _stamp();
    return {
      'id': id,
      'name': name,
      'seasonId': seasonId,
      'teamId': teamId,
      'ageCategoryId': categoryId,
      'amountMinor': amount,
      'currency': _currency,
      'cadence': cadence,
      'firstPeriod': first,
      'lastPeriod': last,
      'autoGenerate': true,
      'archived': archived,
      'hasDues': false,
      'createdAt': at,
      'updatedAt': at,
    };
  }

  /// The players a plan charges: the roster of its team, or of every team of
  /// its age category in its season, each with the team they owe through.
  List<({String id, String name, String teamId})> _rosterOf(String planId) {
    final plan = _plans.firstWhere((p) => p['id'] == planId);
    final teams = plan['teamId'] != null
        ? ['${plan['teamId']}']
        : [for (final t in _teamsOf(plan)) '${t['id']}'];
    final seen = <String>{};
    final players = <({String id, String name, String teamId})>[];
    for (final team in teams) {
      for (final id in core.rosterOf(team)) {
        if (!seen.add(id)) continue;
        players.add((
          id: id,
          name: core.playerFacts(id, teamId: team)!.name,
          teamId: team,
        ));
      }
    }
    players.sort((a, b) => a.name.compareTo(b.name));
    return players;
  }

  List<Map<String, Object?>> _teamsOf(Map<String, Object?> plan) {
    final page = core.handle(
      tenantId: _coreTenant,
      method: 'GET',
      path: '/api/core/teams',
      query: {
        'size': 200,
        'seasonId': plan['seasonId'],
        if (plan['ageCategoryId'] != null)
          'ageCategoryId': plan['ageCategoryId'],
      },
    );
    return [
      for (final t in ((page!.json! as Map)['items']! as List))
        (t as Map).cast<String, Object?>(),
    ];
  }

  Map<String, Object?> _newDue(
    Map<String, Object?> plan,
    ({String id, String name, String teamId}) player,
    Period period,
  ) {
    final span = _span(plan, period);
    final at = _stamp();
    return {
      'id': 'due-${_seq++}',
      'feePlanId': plan['id'],
      'feePlanName': plan['name'],
      'playerId': player.id,
      'playerName': player.name,
      'teamId': player.teamId,
      'period': period.key,
      'periodStart': span.start,
      'periodEnd': span.end,
      'amountMinor': plan['amountMinor'],
      'planAmountMinor': plan['amountMinor'],
      'currency': plan['currency'],
      'status': 'OPEN',
      'reason': null,
      'payment': null,
      'payments': <Map<String, Object?>>[],
      'createdAt': at,
      'updatedAt': at,
    };
  }

  /// The dates of [period] inside the plan's season (a SEASON period is the
  /// season's dates).
  ({String start, String end}) _span(Map<String, Object?> plan, Period period) {
    final season = _season('${plan['seasonId']}');
    final seasonStart = '${season['startsOn']}';
    final seasonEnd = '${season['endsOn']}';
    if (period.kind == PeriodKind.season) {
      return (start: seasonStart, end: seasonEnd);
    }
    String iso(DateTime d) => isoDateOf(d.year, d.month, d.day);
    final start = iso(period.start);
    final end = iso(period.end);
    return (
      start: start.compareTo(seasonStart) < 0 ? seasonStart : start,
      end: end.compareTo(seasonEnd) > 0 ? seasonEnd : end,
    );
  }

  Map<String, Object?> _season(String id) {
    final all = core
        .handle(
          tenantId: _coreTenant,
          method: 'GET',
          path: '/api/core/seasons',
          query: const {},
        )!
        .json!;
    return (all as List).cast<Map<String, Object?>>().firstWhere(
      (s) => s['id'] == id,
    );
  }

  String _stamp() => _now().toUtc().toIso8601String();

  String _today() {
    final d = TenantZone.of(_zone).today(_now());
    return isoDateOf(d.year, d.month, d.day);
  }

  void _addPayment(
    Map<String, Object?> due, {
    required String paidOn,
    required String method,
    String? note,
  }) {
    final payment = <String, Object?>{
      'id': 'pay-${_seq++}',
      'dueId': due['id'],
      'amountMinor': due['amountMinor'],
      'paidOn': paidOn,
      'method': method,
      'note': note,
      'recordedBy': _me,
      'recordedAt': _stamp(),
      'voided': false,
      'voidedAt': null,
      'voidReason': null,
      'voidedBy': null,
    };
    (due['payments']! as List<Map<String, Object?>>).add(payment);
    due['payment'] = payment;
    due['status'] = 'PAID';
  }

  Map<String, Object?> get _me => {
    'personId': core.selfId,
    'displayName': core.selfName,
  };

  // ---------------------------------------------------------------- routing
  /// Null when [path] is not a finance-service path.
  MockResult? handle({
    required String method,
    required String path,
    required Map<String, dynamic> query,
    Object? body,
    String? language,
  }) {
    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    if (seg.length < 3 || seg[0] != 'api' || seg[1] != 'finance') return null;
    final q = MockQuery(query);
    // The two reads of the coach and of the family decide who may ask.
    if (method == 'GET' && seg.length == 5) {
      if (seg[2] == 'teams' && seg[4] == 'due-status') {
        return _teamDueStatus(seg[3]);
      }
      if (seg[2] == 'players' && seg[4] == 'dues') {
        return _playerDues(seg[3], q);
      }
    }
    // Everything else is ADMIN's.
    if (!core.authz.admin) return mockProblem(403, 'Forbidden');
    final b = body is Map ? body.cast<String, Object?>() : <String, Object?>{};
    // A path segment can carry an action: `fee-plans/x:archive`.
    final head = seg[2].split(':');
    final res = head.first;
    final action = head.length > 1 ? head[1] : null;
    final rest = seg.skip(3).toList();
    final id = rest.isEmpty ? null : rest.first.split(':').first;
    final idAction = rest.isEmpty || !rest.first.contains(':')
        ? null
        : rest.first.split(':')[1];

    switch (res) {
      case 'settings':
        if (method == 'GET') return _settingsJson();
        if (method == 'PUT') return _chooseCurrency(b);
      case 'fee-plans':
        if (id == null && method == 'GET') return _listPlans(q);
        if (id == null && method == 'POST') return _createPlan(b);
        if (id != null && rest.length == 1) {
          if (idAction == null && method == 'GET') return _getPlan(id);
          if (idAction == null && method == 'PATCH') return _updatePlan(id, b);
          if (idAction == null && method == 'DELETE') return _deletePlan(id);
          if (idAction == 'archive' && method == 'POST') {
            return _setArchived(id, true);
          }
          if (idAction == 'unarchive' && method == 'POST') {
            return _setArchived(id, false);
          }
        }
        if (id != null && rest.length == 2 && rest[1] == 'dues:generate') {
          return _generate(id, b);
        }
      case 'dues':
        if (action == 'export') return _exportDues(q, language);
        if (id == null && method == 'GET') return _listDues(q);
        if (id != null && idAction == null && method == 'GET') {
          return _getDue(id);
        }
        if (id != null && method == 'POST') {
          if (idAction == 'change-amount') return _changeAmount(id, b);
          if (idAction == 'waive') return _waive(id, b);
          if (idAction == 'pay') return _pay(id, b);
        }
      case 'payments':
        if (id != null && idAction == 'void' && method == 'POST') {
          return _void(id, b);
        }
      case 'expenses':
        if (action == 'export') return _exportExpenses(q, language);
        if (id == null && method == 'GET') return _listExpenses(q);
        if (id == null && method == 'POST') return _createExpense(b);
        if (id != null && method == 'PATCH') return _updateExpense(id, b);
        if (id != null && method == 'DELETE') return _deleteExpense(id);
      case 'balance':
        if (method == 'GET') return _balance(q);
    }
    return null;
  }

  // --------------------------------------------------------------- settings
  MockResult _settingsJson() => MockResult.json(200, {
    'currency': _currency,
    'minorDigits': _currency == null ? null : financeCurrencies[_currency],
    'currencyLocked': _dues.isNotEmpty,
  });

  MockResult _chooseCurrency(Map<String, Object?> b) {
    final code = b['currency'];
    if (code is! String || !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      return mockProblem(400, 'Bad Request');
    }
    if (!financeCurrencies.containsKey(code)) {
      return mockProblem(422, 'Unknown currency', code: 'UNKNOWN_CURRENCY');
    }
    if (_dues.isNotEmpty && code != _currency) {
      return mockProblem(409, 'Currency is locked', code: 'CURRENCY_LOCKED');
    }
    _currency = code;
    for (final p in _plans) {
      p['currency'] = code;
    }
    return _settingsJson();
  }

  // -------------------------------------------------------------- fee plans
  MockResult _listPlans(MockQuery q) {
    final all = q.text('includeArchived') == 'true';
    final plans = [
      for (final p in _plans)
        if ((all || p['archived'] != true) &&
            (q.text('seasonId') == null || p['seasonId'] == q.text('seasonId')))
          p,
    ]..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    return q.page(plans);
  }

  MockResult _getPlan(String id) {
    final plan = _plans.where((p) => p['id'] == id).firstOrNull;
    return plan == null
        ? mockProblem(404, 'Not found')
        : MockResult.json(200, plan);
  }

  MockResult _createPlan(Map<String, Object?> b) {
    final name = b['name'];
    final amount = b['amountMinor'];
    final cadence = b['cadence'];
    final teamId = b['teamId'] as String?;
    final categoryId = b['ageCategoryId'] as String?;
    final first = b['firstPeriod'] as String?;
    final last = b['lastPeriod'] as String?;
    if (name is! String || name.trim().isEmpty || name.length > 80) {
      return mockProblem(400, 'Bad Request');
    }
    if (!_validAmount(amount)) return mockProblem(400, 'Bad Request');
    if (cadence is! String ||
        !const {'MONTHLY', 'QUARTERLY', 'SEASON'}.contains(cadence)) {
      return mockProblem(400, 'Bad Request');
    }
    if ((teamId == null) == (categoryId == null)) {
      return mockProblem(
        400,
        'Exactly one target',
        code: 'ONE_TARGET_REQUIRED',
      );
    }
    final periodsOk = _validPeriods(cadence, first, last);
    if (periodsOk != null) return periodsOk;
    if (_currency == null) {
      return mockProblem(409, 'Currency not set', code: 'CURRENCY_NOT_SET');
    }
    final seasonId = b['seasonId'] as String?;
    if (seasonId == null) return mockProblem(400, 'Bad Request');
    if (teamId != null) {
      final team = _teamsInSeasons()
          .where((t) => t['id'] == teamId)
          .firstOrNull;
      if (team == null)
        return mockProblem(422, 'Unknown team', code: 'UNKNOWN_TEAM');
      if (team['seasonId'] != seasonId) {
        return mockProblem(
          422,
          'Team not in season',
          code: 'TEAM_NOT_IN_SEASON',
        );
      }
    }
    final plan = _newPlan(
      id: 'fp-${_seq++}',
      name: name.trim(),
      seasonId: seasonId,
      teamId: teamId,
      categoryId: categoryId,
      amount: amount as int,
      cadence: cadence,
      first: first,
      last: last,
    )..['autoGenerate'] = b['autoGenerate'] ?? true;
    _plans.add(plan);
    return MockResult.json(201, plan);
  }

  List<Map<String, Object?>> _teamsInSeasons() {
    final page = core.handle(
      tenantId: _coreTenant,
      method: 'GET',
      path: '/api/core/teams',
      query: const {'size': 200},
    );
    return [
      for (final t in ((page!.json! as Map)['items']! as List))
        (t as Map).cast<String, Object?>(),
    ];
  }

  static bool _validAmount(Object? amount) =>
      amount is int && amount >= 1 && amount <= MoneyFormat.maxAmountMinor;

  /// Null when the periods suit the cadence; else the 400 to answer.
  MockResult? _validPeriods(String cadence, String? first, String? last) {
    if (cadence == 'SEASON') {
      return first != null || last != null
          ? mockProblem(400, 'Not allowed', code: 'NOT_ALLOWED')
          : null;
    }
    final kind = cadence == 'MONTHLY' ? PeriodKind.month : PeriodKind.quarter;
    final a = first == null ? null : Period.tryParse(first);
    if (a == null || a.kind != kind) return mockProblem(400, 'Bad Request');
    if (last != null) {
      final z = Period.tryParse(last);
      if (z == null || z.kind != kind || z.compareTo(a) < 0) {
        return mockProblem(400, 'Bad Request');
      }
    }
    return null;
  }

  MockResult _updatePlan(String id, Map<String, Object?> b) {
    final plan = _plans.where((p) => p['id'] == id).firstOrNull;
    if (plan == null) return mockProblem(404, 'Not found');
    final clear = (b['clear'] as List?)?.cast<String>() ?? const <String>[];
    if (b.isEmpty) return mockProblem(400, 'Bad Request');
    if (b.containsKey('amountMinor') && !_validAmount(b['amountMinor'])) {
      return mockProblem(400, 'Bad Request');
    }
    final name = b['name'];
    if (name != null && (name is! String || name.trim().isEmpty)) {
      return mockProblem(400, 'Bad Request');
    }
    if (clear.contains('lastPeriod') && b['lastPeriod'] != null) {
      return mockProblem(400, 'Bad Request');
    }
    final first = (b['firstPeriod'] as String?) ?? '${plan['firstPeriod']}';
    if (b['firstPeriod'] != null && b['firstPeriod'] != plan['firstPeriod']) {
      if (plan['hasDues'] == true) {
        return mockProblem(409, 'The plan has dues', code: 'FEE_PLAN_HAS_DUES');
      }
    }
    final last = clear.contains('lastPeriod')
        ? null
        : (b['lastPeriod'] as String?) ?? plan['lastPeriod'] as String?;
    final invalid = _validPeriods(
      '${plan['cadence']}',
      plan['cadence'] == 'SEASON' ? null : first,
      last,
    );
    if (invalid != null) return invalid;
    if (name != null) plan['name'] = (name as String).trim();
    if (b['amountMinor'] != null) plan['amountMinor'] = b['amountMinor'];
    if (b['firstPeriod'] != null) plan['firstPeriod'] = b['firstPeriod'];
    if (b['autoGenerate'] != null) plan['autoGenerate'] = b['autoGenerate'];
    if (clear.contains('lastPeriod') || b['lastPeriod'] != null) {
      plan['lastPeriod'] = last;
    }
    plan['updatedAt'] = _stamp();
    return MockResult.json(200, plan);
  }

  MockResult _setArchived(String id, bool archived) {
    final plan = _plans.where((p) => p['id'] == id).firstOrNull;
    if (plan == null) return mockProblem(404, 'Not found');
    plan['archived'] = archived;
    plan['updatedAt'] = _stamp();
    return MockResult.json(200, plan);
  }

  MockResult _deletePlan(String id) {
    final plan = _plans.where((p) => p['id'] == id).firstOrNull;
    if (plan == null) return mockProblem(404, 'Not found');
    if (plan['hasDues'] == true) {
      return mockProblem(409, 'The plan has dues', code: 'FEE_PLAN_HAS_DUES');
    }
    _plans.remove(plan);
    return const MockResult.empty(204);
  }

  // ------------------------------------------------------------------- dues
  MockResult _generate(String id, Map<String, Object?> b) {
    final plan = _plans.where((p) => p['id'] == id).firstOrNull;
    if (plan == null) return mockProblem(404, 'Not found');
    final key = b['period'];
    final period = key is String ? Period.tryParse(key) : null;
    final cadence = '${plan['cadence']}';
    final kind = switch (cadence) {
      'MONTHLY' => PeriodKind.month,
      'QUARTERLY' => PeriodKind.quarter,
      _ => PeriodKind.season,
    };
    if (period == null || period.kind != kind)
      return mockProblem(400, 'Bad Request');
    if (plan['archived'] == true) {
      return mockProblem(
        409,
        'The plan is archived',
        code: 'FEE_PLAN_ARCHIVED',
      );
    }
    final season = _season('${plan['seasonId']}');
    if (kind != PeriodKind.season) {
      final feeCadence = cadence == 'MONTHLY'
          ? fin.FeeCadence.MONTHLY
          : fin.FeeCadence.QUARTERLY;
      final first = Period.tryParse('${plan['firstPeriod']}');
      final last = plan['lastPeriod'] == null
          ? null
          : Period.tryParse('${plan['lastPeriod']}');
      if ((first != null && period.compareTo(first) < 0) ||
          (last != null && period.compareTo(last) > 0)) {
        return mockProblem(
          422,
          'Period outside the plan',
          code: 'PERIOD_OUTSIDE_PLAN',
        );
      }
      final inSeason = periodKeysIn(
        feeCadence,
        _date('${season['startsOn']}'),
        _date('${season['endsOn']}'),
      );
      if (!inSeason.contains(period.key)) {
        return mockProblem(
          422,
          'Period outside the season',
          code: 'PERIOD_OUTSIDE_SEASON',
        );
      }
    }
    final span = _span(plan, period);
    final existing = {
      for (final d in _dues)
        if (d['feePlanId'] == id && d['period'] == period.key)
          '${d['playerId']}': d,
    };
    final preview = b['preview'] == true;
    final made = <Map<String, Object?>>[];
    for (final p in _rosterOf(id)) {
      if (existing.containsKey(p.id)) continue;
      made.add(_newDue(plan, p, period));
    }
    if (!preview) {
      _dues.addAll(made);
      if (made.isNotEmpty) plan['hasDues'] = true;
    }
    return MockResult.json(200, {
      'feePlanId': id,
      'period': period.key,
      'periodStart': span.start,
      'periodEnd': span.end,
      'preview': preview,
      'created': made.length,
      'existing': existing.length,
      'dues': [
        for (final d in made)
          {
            'dueId': preview ? null : d['id'],
            'playerId': d['playerId'],
            'playerName': d['playerName'],
            'teamId': d['teamId'],
            'amountMinor': d['amountMinor'],
          },
      ],
    });
  }

  static DateTime _date(String iso) => DateTime.parse(iso);

  Map<String, Object?> _view(Map<String, Object?> due) => {
    for (final e in due.entries)
      if (e.key != 'payments') e.key: e.value,
  };

  MockResult _listDues(MockQuery q) =>
      q.page([for (final d in _filteredDues(q)) _view(d)]);

  /// The dues of the filters, by period then player.
  List<Map<String, Object?>> _filteredDues(MockQuery q) =>
      [
        for (final d in _dues)
          if ((q.text('feePlanId') == null ||
                  d['feePlanId'] == q.text('feePlanId')) &&
              (q.text('teamId') == null || d['teamId'] == q.text('teamId')) &&
              (q.text('playerId') == null ||
                  d['playerId'] == q.text('playerId')) &&
              (q.text('period') == null || d['period'] == q.text('period')) &&
              (q.text('status') == null || d['status'] == q.text('status')))
            d,
      ]..sort((a, b) {
        final byStart = '${a['periodStart']}'.compareTo('${b['periodStart']}');
        if (byStart != 0) return byStart;
        final byName = '${a['playerName']}'.compareTo('${b['playerName']}');
        return byName != 0 ? byName : '${a['id']}'.compareTo('${b['id']}');
      });

  MockResult _getDue(String id) {
    final due = _dues.where((d) => d['id'] == id).firstOrNull;
    return due == null
        ? mockProblem(404, 'Not found')
        : MockResult.json(200, {
            ..._view(due),
            'payments': [
              for (final p in due['payments']! as List<Map<String, Object?>>) p,
            ].reversed.toList(),
          });
  }

  /// The open due, or the problem to answer.
  ({Map<String, Object?>? due, MockResult? problem}) _open(String id) {
    final due = _dues.where((d) => d['id'] == id).firstOrNull;
    if (due == null) return (due: null, problem: mockProblem(404, 'Not found'));
    if (due['status'] != 'OPEN') {
      return (
        due: null,
        problem: mockProblem(409, 'The due is not open', code: 'DUE_NOT_OPEN'),
      );
    }
    return (due: due, problem: null);
  }

  static bool _validReason(Object? reason) =>
      reason is String && reason.trim().isNotEmpty && reason.length <= 200;

  MockResult _changeAmount(String id, Map<String, Object?> b) {
    if (!_validAmount(b['amountMinor']) || !_validReason(b['reason'])) {
      return mockProblem(400, 'Bad Request');
    }
    final r = _open(id);
    if (r.problem != null) return r.problem!;
    r.due!['amountMinor'] = b['amountMinor'];
    r.due!['reason'] = b['reason'];
    r.due!['updatedAt'] = _stamp();
    return MockResult.json(200, _view(r.due!));
  }

  MockResult _waive(String id, Map<String, Object?> b) {
    if (!_validReason(b['reason'])) return mockProblem(400, 'Bad Request');
    final r = _open(id);
    if (r.problem != null) return r.problem!;
    r.due!['status'] = 'WAIVED';
    r.due!['reason'] = b['reason'];
    r.due!['updatedAt'] = _stamp();
    return MockResult.json(200, _view(r.due!));
  }

  MockResult _pay(String id, Map<String, Object?> b) {
    final paidOn = b['paidOn'];
    final method = b['method'];
    final note = b['note'];
    if (paidOn is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(paidOn) ||
        method is! String ||
        !const {'CASH', 'BANK_TRANSFER', 'CARD', 'OTHER'}.contains(method) ||
        (note != null &&
            (note is! String || note.isEmpty || note.length > 200))) {
      return mockProblem(400, 'Bad Request');
    }
    final r = _open(id);
    if (r.problem != null) return r.problem!;
    if (paidOn.compareTo(_today()) > 0) {
      return mockProblem(
        422,
        'Payment day in the future',
        code: 'PAID_ON_IN_FUTURE',
      );
    }
    _addPayment(r.due!, paidOn: paidOn, method: method, note: note as String?);
    r.due!['updatedAt'] = _stamp();
    return MockResult.json(200, _view(r.due!));
  }

  MockResult _void(String paymentId, Map<String, Object?> b) {
    if (!_validReason(b['reason'])) return mockProblem(400, 'Bad Request');
    for (final due in _dues) {
      for (final p in due['payments']! as List<Map<String, Object?>>) {
        if (p['id'] != paymentId) continue;
        if (p['voided'] == true) {
          return mockProblem(
            409,
            'Already voided',
            code: 'PAYMENT_ALREADY_VOIDED',
          );
        }
        p['voided'] = true;
        p['voidedAt'] = _stamp();
        p['voidReason'] = b['reason'];
        p['voidedBy'] = _me;
        due['payment'] = null;
        due['status'] = 'OPEN';
        due['updatedAt'] = _stamp();
        return MockResult.json(200, _view(due));
      }
    }
    return mockProblem(404, 'Not found');
  }
}
