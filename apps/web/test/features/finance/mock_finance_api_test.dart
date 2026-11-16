import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/features/finance/data/finance_repository.dart';
import 'package:hoops_app/features/finance/data/mock_finance_api.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

/// The demo backend's finance-service: the generated client and the real
/// repository against [MockFinanceApi], so the demo and the widget tests share
/// one picture of the contract (finance.yaml 1.0.0, ADR-0056).
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
          (e) => (e.response?.data as Map?)?['code'],
          'code',
          code ?? anything,
        ),
  );

  /// Today in the demo academy's zone, as the mock reads it.
  fin.Date today() {
    final d = TenantZone.of('Europe/Madrid').today(DateTime.now());
    return fin.Date(d.year, d.month, d.day);
  }

  fin.Date daysFromToday(int days) {
    final d = today().toDateTime().add(Duration(days: days));
    return fin.Date(d.year, d.month, d.day);
  }

  late FinanceRepository admin;
  setUp(() => admin = repoAs(['ADMIN']));

  group('settings', () {
    test(
      'the demo academy has a currency, locked because it has dues',
      () async {
        final s = await admin.settings();
        expect(s.currency, 'EUR');
        expect(s.minorDigits, 2);
        expect(s.currencyLocked, isTrue);
      },
    );

    test('another academy has none yet and may choose one', () async {
      final repo = repoAs(['ADMIN'], tenant: norte);
      final before = await repo.settings();
      expect(before.currency, isNull);
      expect(before.minorDigits, isNull);
      expect(before.currencyLocked, isFalse);
      final after = await repo.chooseCurrency('IDR');
      expect(after.currency, 'IDR');
      expect(after.minorDigits, 2);
      expect(after.currencyLocked, isFalse);
      expect((await repo.settings()).currency, 'IDR');
    });

    test('an unknown code is refused', () async {
      final repo = repoAs(['ADMIN'], tenant: norte);
      await expectLater(
        repo.chooseCurrency('XXX'),
        problem(422, 'UNKNOWN_CURRENCY'),
      );
    });

    test('with dues the currency is fixed, the same one is accepted', () async {
      await expectLater(
        admin.chooseCurrency('USD'),
        problem(409, 'CURRENCY_LOCKED'),
      );
      expect((await admin.chooseCurrency('EUR')).currency, 'EUR');
    });

    test('only an ADMIN reads or changes them', () async {
      for (final role in ['COACH', 'ASSISTANT_COACH', 'PARENT', 'PLAYER']) {
        final repo = repoAs([role]);
        await expectLater(repo.settings(), problem(403), reason: role);
        await expectLater(repo.chooseCurrency('EUR'), problem(403));
      }
    });
  });

  group('fee plans', () {
    test('the active plans of the demo, by name', () async {
      final page = await admin.feePlans();
      final names = [for (final p in page.items) p.name];
      expect(names, hasLength(2));
      expect(names, [...names]..sort());
      expect(page.items.every((p) => !p.archived), isTrue);
      final monthly = page.items.firstWhere(
        (p) => p.id == MockFinanceApi.monthlyPlanId,
      );
      expect(monthly.cadence, fin.FeeCadence.MONTHLY);
      expect(monthly.teamId, 'team-mini-a');
      expect(monthly.currency, 'EUR');
      expect(monthly.hasDues, isTrue);
      expect(monthly.firstPeriod, '2026-09');
    });

    test('archived plans only on request', () async {
      final page = await admin.feePlans(includeArchived: true);
      expect(page.items, hasLength(3));
      expect(
        page.items.where((p) => p.archived).single.id,
        MockFinanceApi.archivedPlanId,
      );
    });

    fin.CreateFeePlanRequest request({
      String name = 'Cuota Mini B',
      String? teamId = 'team-mini-b',
      String? categoryId,
      fin.FeeCadence cadence = fin.FeeCadence.MONTHLY,
      String? first = '2026-10',
      String? last,
    }) => fin.CreateFeePlanRequest(
      (b) => b
        ..name = name
        ..seasonId = 'season-2026'
        ..teamId = teamId
        ..ageCategoryId = categoryId
        ..amountMinor = 3500
        ..cadence = cadence
        ..firstPeriod = first
        ..lastPeriod = last,
    );

    test('create gives the plan the academy currency and no dues', () async {
      final plan = await admin.createFeePlan(request());
      expect(plan.currency, 'EUR');
      expect(plan.hasDues, isFalse);
      expect(plan.archived, isFalse);
      expect(plan.autoGenerate, isTrue);
      expect(plan.amountMinor, 3500);
      final names = [for (final p in (await admin.feePlans()).items) p.name];
      expect(names, contains('Cuota Mini B'));
    });

    test('a plan needs the currency first', () async {
      final repo = repoAs(['ADMIN'], tenant: norte);
      await expectLater(
        repo.createFeePlan(request(teamId: 'team-norte-a')),
        problem(409, 'CURRENCY_NOT_SET'),
      );
    });

    test('exactly one target, and the periods of its cadence', () async {
      await expectLater(
        admin.createFeePlan(request(categoryId: 'cat-u12')),
        problem(400, 'ONE_TARGET_REQUIRED'),
      );
      await expectLater(
        admin.createFeePlan(request(teamId: null)),
        problem(400, 'ONE_TARGET_REQUIRED'),
      );
      await expectLater(
        admin.createFeePlan(request(first: null)),
        problem(400),
      );
      await expectLater(
        admin.createFeePlan(request(first: '2026-Q4')),
        problem(400),
      );
      await expectLater(
        admin.createFeePlan(
          request(cadence: fin.FeeCadence.SEASON, first: '2026-10'),
        ),
        problem(400, 'NOT_ALLOWED'),
      );
      await expectLater(
        admin.createFeePlan(request(first: '2026-10', last: '2026-09')),
        problem(400),
      );
    });

    test('a team of another season is refused', () async {
      await expectLater(
        admin.createFeePlan(request(teamId: 'team-mini-a-2025')),
        problem(422, 'TEAM_NOT_IN_SEASON'),
      );
      await expectLater(
        admin.createFeePlan(request(teamId: 'nope')),
        problem(422, 'UNKNOWN_TEAM'),
      );
    });

    test('update changes the name and amount, never the first period of a plan with dues', () async {
      final updated = await admin.updateFeePlan(
        MockFinanceApi.monthlyPlanId,
        fin.UpdateFeePlanRequest(
          (b) => b
            ..name = 'Cuota nueva'
            ..amountMinor = 5000,
        ),
      );
      expect(updated.name, 'Cuota nueva');
      expect(updated.amountMinor, 5000);
      // Dues made before keep their amount.
      final dues = await admin.dues(
        const DueQuery(planId: MockFinanceApi.monthlyPlanId),
      );
      expect(dues.items.every((d) => d.planAmountMinor == 4500), isTrue);
      await expectLater(
        admin.updateFeePlan(
          MockFinanceApi.monthlyPlanId,
          fin.UpdateFeePlanRequest((b) => b..firstPeriod = '2026-10'),
        ),
        problem(409, 'FEE_PLAN_HAS_DUES'),
      );
    });

    test('the last period can be set and cleared', () async {
      final plan = await admin.createFeePlan(request());
      final set = await admin.updateFeePlan(
        plan.id,
        fin.UpdateFeePlanRequest((b) => b..lastPeriod = '2026-12'),
      );
      expect(set.lastPeriod, '2026-12');
      final cleared = await admin.updateFeePlan(
        plan.id,
        fin.UpdateFeePlanRequest(
          (b) => b
            ..clear = SetBuilder<fin.UpdateFeePlanRequestClearEnum>([
              fin.UpdateFeePlanRequestClearEnum.lastPeriod,
            ]),
        ),
      );
      expect(cleared.lastPeriod, isNull);
    });

    test('archive stops generation and unarchive brings it back', () async {
      final archived = await admin.setFeePlanArchived(
        MockFinanceApi.monthlyPlanId,
        archived: true,
      );
      expect(archived.archived, isTrue);
      await expectLater(
        admin.generateDues(
          MockFinanceApi.monthlyPlanId,
          period: '2026-12',
          preview: true,
        ),
        problem(409, 'FEE_PLAN_ARCHIVED'),
      );
      final again = await admin.setFeePlanArchived(
        MockFinanceApi.monthlyPlanId,
        archived: false,
      );
      expect(again.archived, isFalse);
    });

    test('only a plan without dues is deleted', () async {
      await expectLater(
        admin.deleteFeePlan(MockFinanceApi.monthlyPlanId),
        problem(409, 'FEE_PLAN_HAS_DUES'),
      );
      final plan = await admin.createFeePlan(request());
      await admin.deleteFeePlan(plan.id);
      final ids = [for (final p in (await admin.feePlans()).items) p.id];
      expect(ids, isNot(contains(plan.id)));
    });
  });

  group('dues', () {
    test(
      'lists the seeded dues by period then player, with their page',
      () async {
        final page = await admin.dues(
          const DueQuery(planId: MockFinanceApi.monthlyPlanId, size: 50),
        );
        expect(page.page.totalElements, 21);
        final periods = [for (final d in page.items) d.period];
        expect(periods, [...periods]..sort());
        expect(periods.toSet(), {'2026-09', '2026-10', '2026-11'});
        expect(page.items.every((d) => d.currency == 'EUR'), isTrue);
      },
    );

    test('pages and filters', () async {
      final first = await admin.dues(
        const DueQuery(planId: MockFinanceApi.monthlyPlanId, size: 10),
      );
      expect(first.items, hasLength(10));
      expect(first.page.totalPages, 3);
      final rest = await admin.dues(
        const DueQuery(planId: MockFinanceApi.monthlyPlanId, size: 10, page: 2),
      );
      expect(rest.items, hasLength(1));

      final open = await admin.dues(
        const DueQuery(status: fin.DueStatus.OPEN, size: 50),
      );
      expect(open.items.every((d) => d.status == fin.DueStatus.OPEN), isTrue);
      final october = await admin.dues(
        const DueQuery(period: '2026-10', size: 50),
      );
      expect(october.items.map((d) => d.period).toSet(), {'2026-10'});
      final team = await admin.dues(
        const DueQuery(teamId: 'team-mini-b', size: 50),
      );
      expect(team.items, isEmpty);
    });

    test('a due carries who owes it, the plan and its payment', () async {
      final page = await admin.dues(
        const DueQuery(
          planId: MockFinanceApi.monthlyPlanId,
          period: '2026-09',
          status: fin.DueStatus.PAID,
          size: 50,
        ),
      );
      final due = page.items.first;
      expect(due.playerName, isNotEmpty);
      expect(due.feePlanName, isNotEmpty);
      expect(due.payment, isNotNull);
      expect(due.payment!.amountMinor, due.amountMinor);
      expect(due.payment!.voided, isFalse);
    });

    Future<fin.Due> firstOpen() async => (await admin.dues(
      const DueQuery(
        planId: MockFinanceApi.monthlyPlanId,
        status: fin.DueStatus.OPEN,
        size: 50,
      ),
    )).items.first;

    test('record a payment: the due is paid in full', () async {
      final open = await firstOpen();
      final paid = await admin.payDue(
        open.id,
        paidOn: today(),
        method: fin.PaymentMethod.CASH,
        note: 'En mano',
      );
      expect(paid.status, fin.DueStatus.PAID);
      expect(paid.payment!.amountMinor, open.amountMinor);
      expect(paid.payment!.method, fin.PaymentMethod.CASH);
      expect(paid.payment!.note, 'En mano');
      await expectLater(
        admin.payDue(open.id, paidOn: today(), method: fin.PaymentMethod.CASH),
        problem(409, 'DUE_NOT_OPEN'),
      );
    });

    test('a payment day after today is refused', () async {
      final open = await firstOpen();
      await expectLater(
        admin.payDue(
          open.id,
          paidOn: daysFromToday(2),
          method: fin.PaymentMethod.CARD,
        ),
        problem(422, 'PAID_ON_IN_FUTURE'),
      );
    });

    test('voiding a payment keeps it and opens the due again', () async {
      final open = await firstOpen();
      final paid = await admin.payDue(
        open.id,
        paidOn: today(),
        method: fin.PaymentMethod.BANK_TRANSFER,
      );
      final voided = await admin.voidPayment(paid.payment!.id, 'Importe mal');
      expect(voided.status, fin.DueStatus.OPEN);
      expect(voided.payment, isNull);
      final detail = await admin.due(open.id);
      expect(detail.payments, hasLength(1));
      expect(detail.payments.single.voided, isTrue);
      expect(detail.payments.single.voidReason, 'Importe mal');
      expect(detail.payments.single.voidedBy, isNotNull);
      await expectLater(
        admin.voidPayment(paid.payment!.id, 'otra vez'),
        problem(409, 'PAYMENT_ALREADY_VOIDED'),
      );
      // and it can be paid again
      final again = await admin.payDue(
        open.id,
        paidOn: today(),
        method: fin.PaymentMethod.CASH,
      );
      expect(again.status, fin.DueStatus.PAID);
      expect((await admin.due(open.id)).payments, hasLength(2));
    });

    test('waive an open due with a reason, for good', () async {
      final open = await firstOpen();
      final waived = await admin.waiveDue(open.id, 'Beca');
      expect(waived.status, fin.DueStatus.WAIVED);
      expect(waived.reason, 'Beca');
      await expectLater(
        admin.waiveDue(open.id, 'otra'),
        problem(409, 'DUE_NOT_OPEN'),
      );
      await expectLater(
        admin.payDue(open.id, paidOn: today(), method: fin.PaymentMethod.CASH),
        problem(409, 'DUE_NOT_OPEN'),
      );
    });

    test('change the amount of an open due: the plan amount stays', () async {
      final open = await firstOpen();
      final changed = await admin.changeDueAmount(
        open.id,
        amountMinor: 2000,
        reason: 'Medio mes',
      );
      expect(changed.amountMinor, 2000);
      expect(changed.planAmountMinor, open.planAmountMinor);
      expect(changed.reason, 'Medio mes');
      expect(changed.status, fin.DueStatus.OPEN);
    });

    test('a reason is needed and amounts stay inside the contract', () async {
      final open = await firstOpen();
      await expectLater(admin.waiveDue(open.id, ''), problem(400));
      await expectLater(
        admin.changeDueAmount(open.id, amountMinor: 0, reason: 'x'),
        problem(400),
      );
      await expectLater(
        admin.changeDueAmount(open.id, amountMinor: 100000000001, reason: 'x'),
        problem(400),
      );
    });

    test('a paid due cannot change its amount', () async {
      final paid = (await admin.dues(
        const DueQuery(status: fin.DueStatus.PAID, size: 50),
      )).items.first;
      await expectLater(
        admin.changeDueAmount(paid.id, amountMinor: 100, reason: 'x'),
        problem(409, 'DUE_NOT_OPEN'),
      );
    });
  });

  group('generating dues', () {
    test('a preview counts and writes nothing', () async {
      final before = (await admin.dues(const DueQuery())).page.totalElements;
      final preview = await admin.generateDues(
        MockFinanceApi.monthlyPlanId,
        period: '2026-12',
        preview: true,
      );
      expect(preview.preview, isTrue);
      expect(preview.created, 7);
      expect(preview.existing, 0);
      expect(preview.dues, hasLength(7));
      expect(preview.dues.every((d) => d.dueId == null), isTrue);
      expect(preview.dues.every((d) => d.amountMinor == 4500), isTrue);
      expect(preview.periodStart, fin.Date(2026, 12, 1));
      expect(preview.periodEnd, fin.Date(2026, 12, 31));
      expect((await admin.dues(const DueQuery())).page.totalElements, before);
    });

    test('generating creates the missing dues, once', () async {
      final made = await admin.generateDues(
        MockFinanceApi.monthlyPlanId,
        period: '2026-12',
      );
      expect(made.preview, isFalse);
      expect(made.created, 7);
      expect(made.dues.every((d) => d.dueId != null), isTrue);
      final again = await admin.generateDues(
        MockFinanceApi.monthlyPlanId,
        period: '2026-12',
      );
      expect(again.created, 0);
      expect(again.existing, 7);
      final december = await admin.dues(
        const DueQuery(period: '2026-12', size: 50),
      );
      expect(december.page.totalElements, 7);
      expect(
        december.items.every((d) => d.status == fin.DueStatus.OPEN),
        isTrue,
      );
    });

    test(
      'a plan of an age category charges the players of its teams',
      () async {
        final preview = await admin.generateDues(
          MockFinanceApi.seasonPlanId,
          period: 'SEASON',
          preview: true,
        );
        expect(preview.created, 8, reason: 'Mini A (7) and Mini B (1)');
        expect(preview.periodStart, fin.Date(2026, 9, 1));
        expect(preview.periodEnd, fin.Date(2027, 6, 30));
      },
    );

    test(
      'periods outside the plan, its cadence or its season are refused',
      () async {
        await expectLater(
          admin.generateDues(
            MockFinanceApi.monthlyPlanId,
            period: '2026-08',
            preview: true,
          ),
          problem(422, 'PERIOD_OUTSIDE_PLAN'),
        );
        await expectLater(
          admin.generateDues(
            MockFinanceApi.monthlyPlanId,
            period: '2027-09',
            preview: true,
          ),
          problem(422, 'PERIOD_OUTSIDE_SEASON'),
        );
        await expectLater(
          admin.generateDues(
            MockFinanceApi.monthlyPlanId,
            period: '2026-Q4',
            preview: true,
          ),
          problem(400),
        );
      },
    );

    test('the first due locks the currency', () async {
      final repo = repoAs(['ADMIN'], tenant: norte);
      await repo.chooseCurrency('JPY');
      final plan = await repo.createFeePlan(
        fin.CreateFeePlanRequest(
          (b) => b
            ..name = 'Cuota Norte'
            ..seasonId = 'season-2026'
            ..teamId = 'team-norte-a'
            ..amountMinor = 8000
            ..cadence = fin.FeeCadence.MONTHLY
            ..firstPeriod = '2026-10',
        ),
      );
      expect((await repo.settings()).currencyLocked, isFalse);
      await repo.generateDues(plan.id, period: '2026-10');
      expect((await repo.settings()).currencyLocked, isTrue);
      await expectLater(
        repo.chooseCurrency('EUR'),
        problem(409, 'CURRENCY_LOCKED'),
      );
    });
  });

  group('what the service does not answer yet', () {
    test('answers 501 like finance-service for the later operations', () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://mock',
          headers: {'Authorization': 'Bearer x', 'X-Tenant-Id': demo},
          validateStatus: (_) => true,
        ),
      )..httpClientAdapter = MockApiAdapter(roles: ['ADMIN']);
      for (final path in [
        '/api/finance/expenses',
        '/api/finance/balance',
        '/api/finance/teams/team-mini-a/due-status',
      ]) {
        final r = await dio.get<dynamic>(path);
        expect(r.statusCode, 501, reason: path);
        expect((r.data as Map)['code'], 'NOT_IMPLEMENTED');
      }
    });
  });
}
