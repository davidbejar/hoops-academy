import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/ui/kit.dart';
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../support/fake_finance.dart';
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

  late FakeFinanceRepository repo;
  setUp(() => repo = FakeFinanceRepository());

  /// The id of the first due of [status] the seed has, found through the repo
  /// so the tests do not depend on the order of the list.
  Future<fin.Due> firstDue(
    fin.DueStatus status, {
    String period = '2026-11',
  }) async => (await FakeFinanceRepository().dues(
    DueQuery(status: status, period: period, size: 50),
  )).items.first;

  group('the list', () {
    const path = '/admin/finance/dues';

    testWidgets('shows who owes what, by period then player', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.text('21 cuotas'), findsOneWidget);
      final first = (await FakeFinanceRepository().dues(
        const DueQuery(size: 50),
      )).items.first;
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
      repo.hang = true;
      await pumpFinance(tester, repo: repo, location: path, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a filter without matches says so', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await pickDropdown(tester, 'dues-filter-team', 'Mini B');
      expect(repo.last['dues'], const DueQuery(teamId: 'team-mini-b'));
      expect(find.text('No hay cuotas con estos filtros'), findsOneWidget);
    });

    testWidgets('filters by state and by plan', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await tapKey(tester, 'dues-status-OPEN');
      expect(repo.last['dues'], const DueQuery(status: fin.DueStatus.OPEN));
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
        repo.last['dues'],
        const DueQuery(planId: 'fp-mini-a', status: fin.DueStatus.OPEN),
      );
      await tapKey(tester, 'dues-status-ALL');
      expect(repo.last['dues'], const DueQuery(planId: 'fp-mini-a'));
      expect(find.text('21 cuotas'), findsOneWidget);
    });

    testWidgets('filters by period of the chosen plan', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await pickDropdown(tester, 'dues-filter-plan', 'Cuota mensual Mini A');
      await pickDropdown(tester, 'dues-filter-period', 'octubre de 2026');
      expect(
        repo.last['dues'],
        const DueQuery(planId: 'fp-mini-a', period: '2026-10'),
      );
      expect(find.text('7 cuotas'), findsOneWidget);
    });

    testWidgets('pages', (tester) async {
      final h = await pumpFinance(tester, repo: repo, location: path);
      h.container.read(dueQueryProvider.notifier).set(const DueQuery(size: 10));
      await tester.pumpAndSettle();
      expect(find.text('Página 1 de 3'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('dues-previous')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'dues-next');
      expect(find.text('Página 2 de 3'), findsOneWidget);
      expect(repo.last['dues'], const DueQuery(size: 10, page: 1));
    });

    testWidgets('while the service does not serve dues: a clear message', (
      tester,
    ) async {
      repo.notYetServed();
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('other failures use the generic message', (tester) async {
      repo.failOn['dues'] = const AppError(kind: AppErrorKind.timeout);
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.byKey(const Key('finance-not-yet')), findsNothing);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('a due opens its detail', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      final due = (await FakeFinanceRepository().dues(const DueQuery(size: 50)))
          .items
          .first;
      await tapKey(tester, 'due-${due.id}');
      expect(find.byKey(const Key('due-detail')), findsOneWidget);
      expect(find.text(due.playerName), findsWidgets);
    });
  });

  group('generating dues', () {
    const path = '/admin/finance/dues';

    testWidgets('preview first, then create', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
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
      expect(repo.last['generateDues'], ('fp-mini-a', '2026-12', true));

      await tapKey(tester, 'form-submit');
      expect(repo.last['generateDues'], ('fp-mini-a', '2026-12', false));
      expect(find.text('Se han creado 7 cuotas'), findsOneWidget);
      expect(find.text('28 cuotas'), findsOneWidget);
    });

    testWidgets('changing the choice asks to calculate again', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
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
        repo: repo,
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
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await pumpFinance(tester, repo: other, location: path);
      await tapKey(tester, 'dues-generate');
      expect(find.text('Crea primero un plan de cuota activo'), findsOneWidget);
    });

    testWidgets('a service without dues says so instead of failing', (
      tester,
    ) async {
      repo.failOn['generateDues'] = notImplemented;
      await pumpFinance(
        tester,
        repo: repo,
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
      final h = await pumpFinance(tester, repo: repo, location: path);
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
    String detail(String id) => '/admin/finance/dues/$id';

    testWidgets('an open due: amounts, state and the three actions', (
      tester,
    ) async {
      final due = await firstDue(fin.DueStatus.OPEN);
      await pumpFinance(tester, repo: repo, location: detail(due.id));
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
      final due = await firstDue(fin.DueStatus.OPEN);
      await pumpFinance(
        tester,
        repo: repo,
        location: detail(due.id),
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

      final (id, paidOn, method, note) =
          repo.last['payDue']!
              as (String, fin.Date, fin.PaymentMethod, String?);
      expect(id, due.id);
      expect(paidOn.toString(), academyToday());
      expect(method, fin.PaymentMethod.BANK_TRANSFER);
      expect(note, 'Recibo 12');
      expect(find.text('Pago registrado'), findsOneWidget);
      expect(find.text('Pagada'), findsWidgets);
      expect(find.byKey(const Key('due-pay')), findsNothing);
      expect(find.text('Transferencia'), findsWidgets);
      expect(find.text('Registrado por Casey Coach'), findsOneWidget);
    });

    testWidgets('a due that is no longer open is explained', (tester) async {
      final due = await firstDue(fin.DueStatus.OPEN);
      repo.failOn['payDue'] = const AppError(
        kind: AppErrorKind.conflict,
        status: 409,
        code: 'DUE_NOT_OPEN',
      );
      await pumpFinance(
        tester,
        repo: repo,
        location: detail(due.id),
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'due-pay');
      await tapKey(tester, 'form-submit');
      expect(
        find.text('La cuota ya no está pendiente. Recarga la lista.'),
        findsOneWidget,
      );
    });

    testWidgets('change the amount with a reason', (tester) async {
      final due = await firstDue(fin.DueStatus.OPEN);
      await pumpFinance(
        tester,
        repo: repo,
        location: detail(due.id),
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
      expect(repo.calls, isNot(contains('changeDueAmount')));
      await enter(tester, 'reason-field', 'Medio mes');
      await tapKey(tester, 'form-submit');

      expect(repo.last['changeDueAmount'], (due.id, 2000, 'Medio mes'));
      expect(find.text('Importe cambiado'), findsOneWidget);
      expect(find.text('20,00 €'), findsWidgets);
      expect(find.text('Importe del plan: $eur45'), findsOneWidget);
      expect(find.text('Motivo: Medio mes'), findsOneWidget);
    });

    testWidgets('waive with a reason', (tester) async {
      final due = await firstDue(fin.DueStatus.OPEN);
      await pumpFinance(
        tester,
        repo: repo,
        location: detail(due.id),
        size: const Size(360, 1000),
      );
      await tapKey(tester, 'due-waive');
      expect(
        find.text('La cuota queda condonada para siempre.'),
        findsOneWidget,
      );
      await enter(tester, 'reason-field', 'Beca');
      await tapKey(tester, 'form-submit');
      expect(repo.last['waiveDue'], (due.id, 'Beca'));
      expect(find.text('Cuota condonada'), findsOneWidget);
      expect(find.text('Condonada'), findsWidgets);
      expect(find.text('Motivo: Beca'), findsOneWidget);
      expect(find.byKey(const Key('due-waive')), findsNothing);
    });

    testWidgets('void a wrong payment: kept, marked, the due is open again', (
      tester,
    ) async {
      final due = await firstDue(fin.DueStatus.PAID, period: '2026-09');
      await pumpFinance(
        tester,
        repo: repo,
        location: detail(due.id),
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

      expect(repo.last['voidPayment'], (due.payment!.id, 'Importe equivocado'));
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
      final due = await firstDue(fin.DueStatus.OPEN);
      repo.notYetServed();
      await pumpFinance(tester, repo: repo, location: detail(due.id));
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('offline the actions are off', (tester) async {
      final due = await firstDue(fin.DueStatus.OPEN);
      final h = await pumpFinance(tester, repo: repo, location: detail(due.id));
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
