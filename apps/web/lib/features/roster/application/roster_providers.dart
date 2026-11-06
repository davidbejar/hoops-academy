import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/clear_list.dart';
import '../../admin/application/admin_providers.dart';
import '../data/approvals_repository.dart';
import '../data/cases_repository.dart';
import '../data/players_repository.dart';
import '../data/teams_repository.dart';

// ---------------------------------------------------------------- repositories

final teamsRepositoryProvider = Provider<TeamsRepository>(
  (ref) => ApiTeamsRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);
final playersRepositoryProvider = Provider<PlayersRepository>(
  (ref) => ApiPlayersRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);
final approvalsRepositoryProvider = Provider<ApprovalsRepository>(
  (ref) => ApiApprovalsRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);
final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => ApiCasesRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);

// ----------------------------------------------------------------------- teams

/// The season the teams list shows; null = the current season.
class SelectedSeason extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedSeasonIdProvider = NotifierProvider<SelectedSeason, String?>(
  SelectedSeason.new,
);

/// Season in use: the selection, else the current one, else the newest.
final activeSeasonProvider = FutureProvider<api.Season?>((ref) async {
  final seasons = await ref.watch(seasonsProvider.future);
  if (seasons.isEmpty) return null;
  final selected = ref.watch(selectedSeasonIdProvider);
  for (final s in seasons) {
    if (s.id == selected) return s;
  }
  for (final s in seasons) {
    if (s.current) return s;
  }
  return seasons.last;
});

class TeamsNotifier extends AsyncNotifier<List<api.Team>> {
  @override
  Future<List<api.Team>> build() async {
    final season = await ref.watch(activeSeasonProvider.future);
    if (season == null) return const [];
    return ref.watch(teamsRepositoryProvider).list(seasonId: season.id);
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> create({
    required String name,
    String? alias,
    required String ageCategoryId,
    required api.GenderPolicy genderPolicy,
  }) async {
    final season = await ref.read(activeSeasonProvider.future);
    await ref
        .read(teamsRepositoryProvider)
        .create(
          api.CreateTeamRequest(
            (b) => b
              ..seasonId = season!.id
              ..name = name
              ..alias = alias
              ..ageCategoryId = ageCategoryId
              ..genderPolicy = genderPolicy,
          ),
        );
    await _reload();
  }

  Future<void> edit(
    String teamId, {
    required String name,
    String? alias,
    required String ageCategoryId,
    required api.GenderPolicy genderPolicy,
  }) async {
    await ref
        .read(teamsRepositoryProvider)
        .update(
          teamId,
          api.UpdateTeamRequest(
            (b) => b
              ..name = name
              ..alias = alias
              ..ageCategoryId = ageCategoryId
              ..genderPolicy = genderPolicy
              ..clear = clearList({api.UpdateTeamRequestClearEnum.alias: alias}),
          ),
        );
    await _reload();
  }
}

final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<api.Team>>(
  TeamsNotifier.new,
);

class TeamDetail {
  const TeamDetail({
    required this.team,
    required this.roster,
    required this.staff,
  });
  final api.Team team;
  final List<api.TeamPlayer> roster;
  final List<api.TeamStaffMember> staff;
}

class TeamDetailNotifier extends AsyncNotifier<TeamDetail> {
  TeamDetailNotifier(this.teamId);
  final String teamId;

  TeamsRepository get _repo => ref.read(teamsRepositoryProvider);

  @override
  Future<TeamDetail> build() async {
    final repo = ref.watch(teamsRepositoryProvider);
    final r = await Future.wait([
      repo.get(teamId),
      repo.roster(teamId),
      repo.staff(teamId),
    ]);
    return TeamDetail(
      team: r[0] as api.Team,
      roster: r[1] as List<api.TeamPlayer>,
      staff: r[2] as List<api.TeamStaffMember>,
    );
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(teamsProvider); // player counts
  }

  Future<api.EligibilityCheck> check(String playerId) =>
      _repo.checkEligibility(teamId, playerId);

  Future<void> assign(String playerId, {String? jerseyNumber}) async {
    await _repo.assign(teamId, playerId, jerseyNumber: jerseyNumber);
    await _reload();
  }

  Future<void> unassign(String playerId) async {
    await _repo.unassign(teamId, playerId);
    await _reload();
  }

  Future<void> setJersey(String playerId, String? jerseyNumber) async {
    await _repo.setJersey(teamId, playerId, jerseyNumber);
    await _reload();
  }

  Future<void> addStaff(String personId, api.StaffRole role) async {
    await _repo.putStaff(teamId, personId, role);
    await _reload();
  }

  Future<void> removeStaff(String personId) async {
    await _repo.removeStaff(teamId, personId);
    await _reload();
  }
}

final teamDetailProvider =
    AsyncNotifierProvider.family<TeamDetailNotifier, TeamDetail, String>(
      TeamDetailNotifier.new,
    );

// --------------------------------------------------------------------- players

class PlayerFilter {
  const PlayerFilter({
    this.status,
    this.teamId,
    this.categoryId,
    this.query = '',
  });
  final api.PlayerStatus? status;
  final String? teamId;
  final String? categoryId;
  final String query;

  bool get isActive =>
      status != null ||
      teamId != null ||
      categoryId != null ||
      query.isNotEmpty;

  PlayerFilter copyWith({
    api.PlayerStatus? status,
    bool clearStatus = false,
    String? teamId,
    bool clearTeam = false,
    String? categoryId,
    bool clearCategory = false,
    String? query,
  }) => PlayerFilter(
    status: clearStatus ? null : (status ?? this.status),
    teamId: clearTeam ? null : (teamId ?? this.teamId),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    query: query ?? this.query,
  );
}

class PlayerFilterNotifier extends Notifier<PlayerFilter> {
  @override
  PlayerFilter build() => const PlayerFilter();
  void set(PlayerFilter filter) => state = filter;
}

final playerFilterProvider =
    NotifierProvider<PlayerFilterNotifier, PlayerFilter>(
      PlayerFilterNotifier.new,
    );

class PlayersNotifier extends AsyncNotifier<List<api.Player>> {
  @override
  Future<List<api.Player>> build() async {
    final f = ref.watch(playerFilterProvider);
    final players = await ref
        .watch(playersRepositoryProvider)
        .list(status: f.status, teamId: f.teamId, query: f.query);
    // The contract has no category filter on /players: filter client-side.
    if (f.categoryId == null) return players;
    return [
      for (final p in players)
        if (p.naturalCategory?.id == f.categoryId) p,
    ];
  }

  /// Creates a player. Returns the command result so the UI can tell
  /// "created" (APPROVED) from "request filed" (PENDING).
  Future<api.PlayerCommandResult> create(
    api.CreatePlayerRequest request,
  ) async {
    final result = await ref.read(playersRepositoryProvider).create(request);
    ref.invalidateSelf();
    ref.invalidate(approvalsProvider);
    await future;
    return result;
  }
}

final playersProvider =
    AsyncNotifierProvider<PlayersNotifier, List<api.Player>>(
      PlayersNotifier.new,
    );

class PlayerDetailNotifier extends AsyncNotifier<api.Player> {
  PlayerDetailNotifier(this.playerId);
  final String playerId;

  @override
  Future<api.Player> build() =>
      ref.watch(playersRepositoryProvider).get(playerId);

  Future<api.PlayerCommandResult> withdraw({String? reason}) async {
    final result = await ref
        .read(playersRepositoryProvider)
        .withdraw(playerId, reason: reason);
    ref.invalidateSelf();
    ref.invalidate(playersProvider);
    ref.invalidate(approvalsProvider);
    await future;
    return result;
  }

  Future<List<api.EligibleTeam>> eligibleTeams(String seasonId) =>
      ref.read(playersRepositoryProvider).eligibleTeams(playerId, seasonId);

  /// Assign to a team chosen from [eligibleTeams] and refresh.
  Future<void> assignTo(String teamId) async {
    await ref.read(teamsRepositoryProvider).assign(teamId, playerId);
    ref.invalidateSelf();
    ref.invalidate(teamsProvider);
    ref.invalidate(playersProvider);
    await future;
  }
}

final playerDetailProvider =
    AsyncNotifierProvider.family<PlayerDetailNotifier, api.Player, String>(
      PlayerDetailNotifier.new,
    );

// ------------------------------------------------------------------- approvals

class ApprovalsNotifier extends AsyncNotifier<List<api.ApprovalRequest>> {
  @override
  Future<List<api.ApprovalRequest>> build() =>
      ref.watch(approvalsRepositoryProvider).list();

  ApprovalsRepository get _repo => ref.read(approvalsRepositoryProvider);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(playersProvider);
  }

  /// The result carries the temporary password of a login the approval created: the caller shows it once and drops
  /// it; the state only ever holds the password-free list.
  Future<api.ApprovalRequestWithPassword> approve(
    String id, {
    String? note,
  }) async {
    final approved = await _repo.approve(id, note: note);
    await _reload();
    return approved;
  }

  Future<void> reject(String id, {required String note}) async {
    await _repo.reject(id, note: note);
    await _reload();
  }

  Future<void> cancel(String id) async {
    await _repo.cancel(id);
    await _reload();
  }
}

final approvalsProvider =
    AsyncNotifierProvider<ApprovalsNotifier, List<api.ApprovalRequest>>(
      ApprovalsNotifier.new,
    );

// ----------------------------------------------------------------------- cases

class CasesNotifier extends AsyncNotifier<List<api.EligibilityCase>> {
  @override
  Future<List<api.EligibilityCase>> build() => ref
      .watch(casesRepositoryProvider)
      .list(status: api.EligibilityCaseStatus.OPEN);

  /// Eligible teams for the case's player in the active season.
  Future<List<api.EligibleTeam>> eligibleTeamsFor(api.EligibilityCase c) async {
    final season = await ref.read(activeSeasonProvider.future);
    if (season == null) return const [];
    return ref
        .read(playersRepositoryProvider)
        .eligibleTeams(c.player.id, season.id);
  }

  Future<void> _resolve(
    api.EligibilityCase c,
    api.EligibilityCaseResolution resolution, {
    String? targetTeamId,
    String? note,
  }) async {
    await ref
        .read(casesRepositoryProvider)
        .resolve(
          c.id,
          resolution: resolution,
          targetTeamId: targetTeamId,
          note: note,
        );
    ref.invalidateSelf();
    ref.invalidate(playersProvider);
    ref.invalidate(teamsProvider);
    await future;
  }

  Future<void> reassign(
    api.EligibilityCase c,
    String targetTeamId, {
    String? note,
  }) => _resolve(
    c,
    api.EligibilityCaseResolution.REASSIGNED,
    targetTeamId: targetTeamId,
    note: note,
  );

  Future<void> removeFromTeam(api.EligibilityCase c, {String? note}) =>
      _resolve(c, api.EligibilityCaseResolution.REMOVED_FROM_TEAM, note: note);

  Future<void> dismiss(api.EligibilityCase c, {String? note}) =>
      _resolve(c, api.EligibilityCaseResolution.DISMISSED, note: note);
}

final casesProvider =
    AsyncNotifierProvider<CasesNotifier, List<api.EligibilityCase>>(
      CasesNotifier.new,
    );
