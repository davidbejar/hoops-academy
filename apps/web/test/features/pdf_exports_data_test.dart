import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../support/fake_adapter.dart';

const _tenant = '11111111-1111-4111-8111-111111111111';
const _pdf = '%PDF-1.7 fixed';

Dio _dio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;

FakeResponse _file(String name) => FakeResponse(
  200,
  _pdf,
  contentType: 'application/pdf',
  headers: {'content-disposition': 'attachment; filename="$name"'},
);

Future<AppError> _failure(Future<Object?> call) async {
  try {
    await call;
  } on Object catch (e) {
    return AppError.of(e);
  }
  fail('expected a failure');
}

void main() {
  group('team roster PDF (core 3.7.0)', () {
    (ApiTeamsRepository, FakeAdapter) repo(FakeResponse r) {
      final adapter = FakeAdapter([r]);
      return (
        ApiTeamsRepository(
          api.HoopsCoreApi(dio: _dio(adapter), interceptors: const []),
          _tenant,
        ),
        adapter,
      );
    }

    test('asks for application/pdf in the language, keeps the name', () async {
      final (teams, adapter) = repo(_file('hoops-x-roster-mini-a-2026.pdf'));

      final file = await teams.exportRosterPdf('t1', language: 'id');

      final request = adapter.requests.single;
      expect(request.path, '/api/core/teams/t1/roster:export');
      expect(request.headers['Accept'], 'application/pdf');
      expect(request.headers['Accept-Language'], 'id');
      expect(request.headers['X-Tenant-Id'], _tenant);
      expect(utf8.decode(file.bytes), _pdf);
      expect(file.fileName, 'hoops-x-roster-mini-a-2026.pdf');
    });

    test('a 422 EXPORT_TOO_LARGE keeps its code', () async {
      final (teams, _) = repo(
        FakeResponse.problem(422, {
          'title': 'Too large',
          'status': 422,
          'code': 'EXPORT_TOO_LARGE',
        }),
      );
      final error = await _failure(teams.exportRosterPdf('t1', language: 'es'));
      expect(error.status, 422);
      expect(error.code, 'EXPORT_TOO_LARGE');
    });

    test('a 503 is a server error with its code', () async {
      final (teams, _) = repo(
        FakeResponse.problem(503, {
          'title': 'Unavailable',
          'status': 503,
          'code': 'UPSTREAM_UNAVAILABLE',
        }),
      );
      final error = await _failure(teams.exportRosterPdf('t1', language: 'es'));
      expect(error.status, 503);
      expect(error.kind, AppErrorKind.server);
      expect(error.code, 'UPSTREAM_UNAVAILABLE');
    });
  });

  group('match sheet PDF (game 2.4.0)', () {
    (ApiMatchesRepository, FakeAdapter) repo(FakeResponse r) {
      final adapter = FakeAdapter([r]);
      return (
        ApiMatchesRepository(
          gen.HoopsGameApi(dio: _dio(adapter), interceptors: const []),
          _tenant,
        ),
        adapter,
      );
    }

    test('asks box-score:pdf in the language, keeps the name', () async {
      final (matches, adapter) = repo(_file('hoops-x-match-sheet.pdf'));

      final file = await matches.matchSheetPdf('m1', language: 'en');

      final request = adapter.requests.single;
      expect(request.path, '/api/game/matches/m1/box-score:pdf');
      expect(request.headers['Accept-Language'], 'en');
      expect(request.headers['X-Tenant-Id'], _tenant);
      expect(utf8.decode(file.bytes), _pdf);
      expect(file.fileName, 'hoops-x-match-sheet.pdf');
    });

    test('a 503 is an AppError (server), a 404 not found', () async {
      final (down, _) = repo(
        FakeResponse.problem(503, {
          'title': 'Unavailable',
          'status': 503,
          'code': 'UPSTREAM_UNAVAILABLE',
        }),
      );
      await expectLater(
        down.matchSheetPdf('m1', language: 'es'),
        throwsA(
          isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.server),
        ),
      );
      final (gone, _) = repo(
        FakeResponse.problem(404, {'title': 'Not found', 'status': 404}),
      );
      await expectLater(
        gone.matchSheetPdf('m1', language: 'es'),
        throwsA(
          isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.notFound),
        ),
      );
    });
  });
}
