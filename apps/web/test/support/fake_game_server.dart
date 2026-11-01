import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/match/data/events_remote.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';
import 'package:hoops_app/features/match/domain/projector/projection.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';

/// In-memory game-service for sync tests, following the contract and
/// ADR-0014: idempotent by id, `(deviceId, clientSeq)` unique per match,
/// per-event results, feed by serverSeq, box score = projection of the
/// stored set.
class FakeGameServer implements EventsRemote {
  FakeGameServer({this.rules = const MatchRules(periodCount: 4, periodMinutes: 10), this.roster = const []});

  final MatchRules rules;
  List<RosterPlayer> roster;

  /// Network down: every call fails before reaching the server.
  bool offline = false;

  /// Token rejected (refresh failed): every call is a 401.
  bool unauthorized = false;

  /// The server stores the batch but the response is lost.
  bool dropResponses = false;

  /// Rule deciding a rejection reason (null = accept).
  String? Function(MatchEvent event)? rejectWhen;

  final Map<String, Map<String, StoredEvent>> _byMatch = {};
  int _seq = 0;
  final List<int> batchSizes = [];
  final List<List<int>> batchClientSeqs = [];
  int feedCalls = 0;

  /// Stores events recorded by other devices (they arrive via the feed).
  void preload(String matchId, Iterable<RecordedEvent> events, {String personId = 'other-scorer'}) {
    final match = _byMatch.putIfAbsent(matchId, () => {});
    for (final e in events) {
      final seq = e.serverSeq ?? ++_seq;
      if (seq > _seq) _seq = seq;
      match[e.event.id] = StoredEvent(event: e.event, serverSeq: seq, recordedByPersonId: personId);
    }
  }

  List<StoredEvent> stored(String matchId) =>
      (_byMatch[matchId]?.values.toList() ?? [])..sort((a, b) => a.serverSeq.compareTo(b.serverSeq));

  Projection boxScore(String matchId) => project(rules, roster, [
    for (final s in stored(matchId)) RecordedEvent(s.event, serverSeq: s.serverSeq),
  ]);

  void _gate() {
    if (offline) throw const AppError(kind: AppErrorKind.network);
    if (unauthorized) throw const AppError(kind: AppErrorKind.unauthorized, status: 401);
  }

  @override
  Future<BatchOutcome> submit(String matchId, List<MatchEvent> events) async {
    _gate();
    if (events.isEmpty || events.length > 500) {
      throw const AppError(kind: AppErrorKind.validation, status: 400);
    }
    batchSizes.add(events.length);
    batchClientSeqs.add([for (final e in events) e.meta.clientSeq]);
    final match = _byMatch.putIfAbsent(matchId, () => {});
    final results = <EventResult>[];
    for (final e in events) {
      final known = match[e.id];
      if (known != null) {
        results.add(EventResult.duplicate(e.id, known.serverSeq));
        continue;
      }
      final reason = rejectWhen?.call(e);
      if (reason != null) {
        results.add(EventResult.rejected(e.id, reason));
        continue;
      }
      final conflict = match.values.any(
        (s) => s.event.meta.deviceId == e.meta.deviceId && s.event.meta.clientSeq == e.meta.clientSeq,
      );
      if (conflict) {
        results.add(EventResult.rejected(e.id, 'CLIENT_SEQ_CONFLICT'));
        continue;
      }
      final seq = ++_seq;
      match[e.id] = StoredEvent(event: e, serverSeq: seq, recordedByPersonId: 'person-me');
      results.add(EventResult.accepted(e.id, seq));
    }
    if (dropResponses) throw const AppError(kind: AppErrorKind.network);
    return BatchOutcome(results: results, lastServerSeq: _seq);
  }

  @override
  Future<FeedPage> feed(String matchId, {required int after, int limit = 500}) async {
    _gate();
    feedCalls++;
    final events = stored(matchId).where((s) => s.serverSeq > after).toList();
    final page = events.take(limit).toList();
    return FeedPage(
      events: page,
      lastServerSeq: page.isEmpty ? after : page.last.serverSeq,
      hasMore: events.length > page.length,
    );
  }
}
