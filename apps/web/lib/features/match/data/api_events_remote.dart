import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/errors/app_error.dart';
import '../domain/match_event.dart';
import '../domain/pending_event.dart';
import 'event_codec.dart';
import 'events_remote.dart';

/// [EventsRemote] over the generated game-service client.
class ApiEventsRemote implements EventsRemote {
  ApiEventsRemote(gen.HoopsGameApi api, this._tenantId) : _api = api.getMatchEventsApi();

  final gen.MatchEventsApi _api;
  final String _tenantId;

  @override
  Future<BatchOutcome> submit(String matchId, List<MatchEvent> events) => _guard(() async {
    final batch = gen.MatchEventBatch((b) => b.events = ListBuilder(events.map(EventCodec.toApi)));
    final res = (await _api.submitMatchEvents(xTenantId: _tenantId, matchId: matchId, matchEventBatch: batch)).data!;
    return BatchOutcome(
      lastServerSeq: res.lastServerSeq,
      results: [
        for (final r in res.results)
          switch (r.status) {
            gen.MatchEventResultStatus.ACCEPTED => EventResult.accepted(r.eventId, r.serverSeq ?? 0),
            gen.MatchEventResultStatus.DUPLICATE => EventResult.duplicate(r.eventId, r.serverSeq ?? 0),
            _ => EventResult.rejected(r.eventId, r.reason?.name ?? 'UNKNOWN'),
          },
      ],
    );
  });

  @override
  Future<FeedPage> feed(String matchId, {required int after, int limit = 500}) => _guard(() async {
    final res = (await _api.listMatchEvents(xTenantId: _tenantId, matchId: matchId, after: after, limit: limit)).data!;
    return FeedPage(
      lastServerSeq: res.lastServerSeq,
      hasMore: res.hasMore,
      events: [
        for (final s in res.events)
          StoredEvent(
            event: EventCodec.fromApi(s.event),
            serverSeq: s.serverSeq,
            recordedByPersonId: s.recordedBy.personId,
            recordedByName: s.recordedBy.displayName,
            voidedByEventId: s.voidedByEventId,
          ),
      ],
    );
  });
}

/// Rethrows transport failures as [AppError] (the app's Dio already maps
/// Problem+JSON; plain Dio instances in tests do not).
Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw AppError.of(e);
  }
}
