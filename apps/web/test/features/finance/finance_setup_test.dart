import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../support/fake_finance.dart';
import '../../support/finance_pump.dart';
import '../../support/pump_helpers.dart';

/// The finance area for ADMIN, first half: how to reach it, the currency and
/// the fee plans. Data comes from the demo mock's seed (EUR, a monthly plan of
/// Mini A with dues, a season plan of the Mini category, an archived plan).
void main() {
  const eur45 = '45,00 €';
  const eur120 = '120,00 €';

  late FakeFinanceRepository repo;
  setUp(() => repo = FakeFinanceRepository());

  group('reaching it', () {
    testWidgets('the admin hub has a Finance entry that opens the area', (
      tester,
    ) async {
      await pumpFinance(tester, repo: repo, location: '/admin');
      expect(find.byKey(const Key('admin-finance')), findsOneWidget);
      await tapKey(tester, 'admin-finance');
      expect(find.byKey(const Key('finance-hub')), findsOneWidget);
    });

    testWidgets('the hub shows the currency and links to plans and dues', (
      tester,
    ) async {
      await pumpFinance(tester, repo: repo, location: '/admin/finance');
      expect(find.text('Finanzas'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('finance-settings')),
          matching: find.text('EUR'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('finance-plans')), findsOneWidget);
      expect(find.byKey(const Key('finance-dues')), findsOneWidget);
      await tapKey(tester, 'finance-plans');
      expect(find.byKey(const Key('plan-new')), findsOneWidget);
    });

    testWidgets('a coach does not get there', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        roles: {TenantRole.coach},
        location: '/admin/finance',
      );
      expect(find.byKey(const Key('finance-hub')), findsNothing);
      expect(repo.calls, isEmpty);
    });

    testWidgets('loading and error states of the hub', (tester) async {
      repo.hang = true;
      await pumpFinance(
        tester,
        repo: repo,
        location: '/admin/finance',
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a failing server shows the message and retry', (tester) async {
      repo.failWith = const AppError(kind: AppErrorKind.server);
      await pumpFinance(tester, repo: repo, location: '/admin/finance');
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });
  });

  group('currency', () {
    testWidgets('fixed once dues exist, with the reason', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: '/admin/finance/settings',
      );
      expect(find.text('EUR'), findsWidgets);
      expect(find.byKey(const Key('currency-locked')), findsOneWidget);
      expect(
        find.text('La moneda ya no se puede cambiar: hay cuotas generadas.'),
        findsOneWidget,
      );
      final choose = tester.widget<FilledButton>(
        find.byKey(const Key('currency-choose')),
      );
      expect(choose.onPressed, isNull);
    });

    testWidgets('an academy without one chooses it, then it shows', (
      tester,
    ) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await pumpFinance(
        tester,
        repo: other,
        roles: {TenantRole.admin},
        location: '/admin/finance/settings',
      );
      expect(find.text('Sin elegir'), findsOneWidget);
      expect(find.byKey(const Key('currency-locked')), findsNothing);

      await tapKey(tester, 'currency-choose');
      await enter(tester, 'currency-search', 'idr');
      expect(find.byKey(const Key('currency-IDR')), findsOneWidget);
      expect(find.byKey(const Key('currency-EUR')), findsNothing);
      await tester.tap(find.byKey(const Key('currency-IDR')));
      await tester.pumpAndSettle();
      expect(find.textContaining('IDR como moneda'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();

      expect(other.last['chooseCurrency'], 'IDR');
      expect(find.text('Moneda guardada'), findsOneWidget);
      expect(find.text('Sin elegir'), findsNothing);
    });

    testWidgets('a search without a match says so', (tester) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await pumpFinance(
        tester,
        repo: other,
        location: '/admin/finance/settings',
      );
      await tapKey(tester, 'currency-choose');
      await enter(tester, 'currency-search', 'zzz');
      expect(find.text('Sin resultados'), findsOneWidget);
    });
  });

  group('fee plans', () {
    const path = '/admin/finance/plans';

    testWidgets('lists the active plans with target, cadence and amount', (
      tester,
    ) async {
      await pumpFinance(tester, repo: repo, location: path);
      expect(find.byKey(const Key('plan-fp-mini-a')), findsOneWidget);
      expect(find.text('Cuota mensual Mini A'), findsOneWidget);
      expect(find.text('Equipo Mini A · 2026/27'), findsOneWidget);
      expect(find.text('Mensual'), findsOneWidget);
      expect(find.text(eur45), findsOneWidget);
      expect(find.text('Categoría Mini · 2026/27'), findsOneWidget);
      expect(find.text('Una vez por temporada'), findsOneWidget);
      expect(find.text(eur120), findsOneWidget);
      expect(find.text('Con cuotas'), findsOneWidget);
      expect(find.byKey(const Key('plan-fp-premini-2025')), findsNothing);
    });

    testWidgets('archived plans only when asked for', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await tapKey(tester, 'plans-show-archived');
      expect(find.byKey(const Key('plan-fp-premini-2025')), findsOneWidget);
      expect(find.text('Archivado'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await tester.runAsync(() => other.chooseCurrency('EUR'));
      await pumpFinance(tester, repo: other, location: path);
      expect(find.text('Aún no hay planes de cuota'), findsOneWidget);
      expect(find.byKey(const Key('plan-new')), findsOneWidget);
    });

    testWidgets('without a currency it asks to choose one first', (
      tester,
    ) async {
      final other = FakeFinanceRepository(tenant: mockTenantBId);
      await pumpFinance(tester, repo: other, location: path);
      expect(find.byKey(const Key('finance-no-currency')), findsOneWidget);
      expect(find.byKey(const Key('plan-new')), findsNothing);
      await tapKey(tester, 'finance-no-currency-action');
      expect(find.byKey(const Key('currency-choose')), findsOneWidget);
    });

    testWidgets('create a plan for a team', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'plan-new');
      await enter(tester, 'plan-name', 'Cuota Mini B');
      await pickDropdown(tester, 'plan-team', 'Mini B');
      await pickDropdown(tester, 'plan-first', 'octubre de 2026');
      await enter(tester, 'plan-amount', '35');
      await tapKey(tester, 'form-submit');

      final request = repo.last['createFeePlan']! as fin.CreateFeePlanRequest;
      expect(request.name, 'Cuota Mini B');
      expect(request.seasonId, 'season-2026');
      expect(request.teamId, 'team-mini-b');
      expect(request.ageCategoryId, isNull);
      expect(request.cadence, fin.FeeCadence.MONTHLY);
      expect(request.firstPeriod, '2026-10');
      expect(request.lastPeriod, isNull);
      expect(request.amountMinor, 3500);
      expect(find.text('Plan guardado'), findsOneWidget);
      expect(find.text('Cuota Mini B'), findsOneWidget);
    });

    testWidgets('create a season plan for an age category', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'plan-new');
      await enter(tester, 'plan-name', 'Matrícula Infantil');
      await pickDropdown(tester, 'plan-target-kind', 'Una categoría de edad');
      await pickDropdown(tester, 'plan-category', 'Infantil');
      await pickDropdown(tester, 'plan-cadence', 'Una vez por temporada');
      expect(find.byKey(const Key('plan-first')), findsNothing);
      await enter(tester, 'plan-amount', '150,50');
      await tapKey(tester, 'form-submit');

      final request = repo.last['createFeePlan']! as fin.CreateFeePlanRequest;
      expect(request.teamId, isNull);
      expect(request.ageCategoryId, 'cat-u14');
      expect(request.cadence, fin.FeeCadence.SEASON);
      expect(request.firstPeriod, isNull);
      expect(request.amountMinor, 15050);
    });

    testWidgets('the form says what is missing or wrong', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'plan-new');
      await enter(tester, 'plan-amount', '0');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsWidgets);
      expect(
        find.text('Introduce un importe mayor que cero, por ejemplo 45,00'),
        findsOneWidget,
      );
      expect(repo.calls, isNot(contains('createFeePlan')));
    });

    testWidgets('a refusal of the server is worded, not shown raw', (
      tester,
    ) async {
      repo.failOn['createFeePlan'] = const AppError(
        kind: AppErrorKind.conflict,
        code: 'CURRENCY_NOT_SET',
        status: 409,
      );
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'plan-new');
      await enter(tester, 'plan-name', 'X');
      await pickDropdown(tester, 'plan-team', 'Mini B');
      await pickDropdown(tester, 'plan-first', 'octubre de 2026');
      await enter(tester, 'plan-amount', '10');
      await tapKey(tester, 'form-submit');
      expect(
        find.text('Elige primero la moneda de la academia'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('form-submit')), findsOneWidget);
    });

    testWidgets('edit: name and amount, the rest is fixed', (tester) async {
      await pumpFinance(
        tester,
        repo: repo,
        location: path,
        size: const Size(360, 1100),
      );
      await tapKey(tester, 'plan-fp-mini-a');
      expect(find.text('Editar plan'), findsOneWidget);
      expect(find.byKey(const Key('plan-season')), findsNothing);
      expect(
        find.text(
          'La temporada, a quién se cobra y la frecuencia no se pueden '
          'cambiar: crea otro plan.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'El primer periodo ya no se puede cambiar: el plan tiene cuotas.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('plan-amount')))
            .controller!
            .text,
        '45,00',
      );
      await enter(tester, 'plan-amount', '50');
      await tapKey(tester, 'form-submit');

      final request = repo.last['updateFeePlan']! as fin.UpdateFeePlanRequest;
      expect(request.amountMinor, 5000);
      expect(request.name, isNull, reason: 'only what changed is sent');
      expect(request.firstPeriod, isNull);
      expect(find.text('Plan guardado'), findsOneWidget);
      expect(find.text('50,00 €'), findsOneWidget);
    });

    testWidgets('archive and bring back', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await tapKey(tester, 'plan-menu-fp-u12-season');
      await tester.tap(find.byKey(const Key('sheet-action-archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(repo.last['setFeePlanArchived'], true);
      expect(find.text('Plan archivado'), findsOneWidget);
      expect(find.byKey(const Key('plan-fp-u12-season')), findsNothing);

      await tester.pump(const Duration(seconds: 5)); // the first snack bar goes
      await tapKey(tester, 'plans-show-archived');
      await tapKey(tester, 'plan-menu-fp-u12-season');
      await tester.tap(find.byKey(const Key('sheet-action-unarchive')));
      await tester.pumpAndSettle();
      expect(repo.last['setFeePlanArchived'], false);
      expect(find.text('Plan reactivado'), findsOneWidget);
    });

    testWidgets('delete only a plan without dues', (tester) async {
      await pumpFinance(tester, repo: repo, location: path);
      await tapKey(tester, 'plan-menu-fp-mini-a');
      expect(find.byKey(const Key('sheet-action-delete')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape); // dismiss the sheet
      await tester.pumpAndSettle();

      await tapKey(tester, 'plan-menu-fp-u12-season');
      await tester.tap(find.byKey(const Key('sheet-action-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('deleteFeePlan'));
      expect(find.text('Plan eliminado'), findsOneWidget);
      expect(find.byKey(const Key('plan-fp-u12-season')), findsNothing);
    });

    testWidgets('offline it can be read but not changed', (tester) async {
      final h = await pumpFinance(tester, repo: repo, location: path);
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finance-offline')), findsOneWidget);
      expect(
        find.text(
          'Sin conexión: puedes consultar las finanzas, pero no cambiarlas.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FloatingActionButton>(find.byKey(const Key('plan-new')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('plan-fp-mini-a')), findsOneWidget);
    });
  });
}
