import '../domain/match_event.dart';
import '../domain/pending_event.dart';

/// Answer of `POST /matches/{id}/events:batch`.
class BatchOutcome {
  const BatchOutcome({required this.results, required this.lastServerSeq});
  final List<EventResult> results;
  final int lastServerSeq;
}

/// Page of `GET /matches/{id}/events?after=`.
class FeedPage {
  const FeedPage({required this.events, required this.lastServerSeq, required this.hasMore});
  final List<StoredEvent> events;
  final int lastServerSeq;
  final bool hasMore;
}

/// The event half of game-service. Failures are thrown as `AppError`
/// (network / timeout / unauthorized / ...).
abstract class EventsRemote {
  Future<BatchOutcome> submit(String matchId, List<MatchEvent> events);
  Future<FeedPage> feed(String matchId, {required int after, int limit = 500});
}
