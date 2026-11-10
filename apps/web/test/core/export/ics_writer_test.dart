import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/ics_writer.dart';

import '../../support/ics_validator.dart';

IcsEvent event({
  String kind = 'match',
  String id = '1',
  String summary = 'Match vs Lions',
  DateTime? startsAt,
  DateTime? endsAt,
  String? location,
  String? description,
  bool cancelled = false,
}) => IcsEvent(
  kind: kind,
  id: id,
  summary: summary,
  startsAt: startsAt ?? DateTime.utc(2026, 3, 7, 17, 0),
  endsAt: endsAt ?? DateTime.utc(2026, 3, 7, 18, 30),
  location: location,
  description: description,
  cancelled: cancelled,
);

final stamp = DateTime.utc(2026, 11, 10, 8, 30, 15);
final madrid = IcsZone.named('Europe/Madrid')!;

String write(List<IcsEvent> events, {IcsZone? zone}) =>
    IcsWriter.write(events, zone: zone, stamp: stamp);

List<String> linesOf(String ics) => const LineSplitter().convert(ics);

void main() {
  test(
    'media type',
    () => expect(IcsWriter.mediaType, 'text/calendar; charset=utf-8'),
  );

  group('envelope', () {
    test('CRLF lines, calendar header and footer', () {
      final ics = write([event()], zone: madrid);
      expect(ics, endsWith('END:VCALENDAR\r\n'));
      final lines = linesOf(ics);
      expect(lines.take(4), [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'PRODID:-//Hoops Academy//EN',
        'CALSCALE:GREGORIAN',
      ]);
      expect(lines.last, 'END:VCALENDAR');
    });

    test('an empty calendar is still a valid file', () {
      expect(validateIcs(utf8.encode(write(const [], zone: madrid))), isEmpty);
    });
  });

  group('events', () {
    test('stable UID per kind and id, DTSTAMP in UTC', () {
      final lines = linesOf(
        write([
          event(kind: 'match', id: 'abc'),
          event(kind: 'training', id: 'def'),
        ], zone: madrid),
      );
      expect(lines, contains('UID:match-abc@hoops-academy'));
      expect(lines, contains('UID:training-def@hoops-academy'));
      expect(lines.where((l) => l == 'DTSTAMP:20261110T083015Z'), hasLength(2));
    });

    test('times carry the academy zone (winter: +01:00)', () {
      final lines = linesOf(write([event()], zone: madrid));
      expect(lines, contains('DTSTART;TZID=Europe/Madrid:20260307T180000'));
      expect(lines, contains('DTEND;TZID=Europe/Madrid:20260307T193000'));
    });

    test('times follow daylight saving (summer: +02:00)', () {
      final lines = linesOf(
        write([
          event(
            startsAt: DateTime.utc(2026, 7, 4, 16, 0),
            endsAt: DateTime.utc(2026, 7, 4, 17, 0),
          ),
        ], zone: madrid),
      );
      expect(lines, contains('DTSTART;TZID=Europe/Madrid:20260704T180000'));
    });

    test('without a zone the times are UTC', () {
      final ics = write([event()]);
      final lines = linesOf(ics);
      expect(lines, contains('DTSTART:20260307T170000Z'));
      expect(lines, contains('DTEND:20260307T183000Z'));
      expect(ics, isNot(contains('VTIMEZONE')));
    });

    test('a cancelled event says so', () {
      final lines = linesOf(write([event(cancelled: true)], zone: madrid));
      expect(lines, contains('STATUS:CANCELLED'));
    });

    test('an active event is CONFIRMED', () {
      expect(
        linesOf(write([event()], zone: madrid)),
        contains('STATUS:CONFIRMED'),
      );
    });

    test('venue becomes LOCATION; none, no line', () {
      expect(
        linesOf(write([event(location: 'Pabellón Norte')], zone: madrid)),
        contains('LOCATION:Pabellón Norte'),
      );
      expect(write([event()], zone: madrid), isNot(contains('LOCATION')));
    });
  });

  group('text escaping', () {
    test(r'backslash, semicolon, comma and newline', () {
      final lines = linesOf(
        write([
          event(
            summary:
                r'a\b;c,d'
                '\n'
                'e',
            location: 'Hall 1, Court 2; east',
            description: 'line1\r\nline2\rline3',
          ),
        ], zone: madrid),
      );
      expect(lines, contains(r'SUMMARY:a\\b\;c\,d\ne'));
      expect(lines, contains(r'LOCATION:Hall 1\, Court 2\; east'));
      expect(lines, contains(r'DESCRIPTION:line1\nline2\nline3'));
    });
  });

  group('folding at 75 octets', () {
    test('a long summary is folded with a leading space', () {
      final ics = write([event(summary: 'x' * 200)], zone: madrid);
      for (final line in linesOf(ics)) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
      }
      final lines = linesOf(ics);
      final i = lines.indexWhere((l) => l.startsWith('SUMMARY:'));
      expect(lines[i], hasLength(75));
      expect(lines[i + 1], startsWith(' '));
      // Unfolding gives the original back.
      final unfolded = ics.replaceAll('\r\n ', '');
      expect(unfolded, contains('SUMMARY:${'x' * 200}\r\n'));
    });

    test('a fold never splits a multi-byte character', () {
      final summary = 'ñ' * 120; // 2 octets each
      final ics = write([event(summary: summary)], zone: madrid);
      expect(() => utf8.decode(utf8.encode(ics)), returnsNormally);
      final unfolded = ics.replaceAll('\r\n ', '');
      expect(unfolded, contains('SUMMARY:$summary\r\n'));
      for (final line in linesOf(ics)) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
    });
  });

  group('VTIMEZONE', () {
    test('declares the zone with its observances around the events', () {
      final lines = linesOf(
        write([
          event(),
          event(
            id: '2',
            startsAt: DateTime.utc(2026, 7, 4, 16),
            endsAt: DateTime.utc(2026, 7, 4, 17),
          ),
        ], zone: madrid),
      );
      expect(lines, contains('BEGIN:VTIMEZONE'));
      expect(lines, contains('TZID:Europe/Madrid'));
      // March 2026: CET -> CEST on the 29th at 02:00 local.
      expect(lines, contains('BEGIN:DAYLIGHT'));
      expect(lines, contains('DTSTART:20260329T020000'));
      expect(lines, contains('TZOFFSETFROM:+0100'));
      expect(lines, contains('TZOFFSETTO:+0200'));
      expect(lines, contains('TZNAME:CEST'));
      expect(lines, contains('BEGIN:STANDARD'));
      expect(lines, contains('TZNAME:CET'));
    });

    test('is declared before the first event', () {
      final lines = linesOf(write([event()], zone: madrid));
      expect(
        lines.indexOf('BEGIN:VTIMEZONE'),
        lessThan(lines.indexOf('BEGIN:VEVENT')),
      );
    });

    test('a zone without daylight saving still validates', () {
      final jakarta = IcsZone.named('Asia/Jakarta')!;
      final ics = write([event()], zone: jakarta);
      expect(validateIcs(utf8.encode(ics)), isEmpty);
      expect(ics, contains('DTSTART:20260101T000000'));
    });

    test('an unknown zone id is null (the caller falls back to UTC)', () {
      expect(IcsZone.named('Mars/Olympus'), isNull);
      expect(IcsZone.named(null), isNull);
    });
  });

  group('RFC 5545 line-by-line validation', () {
    test('a mixed calendar passes the validator', () {
      final ics = write([
        event(
          location: 'Pabellón, Norte; pista 2',
          description: 'Equipo: Cadete A',
        ),
        event(kind: 'training', id: 't1', summary: 'Entrenamiento ñandú ' * 8),
        event(id: '3', cancelled: true, summary: r'C:\ñ'),
      ], zone: madrid);
      expect(validateIcs(utf8.encode(ics)), isEmpty);
    });

    test('the validator itself catches a long line', () {
      final bad =
          'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:x\r\n'
          'X-LONG:${'a' * 80}\r\nEND:VCALENDAR\r\n';
      expect(validateIcs(utf8.encode(bad)), isNotEmpty);
    });
  });
}
