import '../match_event.dart';

/// Game order, independent of arrival: period asc, clock desc,
/// recordedAtClient asc, serverSeq asc (local unsynced events last), id asc
/// (Java `UUID.compareTo` semantics, so ties resolve exactly like the server).
int compareGameOrder(RecordedEvent a, RecordedEvent b) {
  final ma = a.event.meta, mb = b.event.meta;
  var c = ma.period.compareTo(mb.period);
  if (c != 0) return c;
  c = mb.clockSecondsRemaining.compareTo(ma.clockSecondsRemaining);
  if (c != 0) return c;
  c = ma.recordedAtClient.compareTo(mb.recordedAtClient);
  if (c != 0) return c;
  c = _seq(a).compareTo(_seq(b));
  if (c != 0) return c;
  return compareUuids(a.id, b.id);
}

// No serverSeq yet: after every acknowledged event (max safe int on web too).
int _seq(RecordedEvent e) => e.serverSeq ?? 9007199254740991;

/// Events in game order, each id once (earliest in game order wins).
List<RecordedEvent> canonicalOrder(Iterable<RecordedEvent> events) {
  final sorted = events.toList()..sort(compareGameOrder);
  final seen = <String>{};
  return [for (final e in sorted) if (seen.add(e.id)) e];
}

/// `java.util.UUID.compareTo`: most then least significant 64 bits compared
/// as SIGNED longs. Done on hex digits so it is exact on the web (53-bit ints).
int compareUuids(String a, String b) {
  final ha = a.replaceAll('-', '').toLowerCase();
  final hb = b.replaceAll('-', '').toLowerCase();
  if (ha.length != 32 || hb.length != 32) return a.compareTo(b);
  final c = _compareSigned(ha.substring(0, 16), hb.substring(0, 16));
  return c != 0 ? c : _compareSigned(ha.substring(16), hb.substring(16));
}

int _compareSigned(String a, String b) {
  final negA = int.parse(a[0], radix: 16) >= 8;
  final negB = int.parse(b[0], radix: 16) >= 8;
  if (negA != negB) return negA ? -1 : 1;
  return a.compareTo(b);
}
