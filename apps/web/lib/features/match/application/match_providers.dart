import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/api/api.dart' show tenantIdProvider;
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/http/dio_provider.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_providers.dart';
import '../data/api_events_remote.dart';
import '../data/events_remote.dart';
import '../data/local/connection/connection.dart';
import '../data/local/match_database.dart';
import '../data/local/match_store.dart';
import '../data/matches_repository.dart';
import 'sync/sync_worker.dart';

// ------------------------------------------------------------------ plumbing

/// The offline store; one database per app run (IndexedDB on the web).
final matchStoreProvider = Provider<MatchStore>((ref) {
  final store = MatchStore(MatchDatabase(openMatchConnection()));
  ref.onDispose(store.close);
  return store;
});

final gameApiProvider = Provider<gen.HoopsGameApi>(
  (ref) => gen.HoopsGameApi(dio: ref.watch(dioProvider), interceptors: const []),
);

final matchesRepositoryProvider = Provider<MatchesRepository>(
  (ref) => ApiMatchesRepository(ref.watch(gameApiProvider), ref.watch(tenantIdProvider)),
);

final eventsRemoteProvider = Provider<EventsRemote>(
  (ref) => ApiEventsRemote(ref.watch(gameApiProvider), ref.watch(tenantIdProvider)),
);

final syncTimersProvider = Provider<SyncTimers>((ref) => const RealSyncTimers());

/// Signed-in person in the active academy (null: nothing is synced).
final syncScopeProvider = Provider<SyncScope?>((ref) {
  final session = ref.watch(sessionProvider);
  final m = session is Ready ? session.membership : null;
  final person = m?.personId;
  if (m == null || person == null) return null;
  return SyncScope(tenantId: m.tenantId, personId: person);
});

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final worker = SyncWorker(
    store: ref.watch(matchStoreProvider),
    remote: ref.watch(eventsRemoteProvider),
    scope: () => ref.read(syncScopeProvider),
    timers: ref.watch(syncTimersProvider),
  );
  ref.onDispose(worker.dispose);
  return worker;
});

/// Triggers of the sync worker while the match module is in use:
/// connectivity regained, sign-in completed, app resumed. Read (watched) by
/// the match screens; the worker itself stays free of Flutter bindings.
final syncTriggersProvider = Provider<void>((ref) {
  final worker = ref.watch(syncWorkerProvider);
  ref.listen<AsyncValue<bool>>(onlineProvider, (prev, next) {
    if (next.value == true && prev?.value != true) unawaited(worker.onConnectivityChanged(online: true));
  });
  ref.listen<AuthStatus>(authStatusProvider, (prev, next) {
    if (next == AuthStatus.authenticated && prev != AuthStatus.authenticated) unawaited(worker.onAuthenticated());
  });
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(worker.onResumed()));
  ref.onDispose(lifecycle.dispose);
  unawaited(worker.syncNow());
});

/// Network-ish failures for which cached data is shown instead.
bool isOfflineError(Object e) {
  final kind = AppError.of(e).kind;
  return kind == AppErrorKind.network || kind == AppErrorKind.timeout || kind == AppErrorKind.server;
}

String encodeMatch(gen.Match m) => jsonEncode(gen.standardSerializers.serializeWith(gen.Match.serializer, m));

gen.Match decodeMatch(String json) =>
    gen.standardSerializers.deserializeWith(gen.Match.serializer, jsonDecode(json))!;

// --------------------------------------------------------------- match list

/// Team filter of the match list (null = all teams the caller can see).
class MatchTeamFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? teamId) => state = teamId;
}

final matchTeamFilterProvider = NotifierProvider<MatchTeamFilter, String?>(MatchTeamFilter.new);

class MatchList {
  const MatchList(this.matches, {this.fromCache = false});
  final List<gen.Match> matches;
  final bool fromCache;
}

/// Matches by team (scheduledAt descending); cached for offline use.
class MatchListNotifier extends AsyncNotifier<MatchList> {
  @override
  Future<MatchList> build() async {
    final team = ref.watch(matchTeamFilterProvider);
    final store = ref.watch(matchStoreProvider);
    final tenant = ref.watch(tenantIdProvider);
    try {
      final list = await ref.watch(matchesRepositoryProvider).list(teamId: team);
      for (final m in list) {
        await store.saveMatchJson(tenantId: tenant, matchId: m.id, teamId: m.teamId, json: encodeMatch(m));
      }
      return MatchList(list);
    } on Object catch (e) {
      if (!isOfflineError(e)) rethrow;
      final cached = await store.matchJsonsForTeam(tenantId: tenant, teamId: team);
      if (cached.isEmpty) rethrow;
      final list = cached.map(decodeMatch).toList()..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return MatchList(list, fromCache: true);
    }
  }

  Future<gen.Match> create({
    required String teamId,
    required String opponentName,
    required gen.HomeAway homeAway,
    required DateTime scheduledAt,
  }) async {
    final m = await ref.read(matchesRepositoryProvider).create(
      teamId: teamId, opponentName: opponentName, homeAway: homeAway, scheduledAt: scheduledAt,
    );
    ref.invalidateSelf();
    return m;
  }
}

final matchListProvider = AsyncNotifierProvider<MatchListNotifier, MatchList>(MatchListNotifier.new);

/// Unsynced events of the caller over all matches (banner on the list).
final unsyncedCountProvider = StreamProvider<int>((ref) {
  final scope = ref.watch(syncScopeProvider);
  if (scope == null) return Stream.value(0);
  return ref.watch(matchStoreProvider).watchUnsyncedCount(tenantId: scope.tenantId, personId: scope.personId);
});
