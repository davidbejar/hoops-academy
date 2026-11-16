import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/l10n/locale_controller.dart';
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/finance/data/mock_finance_api.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../support/fake_finance.dart';

/// The state the finance screens read and the commands they run, over the
/// demo mock's seed.
void main() {
  late FakeFinanceRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeFinanceRepository();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...repo.overrides,
        effectiveLocaleProvider.overrideWithValue(const Locale('es')),
      ],
    );
    addTearDown(container.dispose);
  });

  fin.Date today() {
    final d = DateTime.now();
    return fin.Date(d.year, d.month, d.day);
  }

  group('settings and money', () {
    test('settings load and the money format follows them', () async {
      expect(container.read(moneyFormatProvider), isNull);
      final settings = await container.read(financeSettingsProvider.future);
      expect(settings.currency, 'EUR');
      final money = container.read(moneyFormatProvider)!;
      expect(money.currency, 'EUR');
      expect(money.minorDigits, 2);
      expect(money.locale, 'es');
      expect(money.format(4500), '45,00 €');
    });

    test(
      'an academy without a currency has no format until it chooses',
      () async {
        final other = FakeFinanceRepository(tenant: mockTenantBId);
        final c = ProviderContainer(
          overrides: [
            ...other.overrides,
            effectiveLocaleProvider.overrideWithValue(const Locale('id')),
          ],
        );
        addTearDown(c.dispose);
        final settings = await c.read(financeSettingsProvider.future);
        expect(settings.currency, isNull);
        expect(settings.currencyLocked, isFalse);
        expect(c.read(moneyFormatProvider), isNull);

        await c.read(financeSettingsProvider.notifier).chooseCurrency('IDR');
        expect(other.last['chooseCurrency'], 'IDR');
        final money = c.read(moneyFormatProvider)!;
        expect(money.minorDigits, 2);
        expect(money.format(15000000), 'Rp150.000');
      },
    );

    test('a refused currency leaves the state as it was', () async {
      await container.read(financeSettingsProvider.future);
      await expectLater(
        container.read(financeSettingsProvider.notifier).chooseCurrency('USD'),
        throwsA(anything),
      );
      expect(
        container.read(financeSettingsProvider).requireValue.currency,
        'EUR',
      );
    });

    test('the format reads the money in the language of the user', () async {
      final c = ProviderContainer(
        overrides: [
          ...repo.overrides,
          effectiveLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(c.dispose);
      await c.read(financeSettingsProvider.future);
      expect(c.read(moneyFormatProvider)!.format(4500), '€45.00');
    });
  });

  group('fee plans', () {
    test('lists the active plans, and the archived on request', () async {
      final active = await container.read(feePlansProvider.future);
      expect(active, hasLength(2));
      container.read(showArchivedPlansProvider.notifier).set(true);
      final all = await container.read(feePlansProvider.future);
      expect(all, hasLength(3));
      expect(repo.last['feePlans'], true);
    });

    test('create adds the plan to the list', () async {
      await container.read(feePlansProvider.future);
      final plan = await container
          .read(feePlansProvider.notifier)
          .create(
            fin.CreateFeePlanRequest(
              (b) => b
                ..name = 'Cuota Mini B'
                ..seasonId = 'season-2026'
                ..teamId = 'team-mini-b'
                ..amountMinor = 3500
                ..cadence = fin.FeeCadence.MONTHLY
                ..firstPeriod = '2026-10',
            ),
          );
      expect(plan.name, 'Cuota Mini B');
      final names = [
        for (final p in container.read(feePlansProvider).requireValue) p.name,
      ];
      expect(names, contains('Cuota Mini B'));
    });

    test('update, archive and delete reload the list', () async {
      await container.read(feePlansProvider.future);
      final notifier = container.read(feePlansProvider.notifier);
      await notifier.update(
        MockFinanceApi.seasonPlanId,
        fin.UpdateFeePlanRequest((b) => b..amountMinor = 13000),
      );
      expect(
        container
            .read(feePlansProvider)
            .requireValue
            .firstWhere((p) => p.id == MockFinanceApi.seasonPlanId)
            .amountMinor,
        13000,
      );
      await notifier.setArchived(MockFinanceApi.seasonPlanId, true);
      expect(
        container.read(feePlansProvider).requireValue.map((p) => p.id),
        isNot(contains(MockFinanceApi.seasonPlanId)),
      );
      await notifier.setArchived(MockFinanceApi.seasonPlanId, false);
      await notifier.delete(MockFinanceApi.seasonPlanId);
      expect(
        container.read(feePlansProvider).requireValue.map((p) => p.id),
        isNot(contains(MockFinanceApi.seasonPlanId)),
      );
    });
  });

  group('dues', () {
    test('the query decides the page that is read', () async {
      var page = await container.read(duesProvider.future);
      expect(page.items, hasLength(DueQuery.defaultSize));
      expect(page.page.totalElements, 21);

      container
          .read(dueQueryProvider.notifier)
          .set(const DueQuery(status: fin.DueStatus.OPEN));
      page = await container.read(duesProvider.future);
      expect(page.items.every((d) => d.status == fin.DueStatus.OPEN), isTrue);
      expect(repo.last['dues'], const DueQuery(status: fin.DueStatus.OPEN));
    });

    test('a filter goes back to the first page', () async {
      final notifier = container.read(dueQueryProvider.notifier);
      notifier.set(const DueQuery(page: 1));
      notifier.filter(period: '2026-10');
      expect(container.read(dueQueryProvider).page, 0);
      expect(container.read(dueQueryProvider).period, '2026-10');
      notifier.filter(period: null);
      expect(container.read(dueQueryProvider).period, isNull);
    });

    test('paying reloads the dues and the due', () async {
      container
          .read(dueQueryProvider.notifier)
          .set(const DueQuery(status: fin.DueStatus.OPEN));
      final open = (await container.read(duesProvider.future)).items.first;
      final before = (await container.read(duesProvider.future))
          .page
          .totalElements;
      await container
          .read(duesProvider.notifier)
          .pay(
            open.id,
            paidOn: today(),
            method: fin.PaymentMethod.CASH,
            note: 'Mano',
          );
      final after = (await container.read(duesProvider.future))
          .page
          .totalElements;
      expect(after, before - 1);
      expect(repo.last['payDue'], isNotNull);
    });

    test('waive, change the amount and void', () async {
      container
          .read(dueQueryProvider.notifier)
          .set(const DueQuery(status: fin.DueStatus.OPEN, size: 50));
      final dues = (await container.read(duesProvider.future)).items;
      final notifier = container.read(duesProvider.notifier);

      await notifier.waive(dues[0].id, 'Beca');
      await notifier.changeAmount(
        dues[1].id,
        amountMinor: 2000,
        reason: 'Medio mes',
      );
      final detail = await container.read(dueDetailProvider(dues[1].id).future);
      expect(detail.amountMinor, 2000);
      expect(detail.status, fin.DueStatus.OPEN);

      final paid = await notifier.pay(
        dues[2].id,
        paidOn: today(),
        method: fin.PaymentMethod.CARD,
      );
      await notifier.voidPayment(paid.payment!.id, 'Error');
      final reopened = await container.read(
        dueDetailProvider(dues[2].id).future,
      );
      expect(reopened.status, fin.DueStatus.OPEN);
      expect(reopened.payments.single.voided, isTrue);
    });

    test(
      'generating previews without changing anything, then creates',
      () async {
        final notifier = container.read(duesProvider.notifier);
        final preview = await notifier.previewGeneration(
          MockFinanceApi.monthlyPlanId,
          '2026-12',
        );
        expect(preview.preview, isTrue);
        expect(preview.created, 7);
        final made = await notifier.generate(
          MockFinanceApi.monthlyPlanId,
          '2026-12',
        );
        expect(made.created, 7);
        expect(
          (await container.read(duesProvider.future)).page.totalElements,
          28,
        );
      },
    );

    test(
      'the first generated due locks the currency in the settings',
      () async {
        // The seed has dues already; what matters is that settings are read again.
        await container.read(financeSettingsProvider.future);
        final reads = repo.calls.where((c) => c == 'settings').length;
        await container
            .read(duesProvider.notifier)
            .generate(MockFinanceApi.seasonPlanId, 'SEASON');
        await container.read(financeSettingsProvider.future);
        expect(repo.calls.where((c) => c == 'settings').length, reads + 1);
        final plans = await container.read(feePlansProvider.future);
        expect(
          plans.firstWhere((p) => p.id == MockFinanceApi.seasonPlanId).hasDues,
          isTrue,
        );
      },
    );

    test('a service that does not serve dues yet is a 501 AppError', () async {
      repo.notYetServed();
      await expectLater(
        container.read(duesProvider.future),
        throwsA(isA<AppError>().having((e) => e.status, 'status', 501)),
      );
      expect(isNotYetServed(container.read(duesProvider).error!), isTrue);
      expect(
        isNotYetServed(const AppError(kind: AppErrorKind.timeout)),
        isFalse,
      );
      // settings and plans still work
      expect((await container.read(feePlansProvider.future)), isNotEmpty);
    });
  });
}
