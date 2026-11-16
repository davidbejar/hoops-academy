import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/finance/data/finance_repository.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_app/features/finance/domain/expense_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

/// The demo backend's answers for expenses, the season balance, the coach's
/// and the family's reads and the CSV exports (finance.yaml 1.0.0, ADR-0056,
/// the matrix of decision 96): the same picture of the contract the widget
/// tests and the demo share.
void main() {
  const demo = mockTenantAId;
  const norte = mockTenantBId;

  FinanceRepository repoAs(List<String> roles, {String tenant = demo}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: roles, norteRoles: roles);
    return ApiFinanceRepository(
      fin.HoopsFinanceApi(dio: dio, interceptors: const []),
      tenant,
    );
  }

  Matcher problem(int status, [String? code]) => throwsA(
    isA<DioException>()
        .having((e) => e.response?.statusCode, 'status', status)
        .having(
          (e) => e.response?.data is Map
              ? (e.response!.data as Map)['code']
              : null,
          'code',
          code ?? anything,
        ),
  );

  late FinanceRepository admin;
  setUp(() => admin = repoAs(['ADMIN']));

  fin.CreateExpenseRequest create({
    fin.Date? spentOn,
    fin.ExpenseCategory? category,
    int amount = 2500,
    String description = 'Autobús',
    String? note,
  }) => fin.CreateExpenseRequest(
    (b) => b
      ..spentOn = spentOn ?? fin.Date(2026, 11, 5)
      ..category = category ?? fin.ExpenseCategory.TRAVEL
      ..amountMinor = amount
      ..description = description
      ..note = note,
  );

  group('expenses', () {
    test('the demo academy has some, newest first', () async {
      final page = await admin.expenses(const ExpenseQuery(size: 50));
      expect(page.items.length, greaterThanOrEqualTo(6));
      final days = [for (final e in page.items) e.spentOn.toString()];
      expect(days, [...days]..sort((a, b) => b.compareTo(a)));
      expect(page.items.every((e) => e.currency == 'EUR'), isTrue);
      expect(page.page.totalElements, page.items.length);
    });

    test('filters by category and by the days', () async {
      final all = (await admin.expenses(const ExpenseQuery(size: 50))).items;
      final rent = (await admin.expenses(
        const ExpenseQuery(category: fin.ExpenseCategory.COURT_RENTAL),
      )).items;
      expect(rent, isNotEmpty);
      expect(
        rent.every((e) => e.category == fin.ExpenseCategory.COURT_RENTAL),
        isTrue,
      );
      final november = (await admin.expenses(
        ExpenseQuery(from: fin.Date(2026, 11, 1), to: fin.Date(2026, 11, 30)),
      )).items;
      expect(november, isNotEmpty);
      expect(november.length, lessThan(all.length));
      expect(november.every((e) => e.spentOn.month == 11), isTrue);
    });

    test('pages of the size asked for', () async {
      final page = await admin.expenses(const ExpenseQuery(size: 2));
      expect(page.items, hasLength(2));
      expect(page.page.totalPages, greaterThan(1));
    });

    test(
      'creates one in the academy currency, and it is listed first',
      () async {
        final made = await admin.createExpense(
          create(spentOn: fin.Date(2026, 12, 1), note: 'Ida y vuelta'),
        );
        expect(made.currency, 'EUR');
        expect(made.category, fin.ExpenseCategory.TRAVEL);
        expect(made.note, 'Ida y vuelta');
        final first = (await admin.expenses(const ExpenseQuery())).items.first;
        expect(first.id, made.id);
      },
    );

    test('refuses what the contract refuses', () async {
      await expectLater(
        admin.createExpense(create(amount: 0)),
        problem(400),
        reason: 'amount',
      );
      await expectLater(
        admin.createExpense(create(description: ' ')),
        problem(400),
        reason: 'description',
      );
      await expectLater(
        admin.createExpense(create(description: 'x' * 121)),
        problem(400),
        reason: 'too long',
      );
    });

    test('without a currency the academy cannot record one', () async {
      await expectLater(
        repoAs(['ADMIN'], tenant: norte).createExpense(create()),
        problem(409, 'CURRENCY_NOT_SET'),
      );
    });

    test('corrects one, and clears the note', () async {
      final made = await admin.createExpense(create(note: 'Algo'));
      final changed = await admin.updateExpense(
        made.id,
        fin.UpdateExpenseRequest(
          (b) => b
            ..amountMinor = 3000
            ..category = fin.ExpenseCategory.OTHER
            ..clear = SetBuilder<fin.UpdateExpenseRequestClearEnum>([
              fin.UpdateExpenseRequestClearEnum.note,
            ]),
        ),
      );
      expect(changed.amountMinor, 3000);
      expect(changed.category, fin.ExpenseCategory.OTHER);
      expect(changed.note, isNull);
      expect(changed.description, 'Autobús');
    });

    test('an empty correction and an unknown id', () async {
      final made = await admin.createExpense(create());
      await expectLater(
        admin.updateExpense(made.id, fin.UpdateExpenseRequest((_) {})),
        problem(400),
      );
      await expectLater(
        admin.updateExpense(
          'nope',
          fin.UpdateExpenseRequest((b) => b.amountMinor = 100),
        ),
        problem(404),
      );
    });

    test('deletes one, once', () async {
      final made = await admin.createExpense(create());
      await admin.deleteExpense(made.id);
      await expectLater(admin.deleteExpense(made.id), problem(404));
      final ids = [
        for (final e in (await admin.expenses(
          const ExpenseQuery(size: 50),
        )).items)
          e.id,
      ];
      expect(ids, isNot(contains(made.id)));
    });

    test('only an ADMIN reads or writes them', () async {
      for (final role in ['COACH', 'ASSISTANT_COACH', 'PARENT', 'PLAYER']) {
        final repo = repoAs([role]);
        await expectLater(
          repo.expenses(const ExpenseQuery()),
          problem(403),
          reason: role,
        );
        await expectLater(repo.createExpense(create()), problem(403));
        await expectLater(repo.deleteExpense('x'), problem(403));
      }
    });
  });

  group('the season balance', () {
    test('adds the dues by state and the expenses by category', () async {
      final b = await admin.balance('season-2026');
      expect(b.currency, 'EUR');
      expect(b.from.toString(), '2026-09-01');
      expect(b.to.toString(), '2027-06-30');

      var paid = 0, open = 0, waived = 0;
      final dues = (await admin.dues(const DueQuery(size: 200))).items;
      for (final d in dues) {
        if (d.status == fin.DueStatus.PAID) paid += d.amountMinor;
        if (d.status == fin.DueStatus.OPEN) open += d.amountMinor;
        if (d.status == fin.DueStatus.WAIVED) waived += d.amountMinor;
      }
      expect(b.income.paidMinor, paid);
      expect(b.income.openMinor, open);
      expect(b.income.waivedMinor, waived);
      expect(paid, greaterThan(0));
      expect(open, greaterThan(0));
      expect(waived, greaterThan(0));

      expect(
        [for (final c in b.expenses.byCategory) c.category],
        const [
          fin.ExpenseCategory.COURT_RENTAL,
          fin.ExpenseCategory.SALARIES,
          fin.ExpenseCategory.KIT,
          fin.ExpenseCategory.TOURNAMENT_FEES,
          fin.ExpenseCategory.TRAVEL,
          fin.ExpenseCategory.OTHER,
        ],
        reason: 'all six, in the enum order, zero included',
      );
      final total = (await admin.expenses(const ExpenseQuery(size: 200))).items
          .fold<int>(0, (sum, e) => sum + e.amountMinor);
      expect(b.expenses.totalMinor, total);
      expect(
        b.expenses.byCategory.fold<int>(0, (s, c) => s + c.totalMinor),
        total,
      );
      expect(b.netMinor, paid - total);
    });

    test('counts the expenses of the season only', () async {
      await admin.createExpense(
        create(spentOn: fin.Date(2027, 7, 1), amount: 9999),
      );
      final b = await admin.balance('season-2026');
      final inSeason = (await admin.expenses(
        ExpenseQuery(from: fin.Date(2026, 9, 1), to: fin.Date(2027, 6, 30)),
      )).items.fold<int>(0, (s, e) => s + e.amountMinor);
      expect(b.expenses.totalMinor, inSeason);
    });

    test('a season without dues or expenses is all zero', () async {
      final b = await admin.balance('season-2025');
      expect(b.income.paidMinor, 0);
      expect(b.expenses.totalMinor, 0);
      expect(b.netMinor, 0);
      expect(b.expenses.byCategory, hasLength(6));
    });

    test(
      'an unknown season is 404, no season is 400, a member is 403',
      () async {
        await expectLater(admin.balance('season-x'), problem(404));
        await expectLater(admin.balance(''), problem(400));
        await expectLater(
          repoAs(['COACH']).balance('season-2026'),
          problem(403),
        );
      },
    );
  });

  group("the coach's view", () {
    test('says who of the team is up to date, by name, no amounts', () async {
      final status = await repoAs(['COACH']).teamDueStatus('team-mini-a');
      expect(status.teamId, 'team-mini-a');
      expect(status.players, hasLength(7));
      final names = [for (final p in status.players) p.playerName];
      expect(names, [...names]..sort());
      // The seed: a player with every started due paid or waived is up to
      // date, one with an open due of a started period is not.
      expect(status.players.where((p) => p.upToDate), isNotEmpty);
      expect(status.players.where((p) => !p.upToDate), isNotEmpty);
    });

    test(
      'agrees with the dues: behind exactly with an open started due',
      () async {
        final status = await admin.teamDueStatus('team-mini-a');
        final open = (await admin.dues(
          const DueQuery(status: fin.DueStatus.OPEN, size: 200),
        )).items;
        final behind = {
          for (final d in open)
            if (d.periodStart.toString().compareTo(
                  DateTime.now().toIso8601String().substring(0, 10),
                ) <=
                0)
              d.playerId,
        };
        expect({
          for (final p in status.players)
            if (!p.upToDate) p.playerId,
        }, behind);
      },
    );

    test('a team whose players owe nothing is all up to date', () async {
      final status = await admin.teamDueStatus('team-inf-a');
      expect(status.players, hasLength(1));
      expect(status.players.single.upToDate, isTrue);
    });

    test('only the current COACH of the team (and ADMIN)', () async {
      await expectLater(
        repoAs(['COACH']).teamDueStatus('team-mini-b'),
        problem(403),
        reason: 'another team',
      );
      for (final role in ['ASSISTANT_COACH', 'PARENT', 'PLAYER']) {
        await expectLater(
          repoAs([role]).teamDueStatus('team-mini-a'),
          problem(403),
          reason: role,
        );
      }
      await expectLater(admin.teamDueStatus('team-nope'), problem(404));
    });
  });

  group("the family's view", () {
    test('a parent reads the dues of a linked player, newest first', () async {
      final page = await repoAs(['PARENT']).playerDues('p-ana');
      expect(page.items, hasLength(3));
      expect(
        [for (final d in page.items) d.period],
        ['2026-11', '2026-10', '2026-09'],
      );
      final nov = page.items.first;
      expect(nov.feePlanName, 'Cuota mensual Mini A');
      expect(nov.currency, 'EUR');
      expect(
        nov.status == fin.DueStatus.PAID,
        nov.paidOn != null,
        reason: 'a payment day only when paid',
      );
      expect(nov.status == fin.DueStatus.PAID, nov.paymentMethod != null);
    });

    test(
      'shows the day and method of a paid due, none of a waived one',
      () async {
        final dues = (await admin.dues(const DueQuery(size: 200))).items;
        final waived = dues.firstWhere((d) => d.status == fin.DueStatus.WAIVED);
        final paid = dues.firstWhere((d) => d.status == fin.DueStatus.PAID);
        for (final (due, expectPaid) in [(paid, true), (waived, false)]) {
          final page = await admin.playerDues(due.playerId);
          final mine = page.items.firstWhere((d) => d.id == due.id);
          expect(mine.paidOn != null, expectPaid);
          expect(mine.paymentMethod != null, expectPaid);
          expect(mine.status, due.status);
        }
      },
    );

    test('a player reads their own', () async {
      final page = await repoAs(['PLAYER']).playerDues('p-leo');
      expect(page.items, isNotEmpty);
    });

    test('another player is 403, for a parent, a player and a coach', () async {
      await expectLater(repoAs(['PARENT']).playerDues('p-leo'), problem(403));
      await expectLater(repoAs(['PLAYER']).playerDues('p-ana'), problem(403));
      await expectLater(repoAs(['COACH']).playerDues('p-ana'), problem(403));
    });

    test('a player without dues is an empty list', () async {
      final page = await admin.playerDues('p-mia');
      expect(page.items, isEmpty);
      expect(page.page.totalElements, 0);
    });
  });

  group('the CSV exports', () {
    String text(List<int> bytes) => utf8.decode(bytes);

    test(
      'expenses: BOM, header in the language, one row per expense',
      () async {
        final bytes = await admin.exportExpenses(
          const ExpenseQuery(),
          language: 'es',
        );
        expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
        final es = text(bytes);
        final rows = const LineSplitter().convert(es);
        final count = (await admin.expenses(const ExpenseQuery(size: 200)))
            .page
            .totalElements;
        expect(rows, hasLength(count + 1));
        expect(rows.first, contains('Categoría'));
        expect(rows.skip(1).join('\n'), contains('COURT_RENTAL'));
        final en = text(
          await admin.exportExpenses(const ExpenseQuery(), language: 'en'),
        );
        expect(const LineSplitter().convert(en).first, contains('Category'));
      },
    );

    test('expenses: follows the filters', () async {
      final rows = const LineSplitter().convert(
        text(
          await admin.exportExpenses(
            const ExpenseQuery(category: fin.ExpenseCategory.KIT),
            language: 'en',
          ),
        ),
      );
      expect(rows.skip(1), everyElement(contains('KIT')));
    });

    test('dues: one row per due of the filters', () async {
      final query = const DueQuery(status: fin.DueStatus.PAID);
      final rows = const LineSplitter().convert(
        text(await admin.exportDues(query, language: 'en')),
      );
      final count = (await admin.dues(query)).page.totalElements;
      expect(rows, hasLength(count + 1));
      expect(rows.skip(1), everyElement(contains(',Paid,')));
    });

    test('only an ADMIN exports', () async {
      for (final role in ['COACH', 'ASSISTANT_COACH', 'PARENT', 'PLAYER']) {
        final repo = repoAs([role]);
        await expectLater(
          repo.exportDues(const DueQuery(), language: 'es'),
          problem(403),
        );
        await expectLater(
          repo.exportExpenses(const ExpenseQuery(), language: 'es'),
          problem(403),
        );
      }
    });
  });
}
