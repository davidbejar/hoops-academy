part of 'mock_finance_api.dart';

/// Expenses, the season balance, the coach's and the family's reads and the
/// CSV exports of the demo finance-service (finance.yaml 1.0.0, ADR-0056, the
/// matrix of decision 96).
extension _MockFinanceReads on MockFinanceApi {
  static const _categories = [
    'COURT_RENTAL',
    'SALARIES',
    'KIT',
    'TOURNAMENT_FEES',
    'TRAVEL',
    'OTHER',
  ];

  /// The demo's expenses: a season's worth of what an academy pays for.
  void _seedExpenses() {
    for (final (day, category, amount, text, note) in [
      (
        '2026-09-02',
        'COURT_RENTAL',
        9000,
        'Alquiler del pabellón, septiembre',
        null,
      ),
      (
        '2026-09-15',
        'KIT',
        6000,
        'Equipaciones de la temporada',
        'Factura 2026-114',
      ),
      (
        '2026-10-02',
        'COURT_RENTAL',
        9000,
        'Alquiler del pabellón, octubre',
        null,
      ),
      (
        '2026-10-20',
        'TOURNAMENT_FEES',
        3500,
        'Inscripción del torneo de otoño',
        null,
      ),
      ('2026-10-28', 'TRAVEL', 2500, 'Autobús al partido fuera de casa', null),
      (
        '2026-11-03',
        'COURT_RENTAL',
        9000,
        'Alquiler del pabellón, noviembre',
        null,
      ),
      ('2026-11-10', 'SALARIES', 15000, 'Entrenadores, noviembre', null),
      ('2026-11-12', 'OTHER', 1500, 'Material de oficina', null),
    ]) {
      _expenses.add(_newExpense(day, category, amount, text, note));
    }
  }

  Map<String, Object?> _newExpense(
    String day,
    String category,
    int amount,
    String text,
    String? note,
  ) {
    final at = _stamp();
    return {
      'id': 'ex-${_seq++}',
      'spentOn': day,
      'category': category,
      'amountMinor': amount,
      'currency': _currency,
      'description': text,
      'note': note,
      'createdAt': at,
      'updatedAt': at,
    };
  }

  static final _dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  // ---------------------------------------------------------------- expenses
  MockResult _listExpenses(MockQuery q) =>
      q.page([for (final e in _filteredExpenses(q)) e]);

  /// Newest first: the day, then the order of creation.
  List<Map<String, Object?>> _filteredExpenses(MockQuery q) {
    final from = q.date('from');
    final to = q.date('to');
    final category = q.text('category');
    final list = [
      for (final e in _expenses)
        if ((from == null || '${e['spentOn']}'.compareTo(from) >= 0) &&
            (to == null || '${e['spentOn']}'.compareTo(to) <= 0) &&
            (category == null || e['category'] == category))
          e,
    ];
    final order = {for (final (i, e) in _expenses.indexed) e: i};
    list.sort((a, b) {
      final byDay = '${b['spentOn']}'.compareTo('${a['spentOn']}');
      return byDay != 0 ? byDay : order[b]!.compareTo(order[a]!);
    });
    return list;
  }

  static bool _validText(Object? v, int max) =>
      v is String && v.trim().isNotEmpty && v.length <= max;

  MockResult _createExpense(Map<String, Object?> b) {
    final spentOn = b['spentOn'];
    final note = b['note'];
    if (spentOn is! String ||
        !_dayPattern.hasMatch(spentOn) ||
        !_categories.contains(b['category']) ||
        !MockFinanceApi._validAmount(b['amountMinor']) ||
        !_validText(b['description'], 120) ||
        (note != null && !_validText(note, 200))) {
      return MockFinanceApi._problem(400, 'Bad Request');
    }
    if (_currency == null) {
      return MockFinanceApi._problem(
        409,
        'Currency not set',
        'CURRENCY_NOT_SET',
      );
    }
    final expense = _newExpense(
      spentOn,
      '${b['category']}',
      b['amountMinor']! as int,
      '${b['description']}'.trim(),
      note as String?,
    );
    _expenses.add(expense);
    return MockResult.json(201, expense);
  }

  MockResult _updateExpense(String id, Map<String, Object?> b) {
    final expense = _expenses.where((e) => e['id'] == id).firstOrNull;
    if (expense == null) return MockFinanceApi._problem(404, 'Not found');
    final clear = (b['clear'] as List?)?.cast<String>() ?? const <String>[];
    final given = {
      for (final key in const [
        'spentOn',
        'category',
        'amountMinor',
        'description',
        'note',
      ])
        if (b[key] != null) key,
    };
    if (given.isEmpty && clear.isEmpty)
      return MockFinanceApi._problem(400, 'Bad Request');
    if ((clear.contains('note') && b['note'] != null) ||
        clear.any((c) => c != 'note')) {
      return MockFinanceApi._problem(400, 'Bad Request');
    }
    if ((given.contains('spentOn') &&
            !(b['spentOn'] is String &&
                _dayPattern.hasMatch('${b['spentOn']}'))) ||
        (given.contains('category') && !_categories.contains(b['category'])) ||
        (given.contains('amountMinor') &&
            !MockFinanceApi._validAmount(b['amountMinor'])) ||
        (given.contains('description') && !_validText(b['description'], 120)) ||
        (given.contains('note') && !_validText(b['note'], 200))) {
      return MockFinanceApi._problem(400, 'Bad Request');
    }
    for (final key in given) {
      expense[key] = key == 'description' ? '${b[key]}'.trim() : b[key];
    }
    if (clear.contains('note')) expense['note'] = null;
    expense['updatedAt'] = _stamp();
    return MockResult.json(200, expense);
  }

  MockResult _deleteExpense(String id) {
    final expense = _expenses.where((e) => e['id'] == id).firstOrNull;
    if (expense == null) return MockFinanceApi._problem(404, 'Not found');
    _expenses.remove(expense);
    return const MockResult.empty(204);
  }

  // ----------------------------------------------------------------- balance
  MockResult _balance(MockQuery q) {
    final id = q.text('seasonId');
    if (id == null) return MockFinanceApi._problem(400, 'Bad Request');
    final season =
        core
                .handle(
                  tenantId: MockFinanceApi._coreTenant,
                  method: 'GET',
                  path: '/api/core/seasons',
                  query: const {},
                )!
                .json!
            as List;
    final found = season
        .cast<Map<String, Object?>>()
        .where((s) => s['id'] == id)
        .firstOrNull;
    if (found == null) return MockFinanceApi._problem(404, 'Not found');
    if (_currency == null) {
      return MockFinanceApi._problem(
        409,
        'Currency not set',
        'CURRENCY_NOT_SET',
      );
    }
    final plans = {
      for (final p in _plans)
        if (p['seasonId'] == id) p['id'],
    };
    var paid = 0, open = 0, waived = 0;
    for (final d in _dues) {
      if (!plans.contains(d['feePlanId'])) continue;
      final amount = d['amountMinor']! as int;
      switch (d['status']) {
        case 'PAID':
          paid += amount;
        case 'WAIVED':
          waived += amount;
        default:
          open += amount;
      }
    }
    final from = '${found['startsOn']}';
    final to = '${found['endsOn']}';
    final totals = {for (final c in _categories) c: 0};
    for (final e in _expenses) {
      final day = '${e['spentOn']}';
      if (day.compareTo(from) < 0 || day.compareTo(to) > 0) continue;
      totals['${e['category']}'] =
          totals['${e['category']}']! + (e['amountMinor']! as int);
    }
    final spent = totals.values.fold<int>(0, (a, b) => a + b);
    return MockResult.json(200, {
      'seasonId': id,
      'from': from,
      'to': to,
      'currency': _currency,
      'income': {'paidMinor': paid, 'openMinor': open, 'waivedMinor': waived},
      'expenses': {
        'totalMinor': spent,
        'byCategory': [
          for (final e in totals.entries)
            {'category': e.key, 'totalMinor': e.value},
        ],
      },
      'netMinor': paid - spent,
    });
  }

  // ---------------------------------------------------------- coach's reads
  /// Who of the team is up to date. ADMIN: any team of the academy (404 for
  /// an unknown one); COACH: only a team they are current COACH of (ADR-0056
  /// WP119: an assistant, a parent, a player and a former coach get 403).
  MockResult _teamDueStatus(String teamId) {
    final a = core.authz;
    final coach =
        core.roles.contains('COACH') && a.staffTeamIds.contains(teamId);
    if (!a.admin && !coach) return MockFinanceApi._problem(403, 'Forbidden');
    final known = _teamsInSeasons().any((t) => t['id'] == teamId);
    if (!known) return MockFinanceApi._problem(404, 'Not found');
    final today = _today();
    final behind = {
      for (final d in _dues)
        if (d['status'] == 'OPEN' &&
            '${d['periodStart']}'.compareTo(today) <= 0)
          d['playerId'],
    };
    final players = [
      for (final id in core.rosterOf(teamId))
        (id: id, name: core.playerFacts(id, teamId: teamId)!.name),
    ]..sort((x, y) => x.name.compareTo(y.name));
    return MockResult.json(200, {
      'teamId': teamId,
      'players': [
        for (final p in players)
          {
            'playerId': p.id,
            'playerName': p.name,
            'upToDate': !behind.contains(p.id),
          },
      ],
    });
  }

  // --------------------------------------------------------- family's reads
  /// A player's dues as the family sees them. ADMIN: any player (empty for
  /// one without dues); PARENT of a linked player; the PLAYER themself; every
  /// other member, and any unlinked player, 403.
  MockResult _playerDues(String playerId, MockQuery q) {
    final a = core.authz;
    final allowed =
        a.admin ||
        a.linkedPlayerIds.contains(playerId) ||
        a.selfPlayerIds.contains(playerId);
    if (!allowed) return MockFinanceApi._problem(403, 'Forbidden');
    final dues = [
      for (final d in _dues)
        if (d['playerId'] == playerId) d,
    ]..sort((x, y) => '${y['periodStart']}'.compareTo('${x['periodStart']}'));
    return q.page([
      for (final d in dues)
        {
          'id': d['id'],
          'feePlanName': d['feePlanName'],
          'period': d['period'],
          'periodStart': d['periodStart'],
          'periodEnd': d['periodEnd'],
          'amountMinor': d['amountMinor'],
          'currency': d['currency'],
          'status': d['status'],
          'paidOn': d['status'] == 'PAID'
              ? (d['payment']! as Map)['paidOn']
              : null,
          'paymentMethod': d['status'] == 'PAID'
              ? (d['payment']! as Map)['method']
              : null,
        },
    ]);
  }

  // ----------------------------------------------------------------- exports
  static const _expenseHeader = {
    'es': [
      'Día',
      'Categoría',
      'Código',
      'Importe (unidad menor)',
      'Moneda',
      'Descripción',
    ],
    'id': [
      'Hari',
      'Kategori',
      'Kode',
      'Jumlah (satuan terkecil)',
      'Mata uang',
      'Keterangan',
    ],
    'en': [
      'Day',
      'Category',
      'Code',
      'Amount (minor units)',
      'Currency',
      'Description',
    ],
  };

  static const _dueHeader = {
    'es': [
      'Periodo',
      'Inicio',
      'Fin',
      'Plan',
      'Jugador',
      'Equipo',
      'Importe (unidad menor)',
      'Moneda',
      'Estado',
      'Pagada el',
      'Método',
    ],
    'id': [
      'Periode',
      'Mulai',
      'Akhir',
      'Rencana',
      'Pemain',
      'Tim',
      'Jumlah (satuan terkecil)',
      'Mata uang',
      'Status',
      'Dibayar pada',
      'Metode',
    ],
    'en': [
      'Period',
      'Start',
      'End',
      'Plan',
      'Player',
      'Team',
      'Amount (minor units)',
      'Currency',
      'Status',
      'Paid on',
      'Method',
    ],
  };

  static const _categoryLabel = {
    'es': [
      'Alquiler de pista',
      'Sueldos',
      'Equipación',
      'Cuotas de torneos',
      'Viajes',
      'Otros',
    ],
    'id': [
      'Sewa lapangan',
      'Gaji',
      'Perlengkapan',
      'Biaya turnamen',
      'Perjalanan',
      'Lainnya',
    ],
    'en': [
      'Court rental',
      'Salaries',
      'Kit',
      'Tournament fees',
      'Travel',
      'Other',
    ],
  };

  static const _statusLabel = {
    'es': {'OPEN': 'Pendiente', 'PAID': 'Pagada', 'WAIVED': 'Condonada'},
    'id': {'OPEN': 'Belum dibayar', 'PAID': 'Lunas', 'WAIVED': 'Dibebaskan'},
    'en': {'OPEN': 'Open', 'PAID': 'Paid', 'WAIVED': 'Waived'},
  };

  static String _language(String? header) {
    final first = (header ?? 'en').toLowerCase();
    return first.startsWith('es')
        ? 'es'
        : (first.startsWith('id') ? 'id' : 'en');
  }

  /// A cell that starts like a formula is quoted with `'` (ADR-0048).
  static String _cell(String v) {
    final guarded = v.isNotEmpty && '=+-@\t\r'.contains(v[0]) ? "'$v" : v;
    return guarded.contains(RegExp('[",\r\n]'))
        ? '"${guarded.replaceAll('"', '""')}"'
        : guarded;
  }

  MockResult _csvFile(String what, List<List<String>> rows) {
    final text =
        '\u{feff}${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
    final day = _now().toIso8601String().substring(0, 10).replaceAll('-', '');
    return MockResult.bytes(
      200,
      Uint8List.fromList(utf8.encode(text)),
      'text/csv; charset=utf-8',
      headers: {
        'content-disposition':
            'attachment; filename="hoops-demo-$what-$day.csv"',
        'cache-control': 'no-store',
      },
    );
  }

  MockResult _exportExpenses(MockQuery q, String? language) {
    final lang = _language(language);
    final labels = _categoryLabel[lang]!;
    return _csvFile('expenses', [
      _expenseHeader[lang]!,
      for (final e in _filteredExpenses(q))
        [
          '${e['spentOn']}',
          labels[_categories.indexOf('${e['category']}')],
          '${e['category']}',
          '${e['amountMinor']}',
          '${e['currency']}',
          '${e['description']}',
        ],
    ]);
  }

  MockResult _exportDues(MockQuery q, String? language) {
    final lang = _language(language);
    final teams = {for (final t in _teamsInSeasons()) t['id']: '${t['name']}'};
    final dues = _filteredDues(q);
    return _csvFile('dues', [
      _dueHeader[lang]!,
      for (final d in dues)
        [
          '${d['period']}',
          '${d['periodStart']}',
          '${d['periodEnd']}',
          '${d['feePlanName']}',
          '${d['playerName']}',
          teams[d['teamId']] ?? '',
          '${d['amountMinor']}',
          '${d['currency']}',
          _statusLabel[lang]!['${d['status']}']!,
          d['status'] == 'PAID' ? '${(d['payment']! as Map)['paidOn']}' : '',
          d['status'] == 'PAID' ? '${(d['payment']! as Map)['method']}' : '',
        ],
    ]);
  }
}
