import '../match_event.dart';
import '../pending_event.dart';

/// The event set the local projection replays: everything pulled from the
/// server plus this device's events the server has or may still accept.
/// REJECTED events are excluded (the server never stored them); an id
/// present in both sources counts once, with the server's sequence number.
List<RecordedEvent> mergeEvents(List<StoredEvent> synced, List<PendingEvent> own) {
  final ids = <String>{};
  return [
    for (final s in synced)
      if (ids.add(s.event.id)) RecordedEvent(s.event, serverSeq: s.serverSeq),
    for (final p in own)
      if (p.status != EventStatus.rejected && ids.add(p.event.id))
        RecordedEvent(p.event, serverSeq: p.serverSeq),
  ];
}
