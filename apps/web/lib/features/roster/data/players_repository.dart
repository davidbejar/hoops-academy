import '../../../core/api/api.dart' as api;
import '../../../core/api/clear_list.dart';

/// Players (`/api/core/players*`).
abstract class PlayersRepository {
  Future<List<api.Player>> list({
    api.PlayerStatus? status,
    String? teamId,
    String? query,
  });
  Future<api.Player> get(String playerId);

  /// ADMIN: created ACTIVE (approval APPROVED). COACH: PENDING_APPROVAL (approval PENDING).
  Future<api.PlayerCommandResult> create(api.CreatePlayerRequest request);
  Future<api.PlayerCommandResult> withdraw(String playerId, {String? reason});
  Future<List<api.EligibleTeam>> eligibleTeams(
    String playerId,
    String seasonId,
  );

  /// The number a player would like (core 3.5.0); null removes it (named in `clear`, ADR-0032).
  Future<api.Player> setPreferredJersey(String playerId, String? number);
}

class ApiPlayersRepository implements PlayersRepository {
  ApiPlayersRepository(api.HoopsCoreApi client, this._t)
    : _api = client.getPlayersApi();

  final api.PlayersApi _api;
  final String _t;

  @override
  Future<List<api.Player>> list({
    api.PlayerStatus? status,
    String? teamId,
    String? query,
  }) async => (await _api.listPlayers(
    xTenantId: _t,
    status: status,
    teamId: teamId,
    q: (query == null || query.trim().isEmpty) ? null : query.trim(),
    size: 100,
  )).data!.items.toList();

  @override
  Future<api.Player> get(String playerId) async =>
      (await _api.getPlayer(xTenantId: _t, playerId: playerId)).data!;

  @override
  Future<api.PlayerCommandResult> create(
    api.CreatePlayerRequest request,
  ) async => (await _api.createPlayer(
    xTenantId: _t,
    createPlayerRequest: request,
  )).data!;

  @override
  Future<api.PlayerCommandResult> withdraw(
    String playerId, {
    String? reason,
  }) async => (await _api.withdrawPlayer(
    xTenantId: _t,
    playerId: playerId,
    withdrawPlayerRequest: api.WithdrawPlayerRequest((b) => b.reason = reason),
  )).data!;

  @override
  Future<List<api.EligibleTeam>> eligibleTeams(
    String playerId,
    String seasonId,
  ) async => (await _api.listEligibleTeams(
    xTenantId: _t,
    playerId: playerId,
    seasonId: seasonId,
  )).data!.toList();

  @override
  Future<api.Player> setPreferredJersey(
    String playerId,
    String? number,
  ) async => (await _api.updatePlayer(
    xTenantId: _t,
    playerId: playerId,
    updatePlayerRequest: api.UpdatePlayerRequest(
      (b) => b
        ..preferredJerseyNumber = number
        ..clear = clearList({
          api.UpdatePlayerRequestClearEnum.preferredJerseyNumber: number,
        }),
    ),
  )).data!;
}
