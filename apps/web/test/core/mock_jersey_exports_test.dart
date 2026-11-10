import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/audit/data/audit_repository.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

/// Mock parity for core 3.5.0 (WP101): the preferred number, the rule that
/// chose an assigned number, the taken numbers and the three CSV exports. The
/// generated client parses every answer, so a shape that differs from the
/// contract fails here.
void main() {
  const t = mockTenantAId;

  api.HoopsCoreApi clientFor(List<String> roles) => api.HoopsCoreApi(
    dio: Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: roles),
    interceptors: const [],
  );

  Matcher status(int code) => throwsA(
    isA<DioException>().having((e) => e.response?.statusCode, 'status', code),
  );

  group('preferred number', () {
    test('an admin sets it, it is read back, clear removes it', () async {
      final players = ApiPlayersRepository(clientFor(['ADMIN']), t);

      expect(
        (await players.setPreferredJersey('p-eva', '7')).preferredJerseyNumber,
        '7',
      );
      expect((await players.get('p-eva')).preferredJerseyNumber, '7');
      expect(
        (await players.setPreferredJersey('p-eva', null)).preferredJerseyNumber,
        isNull,
      );
    });

    test('only one or two digits are accepted', () async {
      final players = ApiPlayersRepository(clientFor(['ADMIN']), t);
      for (final bad in ['123', 'a', '']) {
        await expectLater(players.setPreferredJersey('p-eva', bad), status(400));
      }
    });

    test('a parent sets it for a linked player only', () async {
      final players = ApiPlayersRepository(clientFor(['PARENT']), t);
      expect(
        (await players.setPreferredJersey('p-ana', '3')).preferredJerseyNumber,
        '3',
      );
      await expectLater(players.setPreferredJersey('p-leo', '3'), status(404));
    });

    test('a player sets it for himself', () async {
      final players = ApiPlayersRepository(clientFor(['PLAYER']), t);
      expect(
        (await players.setPreferredJersey('p-leo', '9')).preferredJerseyNumber,
        '9',
      );
    });

    test('an assistant coach may not (403)', () async {
      final players = ApiPlayersRepository(clientFor(['ASSISTANT_COACH']), t);
      await expectLater(players.setPreferredJersey('p-ana', '3'), status(403));
    });
  });

  group('assignment', () {
    test('the previous number is carried over when it is free', () async {
      final teams = ApiTeamsRepository(clientFor(['ADMIN']), t);
      final assigned = await teams.assign('team-inf-a', 'p-leo');
      expect(assigned.jerseySource, api.JerseySource.PREVIOUS);
      expect(assigned.jerseyNumber, '10');
    });

    test('the preferred number wins over the previous one', () async {
      final client = clientFor(['ADMIN']);
      await ApiPlayersRepository(client, t).setPreferredJersey('p-leo', '3');
      final assigned = await ApiTeamsRepository(
        client,
        t,
      ).assign('team-inf-a', 'p-leo');
      expect(assigned.jerseySource, api.JerseySource.PREFERRED);
      expect(assigned.jerseyNumber, '3');
    });

    test('a preferred number that is taken falls back to the previous', () async {
      final client = clientFor(['ADMIN']);
      await ApiPlayersRepository(client, t).setPreferredJersey('p-leo', '9');
      final assigned = await ApiTeamsRepository(
        client,
        t,
      ).assign('team-inf-a', 'p-leo');
      expect(assigned.jerseySource, api.JerseySource.PREVIOUS);
    });

    test('a requested number is used, a taken one is a 409', () async {
      final teams = ApiTeamsRepository(clientFor(['ADMIN']), t);
      await expectLater(
        teams.assign('team-inf-a', 'p-leo', jerseyNumber: '9'),
        status(409),
      );
      final assigned = await teams.assign(
        'team-inf-a',
        'p-leo',
        jerseyNumber: '12',
      );
      expect(assigned.jerseySource, api.JerseySource.REQUESTED);
    });

    test('nothing to carry over is NONE', () async {
      final client = clientFor(['ADMIN']);
      final teams = ApiTeamsRepository(client, t);
      final eligible = await ApiPlayersRepository(
        client,
        t,
      ).eligibleTeams('p-eva', 'season-2026');
      final target = eligible.firstWhere(
        (e) => e.eligibility.result != api.EligibilityResult.INELIGIBLE,
      );
      final assigned = await teams.assign(target.team.id, 'p-eva');
      expect(assigned.jerseySource, api.JerseySource.NONE);
      expect(assigned.jerseyNumber, isNull);
    });
  });

  group('taken numbers', () {
    test('lists each number with its player, by value', () async {
      final taken = await ApiTeamsRepository(
        clientFor(['ADMIN']),
        t,
      ).jerseyNumbers('team-mini-a');
      expect(taken.map((x) => x.jerseyNumber), [
        '4',
        '5',
        '7',
        '8',
        '10',
        '11',
        '13',
      ]);
      expect(taken.first.player.displayName, 'Sara Vidal');
    });

    test('an unknown team is a 404', () async {
      await expectLater(
        ApiTeamsRepository(clientFor(['ADMIN']), t).jerseyNumbers('nope'),
        status(404),
      );
    });
  });

  group('exports', () {
    test('the roster is a CSV file with a name and no caching', () async {
      final response = await clientFor(['ADMIN'])
          .getTeamsApi()
          .exportTeamRoster(
            xTenantId: t,
            teamId: 'team-mini-a',
            acceptLanguage: 'es',
          );
      final text = utf8.decode(response.data!);
      expect(text.startsWith('\u{feff}'), isTrue);
      expect(text, contains('Ana'));
      expect(text, contains('\r\n'));
      expect(response.headers.value('content-type'), startsWith('text/csv'));
      expect(
        response.headers.value('content-disposition'),
        matches(r'attachment; filename="hoops-demo-roster-.*-\d{8}\.csv"'),
      );
      expect(response.headers.value('cache-control'), 'no-store');
    });

    test('the roster is for the admin and the coach of the team only', () async {
      Future<void> roster(List<String> roles, String team) => ApiTeamsRepository(
        clientFor(roles),
        t,
      ).exportRoster(team, language: 'en');

      await roster(['COACH'], 'team-mini-a');
      await expectLater(roster(['COACH'], 'team-inf-a'), status(403));
      await expectLater(roster(['ASSISTANT_COACH'], 'team-mini-a'), status(403));
      await expectLater(roster(['PARENT'], 'team-mini-a'), status(403));
    });

    test('the academy audit trail is for the admin only', () async {
      final bytes = await ApiAuditRepository(
        clientFor(['ADMIN']),
      ).exportAcademy(t, const AuditQuery(), language: 'en');
      expect(utf8.decode(bytes), contains('member.invited'));
      await expectLater(
        ApiAuditRepository(
          clientFor(['COACH']),
        ).exportAcademy(t, const AuditQuery(), language: 'en'),
        status(403),
      );
    });

    test('the platform audit trail is a CSV too', () async {
      final bytes = await ApiAuditRepository(
        clientFor(['ADMIN']),
      ).exportPlatform(const AuditQuery(), language: 'en');
      expect(bytes, isNotEmpty);
    });
  });
}
