import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/kit.dart';
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../support/finance_seed.dart';
import '../../support/harness.dart';
import '../../support/finance_pump.dart';
import '../../support/pump_helpers.dart';

/// The finance area for ADMIN, second half: the dues, generating them,
/// recording, voiding and waiving, and what happens while the service does not
/// answer those operations yet (501 until WP119).
void main() {
  const eur45 = '45,00 €';
  const notYet =
      'Esta parte de las finanzas todavía no está disponible en el '
      'servidor. Inténtalo más tarde.';

  late FinanceData finance;
  setUp(() => finance = FinanceData());

  /// The first due of the list the mock answered the screen with.
  fin.Due firstListed() =>
      finance.answered<fin.DuePage>(FinanceData.duesPath).items.first;

  /// Pumps the app and opens the first seeded due with [status] in [period]
  /// (its id is the mock's, known once the backend is seeded).
  Future<(Harness, fin.Due)> openDue(
    WidgetTester tester,
    fin.DueStatus status, {
    String period = '2026-11',
    Size size = const Size(360, 780),
  }) async {
    final h = await pumpFinance(tester, finance: finance, size: size);
    final due = finance.due(status, period: period);
    await h.go(tester, '/admin/finance/dues/${due.id}');
    return (h, due);
  }

  group('the list', () {
    const path = '/admin/finance/dues';

    testWidgets('shows who owes what, by period then player', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      expect(find.text('21 cuotas'), findsOneWidget);
      final first = firstListed();
      expect(find.text(first.playerName), findsWidgets);
      expect(
        find.text('Cuota mensual Mini A · septiembre de 2026'),
        findsWidgets,
      );
      expect(find.text(eur45), findsWidgets);
      for (final status in ['Pagada', 'Condonada', 'Pendiente']) {
        expect(
          find.descendant(
            of: find.byType(ListRow),
            matching: find.text(status),
          ),
          findsWidgets,
          reason: status,
        );
      }
    });

    testWidgets('loading and empty', (tester) async {
      finance.hang();
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a filter without matches says so', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      await pickDropdown(tester, 'dues-filter-team', 'Mini B');
      expect(finance.dueQuery, const DueQuery(teamId: 'team-mini-b'));
      expect(find.text('No hay cuotas con estos filtros'), findsOneWidget);
    });

    testWidgets('filters by state and by plan', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      await tapKey(tester, 'dues-status-OPEN');
      expect(finance.dueQuery, const DueQuery(status: fin.DueStatus.OPEN));
      expect(find.text('9 cuotas'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListRow),
          matching: find.text('Pagada'),
        ),
        findsNothing,
      );

      await pickDropdown(tester, 'dues-filter-plan', 'Cuota mensual Mini A');
      expect(
        finance.dueQuery,
        const DueQuery(planId: 'fp-mini-a', status: fin.DueStatus.OPEN),
      );
      await tapKey(tester, 'dues-status-ALL');
      expect(finance.dueQuery, const DueQuery(planId: 'fp-mini-a'));
      expect(find.text('21 cuotas'), findsOneWidget);
    });

    testWidgets('filters by period of the chosen plan', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      await pickDropdown(tester, 'dues-filter-plan', 'Cuota mensual Mini A');
      await pickDropdown(tester, 'dues-filter-period', 'octubre de 2026');
      expect(
        finance.dueQuery,
        const DueQuery(planId: 'fp-mini-a', period: '2026-10'),
      );
      expect(find.text('7 cuotas'), findsOneWidget);
    });

    testWidgets('pages', (tester) async {
      final h = await pumpFinance(tester, finance: finance, location: path);
      h.container.read(dueQueryProvider.notifier).set(const DueQuery(size: 10));
      await settleMock(tester);
      expect(find.text('Página 1 de 3'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('dues-previous')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'dues-next');
      expect(find.text('Página 2 de 3'), findsOneWidget);
      expect(finance.dueQuery, const DueQuery(size: 10, page: 1));
    });

    testWidgets('while the service does not serve dues: a clear message', (
      tester,
    ) async {
      finance.notYetServed();
      await pumpFinance(tester, finance: finance, location: path);
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('other failures use the generic message', (tester) async {
      finance.fail(path: FinanceData.duesPath, status: 504);
      await pumpFinance(tester, finance: finance, location: path);
      expect(find.byKey(const Key('finance-not-yet')), findsNothing);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('a due opens its detail', (tester) async {
      await pumpFinance(tester, finance: finance, location: path);
      final due = firstListed();
      await tapKey(tester, 'due-${due.id}');
      expect(find.byKey(const Key('due-detail')), findsOneWidget);
      expect(find.text(due.playerName), findsWidgets);
    });
  });

  group('generating dues', () {
    const path = '/admin/finance/dues';

    /// The plan and the body of the last generation the app asked for.
    String generatedPlan() =>
        finance.lastId(FinanceData.generatePath, method: 'POST');
    Map<String, Object?> generated() =>
        finance.backend.lastBody(FinanceData.generatePath);

    testWidgets('preview first, then create', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'dues-generate');
      expect(find.text('Generar cuotas'), findsWidgets);
      await pickDropdown(tester, 'gen-plan', 'Cuota mensual Mini A');
      await pickDropdown(tester, 'gen-period', 'diciembre de 2026');
      // nothing can be created before the count was seen
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('form-submit')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'gen-preview');
      expect(find.text('Se crearán 7 cuotas; ya existen 0.'), findsOneWidget);
      expect(generatedPlan(), 'fp-mini-a');
      expect(generated(), {'period': '2026-12', 'preview': true});

      await tapKey(tester, 'form-submit');
      expect(generatedPlan(), 'fp-mini-a');
      expect(generated(), {'period': '2026-12', 'preview': false});
      expect(find.text('Se han creado 7 cuotas'), findsOneWidget);
      expect(find.text('28 cuotas'), findsOneWidget);
    });

    testWidgets('changing the choice asks to calculate again', (tester) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'dues-generate');
      await pickDropdown(tester, 'gen-plan', 'Cuota mensual Mini A');
      await pickDropdown(tester, 'gen-period', 'diciembre de 2026');
      await tapKey(tester, 'gen-preview');
      expect(find.byKey(const Key('gen-preview-result')), findsOneWidget);
      await pickDropdown(tester, 'gen-period', 'enero de 2027');
      expect(find.byKey(const Key('gen-preview-result')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('form-submit')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a plan of an age category counts the players of its teams', (
      tester,
    ) async {
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'dues-generate');
      await pickDropdown(tester, 'gen-plan', 'Matrícula Mini');
      await tapKey(tester, 'gen-preview');
      expect(find.text('Se crearán 8 cuotas; ya existen 0.'), findsOneWidget);
    });

    testWidgets('without an active plan there is nothing to generate', (
      tester,
    ) async {
      final other = FinanceData.empty(currency: 'EUR');
      await pumpFinance(tester, finance: other, location: path);
      await tapKey(tester, 'dues-generate');
      expect(find.text('Crea primero un plan de cuota activo'), findsOneWidget);
    });

    testWidgets('a service without dues says so instead of failing', (
      tester,
    ) async {
      finance.fail(
        path: FinanceData.generatePath,
        status: 501,
        code: 'NOT_IMPLEMENTED',
      );
      await pumpFinance(
        tester,
        finance: finance,
        location: path,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'dues-generate');
      await pickDropdown(tester, 'gen-plan', 'Cuota mensual Mini A');
      await pickDropdown(tester, 'gen-period', 'diciembre de 2026');
      await tapKey(tester, 'gen-preview');
      expect(find.text(notYet), findsOneWidget);
      expect(find.byKey(const Key('gen-preview-result')), findsNothing);
    });

    testWidgets('offline it cannot be started', (tester) async {
      final h = await pumpFinance(tester, finance: finance, location: path);
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finance-offline')), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(
              find.byKey(const Key('dues-generate')),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('one due', () {
    final changeAmount = RegExp(r'^/api/finance/dues/[^/]+:change-amount$');
    final waive = RegExp(r'^/api/finance/dues/[^/]+:waive$');
    final voidPayment = RegExp(r'^/api/finance/payments/[^/]+:void$');

    testWidgets('an open due: amounts, state and the three actions', (
      tester,
    ) async {
      final (_, due) = await openDue(tester, fin.DueStatus.OPEN);
      expect(find.byKey(const Key('due-detail')), findsOneWidget);
      expect(find.text(due.playerName), findsWidgets);
      expect(find.text('Pendiente'), findsWidgets);
      expect(find.text(eur45), findsWidgets);
      expect(find.text('Todavía no hay pagos'), findsOneWidget);
      expect(find.byKey(const Key('due-pay')), findsOneWidget);
      expect(find.byKey(const Key('due-change-amount')), findsOneWidget);
      expect(find.byKey(const Key('due-waive')), findsOneWidget);
    });

    testWidgets('record a payment of the whole due', (tester) async {
      final (_, due) = await openDue(
        tester,
        fin.DueStatus.OPEN,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'due-pay');
      expect(
        find.text('Se registra el pago completo de la cuota: $eur45.'),
        findsOneWidget,
      );
      expect(find.text(academyToday()), findsOneWidget);
      await pickDropdown(tester, 'pay-method', 'Transferencia');
      await enter(tester, 'pay-note', 'Recibo 12');
      await tapKey(tester, 'form-submit');

      final pay = finance.sent<fin.PayDueRequest>(FinanceData.payPath);
      expect(finance.lastId(FinanceData.payPath, method: 'POST'), due.id);
      expect(pay.paidOn.toString(), academyToday());
      expect(pay.method, fin.PaymentMethod.BANK_TRANSFER);
      expect(pay.note, 'Recibo 12');
      expect(find.text('Pago registrado'), findsOneWidget);
      expect(find.text('Pagada'), findsWidgets);
      expect(find.byKey(const Key('due-pay')), findsNothing);
      expect(find.textContaining('Transferencia'), findsWidgets);
      expect(find.text('Registrado por Casey Coach'), findsOneWidget);
    });

    testWidgets('a due that is no longer open is explained', (tester) async {
      finance.fail(
        path: FinanceData.payPath,
        status: 409,
        code: 'DUE_NOT_OPEN',
      );
      await openDue(tester, fin.DueStatus.OPEN, size: const Size(360, 1000));
      await tapKey(tester, 'due-pay');
      await tapKey(tester, 'form-submit');
      expect(
        find.text('La cuota ya no está pendiente. Recarga la lista.'),
        findsOneWidget,
      );
    });

    testWidgets('recording a payment while the service cannot says so', (
      tester,
    ) async {
      finance.fail(
        path: FinanceData.payPath,
        status: 501,
        code: 'NOT_IMPLEMENTED',
      );
      await openDue(tester, fin.DueStatus.OPEN, size: const Size(360, 1000));
      await tapKey(tester, 'due-pay');
      await tapKey(tester, 'form-submit');
      expect(find.text(notYet), findsOneWidget);
      expect(find.byKey(const Key('form-submit')), findsOneWidget);
    });

    testWidgets('change the amount with a reason', (tester) async {
      final (_, due) = await openDue(
        tester,
        fin.DueStatus.OPEN,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'due-change-amount');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('amount-field')))
            .controller!
            .text,
        '45,00',
      );
      await enter(tester, 'amount-field', '20');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      expect(finance.requests(changeAmount, method: 'POST'), isEmpty);
      await enter(tester, 'reason-field', 'Medio mes');
      await tapKey(tester, 'form-submit');

      expect(finance.lastId(changeAmount, method: 'POST'), due.id);
      expect(finance.backend.lastBody(changeAmount), {
        'amountMinor': 2000,
        'reason': 'Medio mes',
      });
      expect(find.text('Importe cambiado'), findsOneWidget);
      expect(find.text('20,00 €'), findsWidgets);
      expect(find.text('Importe del plan: $eur45'), findsOneWidget);
      expect(find.text('Motivo: Medio mes'), findsOneWidget);
    });

    testWidgets('waive with a reason', (tester) async {
      final (_, due) = await openDue(
        tester,
        fin.DueStatus.OPEN,
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'due-waive');
      expect(
        find.text('La cuota queda condonada para siempre.'),
        findsOneWidget,
      );
      await enter(tester, 'reason-field', 'Beca');
      await tapKey(tester, 'form-submit');
      expect(finance.lastId(waive, method: 'POST'), due.id);
      expect(finance.backend.lastBody(waive), {'reason': 'Beca'});
      expect(find.text('Cuota condonada'), findsOneWidget);
      expect(find.text('Condonada'), findsWidgets);
      expect(find.text('Motivo: Beca'), findsOneWidget);
      expect(find.byKey(const Key('due-waive')), findsNothing);
    });

    testWidgets('void a wrong payment: kept, marked, the due is open again', (
      tester,
    ) async {
      final (_, due) = await openDue(
        tester,
        fin.DueStatus.PAID,
        period: '2026-09',
        size: const Size(360, 1000),
      );
      expect(find.text('Pagada'), findsWidgets);
      expect(find.byKey(const Key('due-pay')), findsNothing);
      await tapKey(tester, 'payment-void-${due.payment!.id}');
      expect(
        find.text(
          'El pago se conserva marcado como anulado y la cuota vuelve a '
          'estar pendiente.',
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await enter(tester, 'reason-field', 'Importe equivocado');
      await tapKey(tester, 'form-submit');

      expect(finance.lastId(voidPayment, method: 'POST'), due.payment!.id);
      expect(finance.backend.lastBody(voidPayment), {
        'reason': 'Importe equivocado',
      });
      expect(find.text('Pago anulado'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);
      expect(find.text('Anulado'), findsOneWidget);
      expect(find.text('Motivo: Importe equivocado'), findsOneWidget);
      expect(find.byKey(const Key('due-pay')), findsOneWidget);
      expect(find.byKey(Key('payment-void-${due.payment!.id}')), findsNothing);
    });

    testWidgets('while the service does not serve it: a clear message', (
      tester,
    ) async {
      finance.notYetServed();
      await openDue(tester, fin.DueStatus.OPEN);
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('offline the actions are off', (tester) async {
      final (h, _) = await openDue(tester, fin.DueStatus.OPEN);
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finance-offline')), findsOneWidget);
      for (final key in ['due-pay', 'due-change-amount', 'due-waive']) {
        final button = find.byKey(Key(key));
        expect(
          tester.widget<ButtonStyleButton>(button).onPressed,
          isNull,
          reason: key,
        );
      }
    });
  });
}
