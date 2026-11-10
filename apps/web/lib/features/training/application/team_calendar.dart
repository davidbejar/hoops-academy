import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/export/export_runner.dart' show NothingToExport;
import '../../../core/session/capabilities.dart';
import '../../match/application/match_providers.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/application/season_view.dart';
import 'training_providers.dart';

/// One line of the team calendar: a match (game-service) or a training
/// session (athlete-service).
sealed class CalendarEntry {
  const CalendarEntry();
  String get id;
  String get teamId;
  DateTime get startsAt;
  DateTime get endsAt;
  bool get cancelled;
}

final class MatchEntry extends CalendarEntry {
  const MatchEntry(this.match);
  final gen.Match match;

  @override
  String get id => match.id;
  @override
  String get teamId => match.teamId;
  @override
  DateTime get startsAt => match.scheduledAt;

  /// The scheduled periods; the actual finish is not known in advance.
  @override
  DateTime get endsAt => match.scheduledAt.add(
    Duration(minutes: match.periodCount * match.periodMinutes),
  );
  @override
  bool get cancelled => match.status == gen.MatchStatus.CANCELLED;
}

final class SessionEntry extends CalendarEntry {
  const SessionEntry(this.session);
  final ath.TrainingSession session;

  @override
  String get id => session.id;
  @override
  String get teamId => session.teamId;
  @override
  DateTime get startsAt => session.startsAt;
  @override
  DateTime get endsAt =>
      session.startsAt.add(Duration(minutes: session.durationMinutes));
  @override
  bool get cancelled => session.status == ath.TrainingSessionStatus.CANCELLED;
}

/// The merged calendar and which source could not be read (offline with
/// nothing cached): the export says so instead of passing a gap off as empty.
class TeamCalendar {
  const TeamCalendar(
    this.entries, {
    this.matchesMissing = false,
    this.sessionsMissing = false,
  });
  final List<CalendarEntry> entries;
  final bool matchesMissing;
  final bool sessionsMissing;
}

/// Reads the matches (game) and training sessions (athlete) of the selected
/// season for the calendar export. Matches fall back to the offline cache
/// the list screen fills; sessions have no cache.
class TeamCalendarLoader {
  TeamCalendarLoader(this._ref);
  final Ref _ref;

  Future<TeamCalendar> load({String? teamId}) async {
    final season = await _ref.read(activeSeasonProvider.future);
    if (season == null) throw const NothingToExport();
    final scope = await _scope(teamId);
    final matches = await _matches(scope, season.id);
    final sessions = await _sessions(
      scope,
      toAthDate(season.startsOn.toDateTime()),
      toAthDate(season.endsOn.toDateTime()),
    );
    if (matches.failure != null && sessions.failure != null) {
      throw matches.failure!;
    }
    final entries = <String, CalendarEntry>{
      for (final m in matches.items) 'match-${m.id}': MatchEntry(m),
      for (final s in sessions.items) 'training-${s.id}': SessionEntry(s),
    };
    return TeamCalendar(
      (entries.values.toList())
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
      matchesMissing: matches.failure != null,
      sessionsMissing: sessions.failure != null,
    );
  }

  /// The teams to ask for (null = one unfiltered call): the chosen team, else
  /// as the week view does: all teams for an admin, the staff's own teams for
  /// a coach, everything the server allows for the rest.
  Future<List<String?>> _scope(String? teamId) async {
    if (teamId != null) return [teamId];
    final caps = _ref.read(capabilitiesProvider);
    if (caps.isAdmin) {
      final teams = await _ref.read(teamsProvider.future);
      return teams.isEmpty ? [null] : [for (final t in teams) t.id];
    }
    final staff = _ref.read(viewedPastSeasonProvider) != null
        ? caps.historicStaffTeamIds
        : caps.staffTeamIds;
    return staff.isEmpty ? [null] : staff.toList();
  }

  Future<_Read<gen.Match>> _matches(
    List<String?> scope,
    String seasonId,
  ) async {
    final repo = _ref.read(matchesRepositoryProvider);
    final store = _ref.read(matchStoreProvider);
    final tenant = _ref.read(api.tenantIdProvider);
    await _ref.read(matchOwnerProvider.future);
    final items = <gen.Match>[];
    Object? failure;
    for (final team in scope) {
      try {
        items.addAll(await repo.list(teamId: team, seasonId: seasonId));
      } on Object catch (e) {
        if (!isOfflineError(e)) rethrow;
        final cached = [
          for (final json in await store.matchJsonsForTeam(
            tenantId: tenant,
            teamId: team,
          ))
            decodeMatch(json),
        ].where((m) => m.seasonId == seasonId);
        if (cached.isEmpty) {
          failure = e;
        } else {
          items.addAll(cached);
        }
      }
    }
    return _Read(items, failure);
  }

  Future<_Read<ath.TrainingSession>> _sessions(
    List<String?> scope,
    ath.Date from,
    ath.Date to,
  ) async {
    final repo = _ref.read(trainingRepositoryProvider);
    final items = <ath.TrainingSession>[];
    Object? failure;
    for (final team in scope) {
      try {
        items.addAll(await repo.sessions(teamId: team, from: from, to: to));
      } on Object catch (e) {
        if (!isOfflineError(e)) rethrow;
        failure = e;
      }
    }
    return _Read(items, failure);
  }
}

class _Read<T> {
  const _Read(this.items, this.failure);
  final List<T> items;
  final Object? failure;
}

final teamCalendarLoaderProvider = Provider<TeamCalendarLoader>(
  TeamCalendarLoader.new,
);
