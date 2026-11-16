import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

/// The demo mock answers the two PDF calls with a small fixed PDF.
void main() {
  const t = mockTenantAId;

  Dio dioFor(List<String> roles) => Dio(
    BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}),
  )..httpClientAdapter = MockApiAdapter(roles: roles);

  ApiTeamsRepository teams(List<String> roles) => ApiTeamsRepository(
    api.HoopsCoreApi(dio: dioFor(roles), interceptors: const []),
    t,
  );

  ApiMatchesRepository games(List<String> roles) => ApiMatchesRepository(
    gen.HoopsGameApi(dio: dioFor(roles), interceptors: const []),
    t,
  );

  Matcher status(int code) => throwsA(
    isA<DioException>().having((e) => e.response?.statusCode, 'status', code),
  );

  test(
    'the roster PDF: a PDF with its file name, for admin and coach',
    () async {
      final file = await teams(['ADMIN'])
          .exportRosterPdf('team-mini-a', language: 'en');
      expect(utf8.decode(file.bytes.take(5).toList()), '%PDF-');
      expect(file.fileName, matches(r'^hoops-demo-roster-.*-\d{8}\.pdf$'));
      await teams(['COACH']).exportRosterPdf('team-mini-a', language: 'en');
    },
  );

  test('the roster PDF keeps the CSV rules (403, 404)', () async {
    await expectLater(
      teams(['PARENT']).exportRosterPdf('team-mini-a', language: 'en'),
      status(403),
    );
    await expectLater(
      teams(['ADMIN']).exportRosterPdf('nope', language: 'en'),
      status(404),
    );
  });

  test('the roster CSV is unchanged without the PDF Accept', () async {
    final csv = await teams(['ADMIN'])
        .exportRoster('team-mini-a', language: 'en');
    expect(csv.take(3), [0xEF, 0xBB, 0xBF]);
  });

  test('the match sheet: a PDF with its file name', () async {
    final list = await games(['ADMIN']).list();
    final file = await games(['ADMIN'])
        .matchSheetPdf(list.first.id, language: 'en');
    expect(utf8.decode(file.bytes.take(5).toList()), '%PDF-');
    expect(file.fileName, matches(r'^hoops-demo-match-sheet-.*\.pdf$'));
  });

  test('the match sheet of an unknown match is 404', () async {
    await expectLater(
      games(['ADMIN']).matchSheetPdf('nope', language: 'en'),
      throwsA(isA<AppError>().having((e) => e.status, 'status', 404)),
    );
  });
}
