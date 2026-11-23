import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/health/data/fitness_repository.dart';
import 'package:hoops_app/features/health/data/health_repository.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/platform/data/academy_request_repository.dart';
import 'package:hoops_app/features/platform/data/platform_repository.dart';
import 'package:hoops_app/features/roster/data/approvals_repository.dart';
import 'package:hoops_app/features/roster/data/cases_repository.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';
import 'package:hoops_app/features/training/data/plans_repository.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../support/core_fixtures.dart';
import '../support/server_pages.dart';

/// Lists a screen shows whole read every page (WEB-03, ADR-0061): the server
/// serves at most 200 items a page, so a list of 450 needs three requests.
/// Each repository runs over the demo mock's item shapes, served 450 times by a
/// pager that behaves like the services.
void main() {
  const t = mockTenantAId;
  const count = 450;

  late ServerPagesAdapter server;
  Dio dio() => Dio(
    BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}),
  )..httpClientAdapter = server;
  api.HoopsCoreApi core() => api.HoopsCoreApi(dio: dio(), interceptors: []);
  ath.HoopsAthleteApi athlete() =>
      ath.HoopsAthleteApi(dio: dio(), interceptors: []);

  setUp(() {
    server = ServerPagesAdapter(
      count: count,
      inner: MockApiAdapter(roles: ['ADMIN', 'COACH'], superAdmin: true),
    );
  });

  final cases = <String, Future<List<Object?>> Function()>{
    'players': () => ApiPlayersRepository(core(), t).list(),
    'teams': () => ApiTeamsRepository(core(), t).list(),
    'approval requests': () => ApiApprovalsRepository(core(), t).list(),
    'eligibility cases': () => ApiCasesRepository(core(), t).list(),
    'members': () => ApiMembersRepository(core(), t).list(),
    'guardian links': () => ApiMembersRepository(core(), t).guardianLinks(),
    'training plans': () =>
        ApiPlansRepository(athlete(), t).plans(templates: false),
    'plan assignments': () => ApiPlansRepository(athlete(), t).assignments(),
    'plan completions': () => ApiPlansRepository(athlete(), t).completions(),
    'training sessions': () => ApiTrainingRepository(
      athlete(),
      t,
    ).sessions(from: ath.Date(2000, 1, 1), to: ath.Date(2100, 1, 1)),
    'planned absences': () => ApiTrainingRepository(athlete(), t).absences(),
    'injuries': () => ApiHealthRepository(athlete(), t).injuries(),
    'physical test results': () => ApiFitnessRepository(athlete(), t).results(),
    'matches': () => ApiMatchesRepository(
      gen.HoopsGameApi(dio: dio(), interceptors: []),
      t,
    ).list(),
    'tenants': () => ApiPlatformRepository(core()).tenants(),
    'tenant admins': () => ApiPlatformRepository(core()).admins(t),
    'academy requests': () =>
        ApiAcademyRequestRepository(core())
            .list(api.AcademyRequestStatus.PENDING),
  };

  for (final MapEntry(key: name, value: read) in cases.entries) {
    test('$name: every page, never above the server\'s 200', () async {
      final all = await read();
      expect(all, hasLength(count));
      expect(server.served.map((p) => p.size), everyElement(200));
      expect(server.served.map((p) => p.page), [0, 1, 2]);
    });
  }

  test('teams the user staffed in ended seasons: every page', () async {
    final ended = team('t', 'Mini A', seasonEnded: true);
    server = ServerPagesAdapter(
      count: count,
      template:
          (api.standardSerializers.serializeWith(api.Team.serializer, ended)!
                  as Map)
              .cast(),
    );
    final teams = await ApiTeamsRepository(core(), t).historicStaffTeams();
    expect(teams, hasLength(count));
  });
}
