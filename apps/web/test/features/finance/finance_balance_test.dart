import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/chart_card.dart';
import 'package:hoops_app/features/finance/domain/money.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../support/fake_finance.dart';
import '../../support/finance_pump.dart';

/// The season balance for ADMIN: the figures and the one chart.
void main() {
  const path = '/admin/finance/balance';
  const notYet =
      'Esta parte de las finanzas todavía no está disponible en el '
      'servidor. Inténtalo más tarde.';
  const money = MoneyFormat(currency: 'EUR', minorDigits: 2, locale: 'es');

  late FakeFinanceRepository repo;
  setUp(() => repo = FakeFinanceRepository());

  Future<fin.SeasonBalance> seed(WidgetTester tester, String season) async =>
      (await tester.runAsync(() => FakeFinanceRepository().balance(season)))!;

  String textOf(WidgetTester tester, String key) => tester
      .widgetList<Text>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .join(' | ');

  testWidgets('shows the current season: figures and the chart', (
    tester,
  ) async {
    await pumpFinance(tester, repo: repo, location: path);
    final b = await seed(tester, 'season-2026');
    expect(repo.last['balance'], 'season-2026');
    expect(find.byKey(const Key('balance-season')), findsOneWidget);
    expect(
      textOf(tester, 'balance-paid'),
      contains(money.format(b.income.paidMinor)),
    );
    expect(
      textOf(tester, 'balance-open'),
      contains(money.format(b.income.openMinor)),
    );
    expect(
      textOf(tester, 'balance-waived'),
      contains(money.format(b.income.waivedMinor)),
    );
    expect(
      textOf(tester, 'balance-expenses'),
      contains(money.format(b.expenses.totalMinor)),
    );
    expect(textOf(tester, 'balance-net'), contains(money.format(b.netMinor)));
    expect(find.byType(ChartCard), findsOneWidget);
    for (final c in b.expenses.byCategory) {
      expect(find.byKey(Key('balance-bar-${c.category.name}')), findsOneWidget);
    }
  });

  testWidgets('a negative result is shown as a loss, not hidden', (
    tester,
  ) async {
    await pumpFinance(tester, repo: repo, location: path);
    final b = await seed(tester, 'season-2026');
    expect(
      b.netMinor,
      lessThan(0),
      reason: 'the demo spends more than it collects',
    );
    expect(textOf(tester, 'balance-net'), contains('-'));
  });

  testWidgets('another season is read when picked', (tester) async {
    await pumpFinance(tester, repo: repo, location: path);
    await pickDropdown(tester, 'balance-season', '2025/26');
    expect(repo.last['balance'], 'season-2025');
    expect(textOf(tester, 'balance-paid'), contains(money.format(0)));
    expect(find.text('Sin gastos en esta temporada'), findsOneWidget);
  });

  testWidgets('the chart can be read without seeing it', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFinance(tester, repo: repo, location: path);
    final b = await seed(tester, 'season-2026');
    expect(
      find.bySemanticsLabel(
        RegExp(
          'Gastos por categoría.*${RegExp.escape(money.format(b.expenses.totalMinor))}',
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('loading, an error and a service that is not ready', (
    tester,
  ) async {
    repo.hang = true;
    await pumpFinance(tester, repo: repo, location: path, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final other = FakeFinanceRepository()..notYetServed();
    await pumpFinance(tester, repo: other, location: path);
    expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
    expect(find.text(notYet), findsOneWidget);
  });

  testWidgets('a coach does not get there', (tester) async {
    await pumpFinance(
      tester,
      repo: repo,
      roles: {TenantRole.coach},
      location: path,
    );
    expect(find.byKey(const Key('balance-season')), findsNothing);
    expect(repo.calls, isNot(contains('balance')));
  });
}
