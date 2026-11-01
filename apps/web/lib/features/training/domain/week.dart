/// Pure calendar helpers for the week view (no Flutter imports).
library;

/// Monday 00:00 (local, date only) of the week containing [d].
DateTime startOfWeek(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
}

/// The seven days Monday..Sunday starting at [monday].
List<DateTime> weekDays(DateTime monday) => [
  for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i),
];

DateTime addWeeks(DateTime monday, int weeks) =>
    DateTime(monday.year, monday.month, monday.day + 7 * weeks);

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Groups [items] by local calendar day of [at], each group sorted by time.
Map<DateTime, List<T>> groupByDay<T>(Iterable<T> items, DateTime Function(T) at) {
  final out = <DateTime, List<T>>{};
  for (final i in items) {
    final t = at(i).toLocal();
    out.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(i);
  }
  for (final l in out.values) {
    l.sort((a, b) => at(a).compareTo(at(b)));
  }
  return out;
}
