import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:hoops_app/features/finance/domain/periods.dart';

/// Period keys of ADR-0056: a calendar month `YYYY-MM`, a calendar quarter
/// `YYYY-Qn` (Q1 = January to March), `SEASON` for the one period of a
/// SEASON plan.
void main() {
  final seasonStart = DateTime(2026, 9, 1);
  final seasonEnd = DateTime(2027, 6, 30);

  group('Period', () {
    test('a month spans its calendar days', () {
      final p = Period.tryParse('2026-09')!;
      expect(p.kind, PeriodKind.month);
      expect(p.start, DateTime(2026, 9, 1));
      expect(p.end, DateTime(2026, 9, 30));
      expect(Period.tryParse('2026-02')!.end, DateTime(2026, 2, 28));
      expect(Period.tryParse('2028-02')!.end, DateTime(2028, 2, 29));
      expect(Period.tryParse('2026-12')!.end, DateTime(2026, 12, 31));
    });

    test('a quarter is three calendar months, Q1 from January', () {
      final q3 = Period.tryParse('2026-Q3')!;
      expect(q3.kind, PeriodKind.quarter);
      expect(q3.start, DateTime(2026, 7, 1));
      expect(q3.end, DateTime(2026, 9, 30));
      expect(Period.tryParse('2026-Q1')!.start, DateTime(2026, 1, 1));
      expect(Period.tryParse('2026-Q4')!.end, DateTime(2026, 12, 31));
    });

    test('SEASON is a period without dates of its own', () {
      final p = Period.tryParse('SEASON')!;
      expect(p.kind, PeriodKind.season);
      expect(p.key, 'SEASON');
    });

    test('rejects what is not a key', () {
      for (final key in ['', '2026-13', '2026-00', '2026-Q5', '2026-Q0', 'x']) {
        expect(Period.tryParse(key), isNull, reason: key);
      }
    });

    test('the key round-trips', () {
      for (final key in ['2026-09', '2027-01', '2026-Q3', 'SEASON']) {
        expect(Period.tryParse(key)!.key, key);
      }
    });

    test('next rolls over the year', () {
      expect(Period.tryParse('2026-12')!.next().key, '2027-01');
      expect(Period.tryParse('2026-Q4')!.next().key, '2027-Q1');
      expect(Period.tryParse('2026-09')!.next().key, '2026-10');
    });

    test('the period containing a day', () {
      expect(
        Period.containing(fin.FeeCadence.MONTHLY, DateTime(2026, 11, 30)).key,
        '2026-11',
      );
      expect(
        Period.containing(fin.FeeCadence.QUARTERLY, DateTime(2026, 7, 1)).key,
        '2026-Q3',
      );
      expect(
        Period.containing(fin.FeeCadence.QUARTERLY, DateTime(2026, 12, 31)).key,
        '2026-Q4',
      );
      expect(
        Period.containing(fin.FeeCadence.SEASON, DateTime(2026, 12, 31)).key,
        'SEASON',
      );
    });

    test('orders chronologically', () {
      final keys = [
        '2027-01',
        '2026-10',
        '2026-09',
      ].map((k) => Period.tryParse(k)!).toList();
      keys.sort();
      expect([for (final p in keys) p.key], ['2026-09', '2026-10', '2027-01']);
    });
  });

  group('periods of a season', () {
    test('every month that touches the season', () {
      final keys = periodKeysIn(fin.FeeCadence.MONTHLY, seasonStart, seasonEnd);
      expect(keys.first, '2026-09');
      expect(keys.last, '2027-06');
      expect(keys, hasLength(10));
    });

    test('a quarter that only touches the season counts', () {
      expect(periodKeysIn(fin.FeeCadence.QUARTERLY, seasonStart, seasonEnd), [
        '2026-Q3',
        '2026-Q4',
        '2027-Q1',
        '2027-Q2',
      ]);
    });

    test('a SEASON plan has the one period', () {
      expect(periodKeysIn(fin.FeeCadence.SEASON, seasonStart, seasonEnd), [
        'SEASON',
      ]);
    });
  });

  group('periods of a plan', () {
    List<String> plan(fin.FeeCadence cadence, {String? first, String? last}) =>
        planPeriodKeys(
          cadence: cadence,
          firstPeriod: first,
          lastPeriod: last,
          seasonStart: seasonStart,
          seasonEnd: seasonEnd,
        );

    test('no last period: to the end of the season', () {
      final keys = plan(fin.FeeCadence.MONTHLY, first: '2026-10');
      expect(keys.first, '2026-10');
      expect(keys.last, '2027-06');
      expect(keys, hasLength(9));
    });

    test('a last period ends the plan there', () {
      expect(plan(fin.FeeCadence.MONTHLY, first: '2026-10', last: '2026-12'), [
        '2026-10',
        '2026-11',
        '2026-12',
      ]);
    });

    test('periods before the season create no dues', () {
      expect(plan(fin.FeeCadence.MONTHLY, first: '2026-07', last: '2026-10'), [
        '2026-09',
        '2026-10',
      ]);
    });

    test('a plan wholly outside the season has none', () {
      expect(
        plan(fin.FeeCadence.MONTHLY, first: '2025-01', last: '2025-03'),
        isEmpty,
      );
    });

    test('quarterly and season plans', () {
      expect(plan(fin.FeeCadence.QUARTERLY, first: '2026-Q4'), [
        '2026-Q4',
        '2027-Q1',
        '2027-Q2',
      ]);
      expect(plan(fin.FeeCadence.SEASON), ['SEASON']);
    });

    test('a plan without a first period (not yet loaded) has none', () {
      expect(plan(fin.FeeCadence.MONTHLY), isEmpty);
    });
  });

  group('the period to offer first', () {
    final keys = ['2026-09', '2026-10', '2026-11', '2026-12'];

    test('the current one when the plan covers today', () {
      expect(
        suggestedPeriod(keys, fin.FeeCadence.MONTHLY, DateTime(2026, 11, 16)),
        '2026-11',
      );
    });

    test(
      'the first one before the plan starts, the last one after it ends',
      () {
        expect(
          suggestedPeriod(keys, fin.FeeCadence.MONTHLY, DateTime(2026, 8, 31)),
          '2026-09',
        );
        expect(
          suggestedPeriod(keys, fin.FeeCadence.MONTHLY, DateTime(2027, 3, 1)),
          '2026-12',
        );
      },
    );

    test('nothing to offer for a plan without periods', () {
      expect(
        suggestedPeriod(
          const [],
          fin.FeeCadence.MONTHLY,
          DateTime(2026, 11, 16),
        ),
        isNull,
      );
    });
  });
}
