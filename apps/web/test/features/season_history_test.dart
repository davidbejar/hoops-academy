import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/core/ui/app_error_view.dart';
import 'package:hoops_app/features/match/presentation/match_labels.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/roster/application/roster_providers.dart'
    show selectedSeasonIdProvider;
import 'package:hoops_app/l10n/gen/app_localizations_es.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../support/core_fixtures.dart';
import '../support/fake_athlete.dart';
import '../support/fake_game.dart';
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';

/// WP80 / ADR-0042 on the web: past seasons are readable (selector), never editable (actions hidden), the server's
/// 409 `SEASON_ENDED` is worded, an offline event of an ended season is a final rejection.
const _past = 'season-old';
const _tOld = 'team-old';
const _tNew = 'team-new';

final _l = AppLocalizationsEs();

FakeCore _core() => FakeCore(
  seasons: FakeSeasonsRepository([
    season(_past, '2025/26', endsOn: api.Date(2026, 6, 30)),
    season(seasonId, '2026/27', current: true),
  ]),
  teams: FakeTeamsRepository(
    teams: [
      team(_tOld, 'Mini A 25', sid: _past, seasonEnded: true),
      team(_tNew, 'Mini A'),
    ],
    rosters: {
      _tOld: [teamPlayer(_tOld, 'p1', 'Ana Ruiz')],
      _tNew: [teamPlayer(_tNew, 'p1', 'Ana Ruiz')],
    },
  ),
);

FakeGame _game() => FakeGame(
  matches: FakeMatchesRepository(
    matches: [
      gameMatch(
        'm-old',
        teamId: _tOld,
        seasonId: _past,
        status: gen.MatchStatus.FINISHED,
        opponent: 'Lobos',
      ),
      gameMatch(
        'm-new',
        teamId: _tNew,
        seasonId: seasonId,
        status: gen.MatchStatus.SCHEDULED,
        opponent: 'Osos',
      ),
    ],
    rosters: {'m-old': demoRoster, 'm-new': demoRoster},
  ),
);

DioException _problem(int status, String code) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: {'status': status, 'code': code, 'detail': 'English detail'},
    ),
  );
}

void main() {
  group('capabilities of a past season', () {
    const admin = Capabilities(
      roles: {TenantRole.admin},
      endedTeamIds: {_tOld},
    );
    const coach = Capabilities(
      roles: {TenantRole.coach},
      staffTeamIds: {_tNew},
      historicStaffTeamIds: {_tOld},
      endedTeamIds: {_tOld},
    );

    test('nobody writes on an ended team, the admin included', () {
      for (final c in [admin, coach]) {
        expect(c.canRunMatch(_tOld), isFalse);
        expect(c.canEditRoster(_tOld), isFalse);
        expect(c.canManageTraining(_tOld), isFalse);
        expect(c.canManageTeam(_tOld), isFalse);
      }
      expect(admin.canRunMatch(_tNew), isTrue);
      expect(coach.canManageTraining(_tNew), isTrue);
      expect(admin.canManageTeam(_tNew), isTrue);
    });

    test('reading the attendance sheet: admin, staff and former staff', () {
      expect(admin.canReadTraining(_tOld), isTrue);
      expect(coach.canReadTraining(_tOld), isTrue);
      expect(coach.canReadTraining('other'), isFalse);
    });

    test('a past season on screen turns every health write off', () {
      const viewing = Capabilities(
        roles: {TenantRole.admin},
        viewingPastSeason: true,
      );
      expect(viewing.canWriteHealth('p1'), isFalse);
      expect(viewing.canEnterTestResults, isFalse);
      expect(viewing.canCreateMatches, isFalse);
      expect(viewing.canManageAnyTraining, isFalse);
    });

    test('the selector is for an admin or a coach with history', () {
      expect(admin.canBrowseSeasons, isTrue);
      expect(coach.canBrowseSeasons, isTrue);
      expect(
        const Capabilities(
          roles: {TenantRole.coach},
          staffTeamIds: {_tNew},
        ).canBrowseSeasons,
        isFalse,
      );
      expect(
        const Capabilities(roles: {TenantRole.parent}).canBrowseSeasons,
        isFalse,
      );
    });
  });

  group('words for the server answer', () {
    test('409 SEASON_ENDED is worded, never the server text', () {
      final e = AppError.fromDioException(_problem(409, 'SEASON_ENDED'));
      expect(e.message(_l), _l.errorSeasonEnded);
      expect(e.message(_l), isNot(contains('English')));
    });

    test('another 409 keeps the generic conflict text', () {
      final e = AppError.fromDioException(_problem(409, 'EMAIL_TAKEN'));
      expect(e.message(_l), _l.errorConflict);
    });

    test('an offline event refused for an ended season says so', () {
      expect(reasonLabel(_l, 'SEASON_ENDED'), _l.matchReasonSeasonEnded);
      expect(_l.matchReasonSeasonEnded, isNot(_l.matchReasonOther));
    });
  });

  group('matches of a past season', () {
    testWidgets(
      'admin: no edit on a match of an ended team, edit on the rest',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: _core(),
          game: _game(),
          location: '/matches',
          size: const Size(360, 1400),
        );
        expect(find.byKey(const Key('match-m-old')), findsOneWidget);
        expect(find.byKey(const Key('match-edit-m-old')), findsNothing);
        expect(find.byKey(const Key('match-edit-m-new')), findsOneWidget);
      },
    );

    testWidgets('the selector switches the list to the past season', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _core(),
        game: _game(),
        location: '/matches',
        size: const Size(360, 1400),
      );
      expect(find.byKey(const Key('season-bar')), findsOneWidget);
      expect(find.byKey(const Key('past-season-banner')), findsNothing);
      await tapKey(tester, 'season-bar');
      await tester.tap(find.text('2025/26').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('match-m-old')), findsOneWidget);
      expect(find.byKey(const Key('match-m-new')), findsNothing);
      expect(find.byKey(const Key('past-season-banner')), findsOneWidget);
      expect(find.byKey(const Key('match-new')), findsNothing);
    });

    testWidgets('a coach with no history has no selector', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {_tNew},
        core: _core(),
        game: _game(),
        location: '/matches',
        size: const Size(360, 1400),
      );
      expect(find.byKey(const Key('season-bar')), findsNothing);
    });

    testWidgets('a coach with history has the selector and reads the past', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {_tNew},
        historicStaffTeamIds: {_tOld},
        core: _core(),
        game: _game(),
        location: '/matches',
        size: const Size(360, 1400),
      );
      expect(find.byKey(const Key('season-bar')), findsOneWidget);
      await tapKey(tester, 'season-bar');
      await tester.tap(find.text('2025/26').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('match-m-old')), findsOneWidget);
      expect(find.byKey(const Key('match-edit-m-old')), findsNothing);
    });

    testWidgets('a parent never sees the selector', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: _core(),
        game: _game(),
        location: '/matches',
        size: const Size(360, 1400),
      );
      expect(find.byKey(const Key('season-bar')), findsNothing);
    });
  });

  group('teams of past seasons', () {
    testWidgets('an admin opens an ended team: read only, no edit, no assign', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _core(),
        location: '/teams/$_tOld',
      );
      expect(find.byKey(const Key('read-only')), findsOneWidget);
      expect(find.byKey(const Key('team-edit')), findsNothing);
      expect(find.byKey(const Key('roster-assign')), findsNothing);
      expect(find.byKey(const Key('staff-add')), findsNothing);
    });

    testWidgets('the same admin edits a team of the current season', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _core(),
        location: '/teams/$_tNew',
      );
      expect(find.byKey(const Key('team-edit')), findsOneWidget);
      expect(find.byKey(const Key('roster-assign')), findsOneWidget);
    });

    testWidgets('a coach sees the own past teams in a "Past seasons" group', (
      tester,
    ) async {
      final core = _core();
      core.teams.historicStaffIds.add(_tOld);
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {_tNew},
        historicStaffTeamIds: {_tOld},
        core: core,
        location: '/teams',
        size: const Size(360, 1400),
      );
      expect(find.text('Temporadas anteriores'), findsOneWidget);
      expect(find.byKey(const Key('past-team-$_tOld')), findsOneWidget);
      expect(find.byKey(const Key('team-$_tNew')), findsOneWidget);
    });

    testWidgets('no group without history', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {_tNew},
        core: _core(),
        location: '/teams',
        size: const Size(360, 1400),
      );
      expect(find.text('Temporadas anteriores'), findsNothing);
    });
  });

  group('training of a past season', () {
    FakeAthlete athlete() => FakeAthlete(
      training: FakeTrainingRepository(
        sessions: [session('s-old', teamId: _tOld, day: DateTime(2026, 5, 4))],
      ),
    );

    testWidgets('an admin reads the sheet of an ended team, cannot change it', (
      tester,
    ) async {
      final a = athlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _core(),
        athlete: a,
        location: '/training/session/s-old',
        size: const Size(360, 1400),
      );
      expect(a.training.calls, contains('attendance'));
      expect(find.byKey(const Key('session-edit')), findsNothing);
      expect(find.byKey(const Key('session-cancel')), findsNothing);
      expect(find.byKey(const Key('attendance-save')), findsNothing);
    });
  });

  group('health of a past season', () {
    testWidgets('with a past season on screen, no health write is offered', (
      tester,
    ) async {
      final h = await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _core(),
        athlete: FakeAthlete(),
        location: '/players/p1/health',
        size: const Size(360, 1400),
      );
      expect(find.byKey(const Key('injury-new')), findsOneWidget);
      h.container.read(selectedSeasonIdProvider.notifier).select(_past);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('injury-new')), findsNothing);
      expect(find.byKey(const Key('past-season-banner')), findsOneWidget);
    });
  });
}
