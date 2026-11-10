import 'dart:convert';
import 'dart:typed_data';

import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One match or training session of the team calendar.
class IcsEvent {
  const IcsEvent({
    required this.kind,
    required this.id,
    required this.summary,
    required this.startsAt,
    required this.endsAt,
    this.location,
    this.description,
    this.cancelled = false,
  });

  /// `match` or `training`; with [id] it makes the stable UID.
  final String kind;
  final String id;
  final String summary;

  /// Instants (UTC).
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;
  final String? description;
  final bool cancelled;

  String get uid => '$kind-$id@hoops-academy';
}

/// An IANA zone for `TZID` times and the `VTIMEZONE` that defines it.
class IcsZone {
  IcsZone._(this._location);

  final tz.Location _location;
  static bool _loaded = false;

  /// The zone [id] (`Europe/Madrid`), or null when unknown / not given: the
  /// calendar then uses UTC times.
  static IcsZone? named(String? id) {
    if (id == null || id.isEmpty) return null;
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
    try {
      return IcsZone._(tz.getLocation(id));
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  String get tzid => _location.name;

  /// The wall clock of [instant] in this zone (as a plain UTC-flagged value).
  DateTime wall(DateTime instant) {
    final t = tz.TZDateTime.from(instant.toUtc(), _location);
    return DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// Offsets in force from 1 January of [from]'s year to [to]: the first
  /// entry is the baseline, the others are the transitions in between.
  List<_Observance> _observances(DateTime from, DateTime to) {
    final year = wall(from).year;
    final baseline = tz.TZDateTime(_location, year).millisecondsSinceEpoch;
    var current = _location.lookupTimeZone(baseline);
    final out = [
      _Observance(
        onset: DateTime.utc(year),
        from: current.timeZone,
        to: current.timeZone,
      ),
    ];
    final limit = to.toUtc().millisecondsSinceEpoch;
    while (current.end < limit) {
      final next = _location.lookupTimeZone(current.end);
      final onset = DateTime.fromMillisecondsSinceEpoch(
        current.end + current.timeZone.offset.inMilliseconds,
        isUtc: true,
      );
      out.add(
        _Observance(onset: onset, from: current.timeZone, to: next.timeZone),
      );
      current = next;
    }
    return out;
  }
}

class _Observance {
  const _Observance({
    required this.onset,
    required this.from,
    required this.to,
  });
  final DateTime onset;
  final tz.TimeZone from;
  final tz.TimeZone to;
}

/// RFC 5545 calendar for the team calendar export: `PRODID`
/// `-//Hoops Academy//EN`, one `VEVENT` per match / session, `TZID` times
/// with their `VTIMEZONE` (UTC `Z` times when no zone is known), `STATUS`
/// `CANCELLED` for cancelled ones, escaped text, lines folded at 75 octets.
class IcsWriter {
  const IcsWriter._();

  static const mediaType = 'text/calendar; charset=utf-8';
  static const extension = 'ics';
  static const _maxOctets = 75;

  static String write(
    List<IcsEvent> events, {
    required IcsZone? zone,
    required DateTime stamp,
  }) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Hoops Academy//EN',
      'CALSCALE:GREGORIAN',
      if (zone != null && events.isNotEmpty) ..._timezone(zone, events),
      for (final e in events) ..._event(e, zone, stamp),
      'END:VCALENDAR',
    ];
    final out = StringBuffer();
    for (final line in lines) {
      _fold(out, line);
    }
    return out.toString();
  }

  static Uint8List encode(
    List<IcsEvent> events, {
    required IcsZone? zone,
    required DateTime stamp,
  }) =>
      Uint8List.fromList(utf8.encode(write(events, zone: zone, stamp: stamp)));

  static List<String> _event(IcsEvent e, IcsZone? zone, DateTime stamp) => [
    'BEGIN:VEVENT',
    'UID:${e.uid}',
    'DTSTAMP:${_utc(stamp)}',
    _time('DTSTART', e.startsAt, zone),
    _time('DTEND', e.endsAt, zone),
    'SUMMARY:${_escape(e.summary)}',
    if (e.location != null && e.location!.isNotEmpty)
      'LOCATION:${_escape(e.location!)}',
    if (e.description != null && e.description!.isNotEmpty)
      'DESCRIPTION:${_escape(e.description!)}',
    'STATUS:${e.cancelled ? 'CANCELLED' : 'CONFIRMED'}',
    'END:VEVENT',
  ];

  static String _time(String name, DateTime instant, IcsZone? zone) =>
      zone == null
      ? '$name:${_utc(instant)}'
      : '$name;TZID=${zone.tzid}:${_local(zone.wall(instant))}';

  static List<String> _timezone(IcsZone zone, List<IcsEvent> events) {
    var first = events.first.startsAt;
    var last = events.first.endsAt;
    for (final e in events) {
      if (e.startsAt.isBefore(first)) first = e.startsAt;
      if (e.endsAt.isAfter(last)) last = e.endsAt;
    }
    return [
      'BEGIN:VTIMEZONE',
      'TZID:${zone.tzid}',
      for (final o in zone._observances(first, last)) ...[
        'BEGIN:${o.to.isDst ? 'DAYLIGHT' : 'STANDARD'}',
        'DTSTART:${_local(o.onset)}',
        'TZOFFSETFROM:${_offset(o.from.offset)}',
        'TZOFFSETTO:${_offset(o.to.offset)}',
        'TZNAME:${_escape(o.to.abbreviation)}',
        'END:${o.to.isDst ? 'DAYLIGHT' : 'STANDARD'}',
      ],
      'END:VTIMEZONE',
    ];
  }

  static String _utc(DateTime t) => '${_local(t.toUtc())}Z';

  static String _local(DateTime t) =>
      '${_n(t.year, 4)}${_n(t.month, 2)}${_n(t.day, 2)}'
      'T${_n(t.hour, 2)}${_n(t.minute, 2)}${_n(t.second, 2)}';

  static String _offset(Duration d) {
    final minutes = d.inMinutes.abs();
    return '${d.isNegative ? '-' : '+'}${_n(minutes ~/ 60, 2)}${_n(minutes % 60, 2)}';
  }

  static String _n(int v, int width) => v.toString().padLeft(width, '0');

  /// RFC 5545 section 3.3.11.
  static String _escape(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\r', r'\n')
      .replaceAll('\n', r'\n');

  /// Folds at [_maxOctets] octets (the continuation's leading space counts)
  /// without splitting a UTF-8 sequence.
  static void _fold(StringBuffer out, String line) {
    var octets = 0;
    var limit = _maxOctets;
    for (final rune in line.runes) {
      final width = utf8.encode(String.fromCharCode(rune)).length;
      if (octets + width > limit) {
        out.write('\r\n ');
        octets = 1;
        limit = _maxOctets;
      }
      out.writeCharCode(rune);
      octets += width;
    }
    out.write('\r\n');
  }
}
