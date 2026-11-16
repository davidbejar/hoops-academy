import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

enum PeriodKind { month, quarter, season }

/// A billing period of a fee plan (ADR-0056): a calendar month `2026-09`, a
/// calendar quarter `2026-Q3` (Q1 = January to March) or `SEASON`, the one
/// period of a SEASON plan, whose dates are the season's.
class Period implements Comparable<Period> {
  const Period._(this.kind, this.year, this.number);

  /// `SEASON`.
  static const season = Period._(PeriodKind.season, 0, 0);

  final PeriodKind kind;
  final int year;

  /// Month 1..12, or quarter 1..4.
  final int number;

  static final _month = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$');
  static final _quarter = RegExp(r'^(\d{4})-Q([1-4])$');

  /// The period named by [key], or null when it is not a period key.
  static Period? tryParse(String key) {
    if (key == 'SEASON') return season;
    final month = _month.firstMatch(key);
    if (month != null) {
      return Period._(
        PeriodKind.month,
        int.parse(month[1]!),
        int.parse(month[2]!),
      );
    }
    final quarter = _quarter.firstMatch(key);
    if (quarter != null) {
      return Period._(
        PeriodKind.quarter,
        int.parse(quarter[1]!),
        int.parse(quarter[2]!),
      );
    }
    return null;
  }

  /// The period of [cadence] that [day] falls in.
  static Period containing(fin.FeeCadence cadence, DateTime day) {
    if (cadence == fin.FeeCadence.MONTHLY) {
      return Period._(PeriodKind.month, day.year, day.month);
    }
    if (cadence == fin.FeeCadence.QUARTERLY) {
      return Period._(PeriodKind.quarter, day.year, (day.month - 1) ~/ 3 + 1);
    }
    return season;
  }

  String get key => switch (kind) {
    PeriodKind.month => '$year-${number.toString().padLeft(2, '0')}',
    PeriodKind.quarter => '$year-Q$number',
    PeriodKind.season => 'SEASON',
  };

  /// First day. A SEASON period has none of its own (the season's dates
  /// apply), so this is only meaningful for months and quarters.
  DateTime get start => switch (kind) {
    PeriodKind.month => DateTime(year, number, 1),
    PeriodKind.quarter => DateTime(year, (number - 1) * 3 + 1, 1),
    PeriodKind.season => DateTime(year, 1, 1),
  };

  /// Last day (inclusive).
  DateTime get end => switch (kind) {
    PeriodKind.month => DateTime(year, number + 1, 0),
    PeriodKind.quarter => DateTime(year, number * 3 + 1, 0),
    PeriodKind.season => DateTime(year, 12, 31),
  };

  Period next() => switch (kind) {
    PeriodKind.month =>
      number == 12
          ? Period._(kind, year + 1, 1)
          : Period._(kind, year, number + 1),
    PeriodKind.quarter =>
      number == 4
          ? Period._(kind, year + 1, 1)
          : Period._(kind, year, number + 1),
    PeriodKind.season => this,
  };

  @override
  int compareTo(Period other) {
    final byYear = year.compareTo(other.year);
    return byYear != 0 ? byYear : number.compareTo(other.number);
  }

  @override
  bool operator ==(Object other) => other is Period && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

/// Keys of every period of [cadence] that touches the season from
/// [seasonStart] to [seasonEnd] (a period wholly outside it creates no dues).
List<String> periodKeysIn(
  fin.FeeCadence cadence,
  DateTime seasonStart,
  DateTime seasonEnd,
) {
  if (cadence == fin.FeeCadence.SEASON) return [Period.season.key];
  final keys = <String>[];
  var period = Period.containing(cadence, seasonStart);
  while (!period.start.isAfter(seasonEnd)) {
    keys.add(period.key);
    period = period.next();
  }
  return keys;
}

/// The periods a plan charges: those of its cadence from [firstPeriod] to
/// [lastPeriod] (none: to the end of the season) that touch the season.
List<String> planPeriodKeys({
  required fin.FeeCadence cadence,
  required String? firstPeriod,
  required String? lastPeriod,
  required DateTime seasonStart,
  required DateTime seasonEnd,
}) {
  if (cadence == fin.FeeCadence.SEASON) return [Period.season.key];
  final first = firstPeriod == null ? null : Period.tryParse(firstPeriod);
  if (first == null) return const [];
  final last = lastPeriod == null ? null : Period.tryParse(lastPeriod);
  return [
    for (final key in periodKeysIn(cadence, seasonStart, seasonEnd))
      if (Period.tryParse(key)!.compareTo(first) >= 0 &&
          (last == null || Period.tryParse(key)!.compareTo(last) <= 0))
        key,
  ];
}

/// The period to offer first among [keys]: the one [today] falls in, else the
/// first (the plan has not started) or the last (it has ended).
String? suggestedPeriod(
  List<String> keys,
  fin.FeeCadence cadence,
  DateTime today,
) {
  if (keys.isEmpty) return null;
  final current = Period.containing(cadence, today).key;
  if (keys.contains(current)) return current;
  final first = Period.tryParse(keys.first)!;
  return Period.containing(cadence, today).compareTo(first) < 0
      ? keys.first
      : keys.last;
}
