import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/api/clear_list.dart';
import '../../../core/errors/app_error.dart';
import '../domain/projector/projector.dart';

/// One line of the roster the setup screen submits.
class RosterInput {
  const RosterInput({
    required this.playerId,
    this.jerseyNumber,
    required this.isStarter,
  });
  final String playerId;
  final String? jerseyNumber;
  final bool isStarter;
}

/// Matches, rosters and statistics of game-service (online operations).
/// Returns the generated models (see WP12 decision) except the roster, which
/// becomes the projector's [RosterPlayer].
abstract class MatchesRepository {
  Future<List<gen.Match>> list({String? teamId, String? seasonId});
  Future<gen.Match> get(String matchId);
  Future<gen.Match> create({
    required String teamId,
    required String opponentName,
    required gen.HomeAway homeAway,
    required DateTime scheduledAt,
    String? venue,
    int? periodCount,
    int? periodMinutes,
  });

  /// Edits the descriptive fields; an empty [venue] is sent in `clear` (ADR-0032).
  Future<gen.Match> update(
    String matchId, {
    required String opponentName,
    required DateTime scheduledAt,
    String? venue,
    gen.HomeAway? homeAway,
    int? periodCount,
    int? periodMinutes,
  });
  Future<gen.Match> start(String matchId);
  Future<gen.Match> finish(String matchId);
  Future<List<RosterPlayer>> roster(String matchId);
  Future<List<RosterPlayer>> replaceRoster(
    String matchId,
    List<RosterInput> entries,
  );
  Future<gen.BoxScore> boxScore(String matchId);
  Future<gen.PlayerSeasonStats> seasonStats(String playerId, String seasonId);
}

class ApiMatchesRepository implements MatchesRepository {
  ApiMatchesRepository(gen.HoopsGameApi api, this._tenant)
    : _matches = api.getMatchesApi(),
      _roster = api.getMatchRosterApi(),
      _stats = api.getStatisticsApi();

  final gen.MatchesApi _matches;
  final gen.MatchRosterApi _roster;
  final gen.StatisticsApi _stats;
  final String _tenant;

  @override
  Future<List<gen.Match>> list({String? teamId, String? seasonId}) => _guard(
    () async => (await _matches.listMatches(
      xTenantId: _tenant,
      teamId: teamId,
      seasonId: seasonId,
      size: 100,
    )).data!.items.toList(),
  );

  @override
  Future<gen.Match> get(String matchId) => _guard(
    () async =>
        (await _matches.getMatch(xTenantId: _tenant, matchId: matchId)).data!,
  );

  @override
  Future<gen.Match> create({
    required String teamId,
    required String opponentName,
    required gen.HomeAway homeAway,
    required DateTime scheduledAt,
    String? venue,
    int? periodCount,
    int? periodMinutes,
  }) => _guard(
    () async => (await _matches.createMatch(
      xTenantId: _tenant,
      createMatchRequest: gen.CreateMatchRequest(
        (b) => b
          ..teamId = teamId
          ..opponentName = opponentName
          ..homeAway = homeAway
          ..scheduledAt = scheduledAt.toUtc()
          ..venue = venue
          ..periodCount = periodCount
          ..periodMinutes = periodMinutes,
      ),
    )).data!,
  );

  @override
  Future<gen.Match> update(
    String matchId, {
    required String opponentName,
    required DateTime scheduledAt,
    String? venue,
    gen.HomeAway? homeAway,
    int? periodCount,
    int? periodMinutes,
  }) => _guard(
    () async => (await _matches.updateMatch(
      xTenantId: _tenant,
      matchId: matchId,
      updateMatchRequest: gen.UpdateMatchRequest(
        (b) => b
          ..opponentName = opponentName
          ..scheduledAt = scheduledAt.toUtc()
          ..homeAway = homeAway
          ..venue = venue
          ..periodCount = periodCount
          ..periodMinutes = periodMinutes
          ..clear = clearList({gen.UpdateMatchRequestClearEnum.venue: venue}),
      ),
    )).data!,
  );

  @override
  Future<gen.Match> start(String matchId) => _guard(
    () async =>
        (await _matches.startMatch(xTenantId: _tenant, matchId: matchId)).data!,
  );

  @override
  Future<gen.Match> finish(String matchId) => _guard(
    () async => (await _matches.finishMatch(
      xTenantId: _tenant,
      matchId: matchId,
    )).data!,
  );

  @override
  Future<List<RosterPlayer>> roster(String matchId) => _guard(
    () async => _toRoster(
      (await _roster.getMatchRoster(
        xTenantId: _tenant,
        matchId: matchId,
      )).data!,
    ),
  );

  @override
  Future<List<RosterPlayer>> replaceRoster(
    String matchId,
    List<RosterInput> entries,
  ) => _guard(() async {
    final request = gen.ReplaceMatchRosterRequest(
      (b) => b.entries = ListBuilder([
        for (final e in entries)
          gen.MatchRosterEntryInput(
            (i) => i
              ..playerId = e.playerId
              ..jerseyNumber = e.jerseyNumber
              ..isStarter = e.isStarter,
          ),
      ]),
    );
    return _toRoster(
      (await _roster.replaceMatchRoster(
        xTenantId: _tenant,
        matchId: matchId,
        replaceMatchRosterRequest: request,
      )).data!,
    );
  });

  @override
  Future<gen.BoxScore> boxScore(String matchId) => _guard(
    () async =>
        (await _stats.getBoxScore(xTenantId: _tenant, matchId: matchId)).data!,
  );

  @override
  Future<gen.PlayerSeasonStats> seasonStats(String playerId, String seasonId) =>
      _guard(
        () async => (await _stats.getPlayerSeasonStats(
          xTenantId: _tenant,
          playerId: playerId,
          seasonId: seasonId,
        )).data!,
      );

  static List<RosterPlayer> _toRoster(gen.MatchRoster r) => [
    for (final e in r.entries)
      RosterPlayer(
        playerId: e.playerId,
        displayName: e.displayName,
        jerseyNumber: e.jerseyNumber,
        isStarter: e.isStarter,
      ),
  ];
}

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw AppError.of(e);
  }
}
