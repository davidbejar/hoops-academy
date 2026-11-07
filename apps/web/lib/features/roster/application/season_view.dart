import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/session/session.dart';
import '../../../core/session/session_providers.dart';
import '../../me/domain/current_user.dart';
import '../../tenant/application/tenant_providers.dart';
import 'roster_providers.dart';

/// Season history (WP80, ADR-0042): the season on screen comes from `selectedSeasonIdProvider`; a season that has
/// ended is read-only for everybody.

/// The past season the person picked in the season selector; null while the current one is on screen.
final viewedPastSeasonProvider = Provider<api.Season?>((ref) {
  if (ref.watch(selectedSeasonIdProvider) == null) return null;
  final season = ref.watch(activeSeasonProvider).value;
  if (season == null) return null;
  final today = ref.watch(tenantZoneProvider).today(DateTime.now());
  return season.endsOn.toDateTime().isBefore(today) ? season : null;
});

/// A past season is on screen: write affordances are off.
final viewingPastSeasonProvider = Provider<bool>(
  (ref) => ref.watch(viewedPastSeasonProvider) != null,
);

/// Ids of the academy's teams whose season has ended, for the admin (the coach's own current teams never include
/// one). Empty while loading or when the list cannot be read: the server still answers 409 `SEASON_ENDED`.
final endedTeamIdsProvider = Provider<Set<String>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! Ready || !session.roles.contains(TenantRole.admin)) {
    return const {};
  }
  return ref.watch(_endedTeamsProvider).value ?? const {};
});

final _endedTeamsProvider = FutureProvider<Set<String>>((ref) async {
  try {
    final teams = await ref.watch(teamsRepositoryProvider).list();
    return {
      for (final t in teams)
        if (t.seasonEnded) t.id,
    };
  } on Object {
    return const {};
  }
});

/// The caller's own teams of ended seasons (the "Past seasons" group); empty without history.
final historicTeamsProvider = FutureProvider<List<api.Team>>((ref) async {
  final session = ref.watch(sessionProvider);
  final history = session is Ready
      ? session.membership?.historicStaffTeamIds ?? const <String>{}
      : const <String>{};
  if (history.isEmpty) return const [];
  return ref.watch(teamsRepositoryProvider).historicStaffTeams();
});
