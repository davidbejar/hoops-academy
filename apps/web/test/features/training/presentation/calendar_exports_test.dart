import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/export/export_table.dart';
import 'package:hoops_app/core/export/ics_writer.dart';
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/features/training/application/team_calendar.dart';
import 'package:hoops_app/features/training/presentation/calendar_exports.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/ics_validator.dart';

AppLocalizations l(String lang) => lookupAppLocalizations(Locale(lang));

gen.Match match(
  String id, {
  required DateTime at,
  String opponent = 'Lobos',
  gen.MatchStatus status = gen.MatchStatus.SCHEDULED,
  String? venue,
  String? cancelReason,
}) => gen.Match(
  (b) => b
    ..id = id
    ..teamId = 't1'
    ..seasonId = 's1'
    ..opponentName = opponent
    ..homeAway = gen.HomeAway.HOME
    ..scheduledAt = at
    ..venue = venue
    ..status = status
    ..periodCount = 4
    ..periodMinutes = 10
    ..cancelReason = cancelReason
    ..score.team = 0
    ..score.opponent = 0
    ..lastServerSeq = 0,
);

ath.TrainingSession training(
  String id, {
  required DateTime at,
  String? location,
  ath.TrainingSessionStatus status = ath.TrainingSessionStatus.PLANNED,
  String? cancelReason,
  String? notes,
}) => ath.TrainingSession(
  (b) => b
    ..id = id
    ..teamId = 't1'
    ..startsAt = at
    ..durationMinutes = 90
    ..location = location
    ..status = status
    ..cancelReason = cancelReason
    ..notes = notes,
);

Object? value(ExportCell c) => switch (c) {
  TextCell(:final value) => value,
  NumberCell(:final value) => value,
  DateCell(:final value) => isoDate(value),
  TimeCell(:final hour, :final minute) => isoTime(hour, minute),
  EmptyCell() => null,
};

void main() {
  final madrid = TenantZone.of('Europe/Madrid');
  final names = {'t1': 'Cadete A'};
  final entries = [
    SessionEntry(
      training(
        's1',
        at: DateTime.utc(2026, 11, 3, 17),
        location: 'Pabellón, Norte',
      ),
    ),
    MatchEntry(
      match(
        'm1',
        at: DateTime.utc(2026, 11, 7, 10),
        venue: 'Pista 2',
        status: gen.MatchStatus.FINISHED,
      ),
    ),
    SessionEntry(
      training(
        's2',
        at: DateTime.utc(2026, 11, 10, 17),
        status: ath.TrainingSessionStatus.CANCELLED,
        cancelReason: 'Lluvia; sin pabellón',
      ),
    ),
    MatchEntry(
      match(
        'm2',
        at: DateTime.utc(2026, 11, 14, 10),
        opponent: '=Tigres',
        status: gen.MatchStatus.CANCELLED,
        cancelReason: 'Rival retirado',
      ),
    ),
  ];

  group('entries', () {
    test('end times: session duration, match periods x minutes', () {
      expect(entries[0].endsAt, DateTime.utc(2026, 11, 3, 18, 30));
      expect(entries[1].endsAt, DateTime.utc(2026, 11, 7, 10, 40));
    });

    test('cancelled state', () {
      expect(entries.map((e) => e.cancelled), [false, false, true, true]);
    });
  });

  group('calendarTable', () {
    final table = calendarTable(
      l('en'),
      entries,
      zone: madrid,
      teamNames: names,
    );

    test('headers in the user language', () {
      expect(table.headers, [
        'Date',
        'Start time',
        'End time',
        'Time zone',
        'Type',
        'Team',
        'Event',
        'Venue',
        'Status',
        'Notes',
      ]);
      expect(
        calendarTable(
          l('es'),
          const [],
          zone: madrid,
          teamNames: names,
        ).headers.first,
        'Fecha',
      );
    });

    test('a training row', () {
      expect(
        [for (final c in table.rows[0]) value(c)],
        [
          '2026-11-03',
          '18:00',
          '19:30',
          'Europe/Madrid',
          'Training',
          'Cadete A',
          'Training',
          'Pabellón, Norte',
          'Planned',
          null,
        ],
      );
    });

    test('a match row has the opponent and the venue', () {
      expect(
        [for (final c in table.rows[1]) value(c)],
        [
          '2026-11-07',
          '11:00',
          '11:40',
          'Europe/Madrid',
          'Match',
          'Cadete A',
          'vs Lobos',
          'Pista 2',
          'Finished',
          null,
        ],
      );
    });

    test('cancelled ones carry their state and reason', () {
      expect(value(table.rows[2][8]), 'Cancelled');
      expect(value(table.rows[2][9]), 'Lluvia; sin pabellón');
      expect(value(table.rows[3][9]), 'Rival retirado');
    });

    test('unknown team: empty cell', () {
      final t = calendarTable(
        l('en'),
        entries,
        zone: madrid,
        teamNames: const {},
      );
      expect(value(t.rows[0][5]), isNull);
    });
  });

  group('calendarIcsEvents + IcsWriter', () {
    final events = calendarIcsEvents(l('en'), entries, teamNames: names);
    final ics = IcsWriter.write(
      events,
      zone: IcsZone.named('Europe/Madrid'),
      stamp: DateTime.utc(2026, 11, 10, 9),
    );

    test('stable ids per kind', () {
      expect(events.map((e) => e.uid), [
        'training-s1@hoops-academy',
        'match-m1@hoops-academy',
        'training-s2@hoops-academy',
        'match-m2@hoops-academy',
      ]);
    });

    test('summary has the team and the event, venue is the location', () {
      expect(events[0].summary, 'Cadete A · Training');
      expect(events[1].summary, 'Cadete A · vs Lobos');
      expect(events[1].location, 'Pista 2');
      expect(events[0].location, 'Pabellón, Norte');
    });

    test('cancelled ones are STATUS:CANCELLED, others CONFIRMED', () {
      expect(RegExp('STATUS:CANCELLED').allMatches(ics), hasLength(2));
      expect(RegExp('STATUS:CONFIRMED').allMatches(ics), hasLength(2));
    });

    test('the file from this data validates line by line (RFC 5545)', () {
      expect(validateIcs(utf8.encode(ics)), isEmpty);
    });

    test('times in the academy zone, commas and semicolons escaped', () {
      expect(ics, contains('DTSTART;TZID=Europe/Madrid:20261103T180000'));
      expect(ics, contains(r'LOCATION:Pabellón\, Norte'));
      expect(ics, contains(r'DESCRIPTION:Lluvia\; sin pabellón'));
    });
  });
}
