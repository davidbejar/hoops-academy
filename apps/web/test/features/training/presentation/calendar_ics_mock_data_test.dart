import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/export/ics_writer.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/match/data/mock_game_api.dart';
import 'package:hoops_app/features/training/application/team_calendar.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';
import 'package:hoops_app/features/training/presentation/calendar_exports.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/ics_validator.dart';

/// The calendar of the demo mock (matches of game-service and sessions of
/// athlete-service, read through the real generated clients and
/// repositories) written as an ICS file and checked line by line against
/// RFC 5545, in every app language.
void main() {
  Dio dio() => Dio(
    BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}),
  )..httpClientAdapter = MockApiAdapter(roles: ['ADMIN']);

  test('the mock calendar is a valid RFC 5545 file', () async {
    final game = gen.HoopsGameApi(dio: dio(), interceptors: const []);
    final athlete = ath.HoopsAthleteApi(dio: dio(), interceptors: const []);
    final matches = await ApiMatchesRepository(
      game,
      mockTenantAId,
    ).list(teamId: MockGameApi.ownTeamId);
    final sessions = await ApiTrainingRepository(athlete, mockTenantAId)
        .sessions(
          teamId: 'team-mini-a',
          from: ath.Date(2026, 1, 1),
          to: ath.Date(2027, 12, 31),
        );
    expect(matches, isNotEmpty);
    expect(sessions, isNotEmpty);
    final entries = <CalendarEntry>[
      for (final m in matches) MatchEntry(m),
      for (final s in sessions) SessionEntry(s),
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    for (final lang in ['es', 'en', 'id']) {
      final ics = IcsWriter.encode(
        calendarIcsEvents(
          lookupAppLocalizations(Locale(lang)),
          entries,
          teamNames: const {'team-mini-a': 'Mini A'},
        ),
        zone: IcsZone.named('Europe/Madrid'),
        stamp: DateTime.utc(2026, 11, 10, 9),
      );
      expect(validateIcs(ics), isEmpty, reason: lang);
      expect(
        RegExp('BEGIN:VEVENT').allMatches(utf8.decode(ics)),
        hasLength(entries.length),
      );
    }
  });
}
