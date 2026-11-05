import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/data/local/match_database.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/match/domain/projector/projection.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import 'fake_game_server.dart';
import 'fake_repos.dart' show Faulty;
import 'fake_timers.dart';

const teamA = 'team-a';

gen.Match gameMatch(
  String id, {
  gen.MatchStatus? status,
  String teamId = teamA,
  String opponent = 'Tigres',
  int team = 0,
  int opponentScore = 0,
  DateTime? at,
}) => gen.Match((b) => b
  ..id = id
  ..teamId = teamId
  ..seasonId = 'season-1'
  ..opponentName = opponent
  ..homeAway = gen.HomeAway.HOME
  ..scheduledAt = at ?? DateTime.utc(2026, 11, 7, 10)
  ..status = status ?? gen.MatchStatus.LIVE
  ..periodCount = 4
  ..periodMinutes = 10
  ..score.team = team
  ..score.opponent = opponentScore
  ..lastServerSeq = 0);

const demoRoster = [
  RosterPlayer(playerId: 'p1', displayName: 'Ana Ruiz', jerseyNumber: '4', isStarter: true),
  RosterPlayer(playerId: 'p2', displayName: 'Bo Gil', jerseyNumber: '5', isStarter: true),
  RosterPlayer(playerId: 'p3', displayName: 'Cai Soto', jerseyNumber: '6', isStarter: true),
  RosterPlayer(playerId: 'p4', displayName: 'Dee Mar', jerseyNumber: '7', isStarter: true),
  RosterPlayer(playerId: 'p5', displayName: 'Eli Paz', jerseyNumber: '8', isStarter: true),
  RosterPlayer(playerId: 'p6', displayName: 'Fay Rey', jerseyNumber: '9', isStarter: false),
  RosterPlayer(playerId: 'p7', displayName: 'Gus Luz', jerseyNumber: '10', isStarter: false),
];

class FakeMatchesRepository with Faulty implements MatchesRepository {
  FakeMatchesRepository({List<gen.Match>? matches, Map<String, List<RosterPlayer>>? rosters, this.seasonStatsResult})
    : matches = matches ?? [],
      rosters = rosters ?? {};

  final List<gen.Match> matches;
  final Map<String, List<RosterPlayer>> rosters;
  gen.PlayerSeasonStats? seasonStatsResult;
  final List<List<RosterInput>> replacedRosters = [];
  String? lastSeasonStatsSeason;

  gen.Match _get(String id) => matches.firstWhere((m) => m.id == id);
  void _put(gen.Match m) => matches[matches.indexWhere((x) => x.id == m.id)] = m;

  @override
  Future<List<gen.Match>> list({String? teamId, String? seasonId}) =>
      run('list', () => [for (final m in matches) if (teamId == null || m.teamId == teamId) m]);
  @override
  Future<gen.Match> get(String matchId) => run('get', () => _get(matchId));
  @override
  Future<gen.Match> create({
    required String teamId,
    required String opponentName,
    required gen.HomeAway homeAway,
    required DateTime scheduledAt,
    String? venue,
    int? periodCount,
    int? periodMinutes,
  }) => run('create', () {
    final m = gameMatch('new-${matches.length}', status: gen.MatchStatus.SCHEDULED, teamId: teamId, opponent: opponentName, at: scheduledAt.toUtc());
    matches.add(m);
    return m;
  });
  @override
  Future<gen.Match> start(String matchId) => run('start', () {
    final m = _get(matchId).rebuild((b) => b.status = gen.MatchStatus.LIVE);
    _put(m);
    return m;
  });
  @override
  Future<gen.Match> finish(String matchId) => run('finish', () {
    final m = _get(matchId).rebuild((b) => b.status = gen.MatchStatus.FINISHED);
    _put(m);
    return m;
  });
  @override
  Future<List<RosterPlayer>> roster(String matchId) => run('roster', () => [...?rosters[matchId]]);
  @override
  Future<List<RosterPlayer>> replaceRoster(String matchId, List<RosterInput> entries) => run('replaceRoster', () {
    replacedRosters.add(entries);
    return rosters[matchId] = [
      for (final e in entries)
        RosterPlayer(playerId: e.playerId, displayName: e.playerId, jerseyNumber: e.jerseyNumber, isStarter: e.isStarter),
    ];
  });
  /// `GET box-score`; FakeGame answers from its server's stored events.
  gen.BoxScore Function(String matchId)? boxScoreOf;

  @override
  Future<gen.BoxScore> boxScore(String matchId) => run('boxScore', () => boxScoreOf!(matchId));
  @override
  Future<gen.PlayerSeasonStats> seasonStats(String playerId, String seasonId) => run('seasonStats', () {
    lastSeasonStatsSeason = seasonId;
    return seasonStatsResult!;
  });
}

/// In-memory game side for widget / provider tests: repository fake, the
/// contract fake server for events, a Drift in-memory store, manual timers.
class FakeGame {
  FakeGame({FakeMatchesRepository? matches, FakeGameServer? server})
    : matches = (() {
        // Every test owns a fresh in-memory database.
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        return matches ?? FakeMatchesRepository();
      })(),
      server = server ?? FakeGameServer(roster: demoRoster),
      store = MatchStore(MatchDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true))) {
    this.matches.boxScoreOf ??= (id) => genBoxScore(id, this.server.boxScore(id));
  }

  final FakeMatchesRepository matches;
  final FakeGameServer server;
  final MatchStore store;
  final timers = FakeTimers();

  List<Override> get overrides => [
    matchStoreProvider.overrideWithValue(store),
    matchesRepositoryProvider.overrideWithValue(matches),
    eventsRemoteProvider.overrideWithValue(server),
    syncTimersProvider.overrideWithValue(timers),
  ];
}

/// The server's box score of a projection, as the contract's `BoxScore`
/// (team figures; player lines are not needed by the app).
gen.BoxScore genBoxScore(String matchId, Projection p) {
  Map<String, Object?> line(StatLine s) => {
    'points': s.points, 'fg1Made': s.fg1Made, 'fg1Attempted': s.fg1Attempted, 'fg2Made': s.fg2Made,
    'fg2Attempted': s.fg2Attempted, 'fg3Made': s.fg3Made, 'fg3Attempted': s.fg3Attempted, 'assists': s.assists,
    'offensiveRebounds': s.offensiveRebounds, 'defensiveRebounds': s.defensiveRebounds, 'turnovers': s.turnovers,
    'steals': s.steals, 'blocks': s.blocks, 'personalFouls': s.personalFouls, 'technicalFouls': s.technicalFouls,
    'unsportsmanlikeFouls': s.unsportsmanlikeFouls, 'secondsPlayed': s.secondsPlayed,
  };
  return gen.standardSerializers.deserializeWith(gen.BoxScore.serializer, {
    'matchId': matchId,
    'status': 'LIVE',
    'score': {'team': p.summary.teamScore, 'opponent': p.summary.opponentScore},
    'periodScores': [for (final s in p.summary.periodScores) {'period': s.period, 'team': s.team, 'opponent': s.opponent}],
    'teamTotals': line(p.teamTotals),
    'players': <Object?>[],
    'warnings': <Object?>[],
    'lastServerSeq': p.summary.lastServerSeq,
  })!;
}
