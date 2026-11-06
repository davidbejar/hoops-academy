import 'match_event.dart';

/// Sync state of an event recorded on this device.
enum EventStatus {
  pending('PENDING'),
  sent('SENT'),
  accepted('ACCEPTED'),
  duplicate('DUPLICATE'),
  rejected('REJECTED');

  const EventStatus(this.wire);
  final String wire;

  static EventStatus fromWire(String w) =>
      values.firstWhere((s) => s.wire == w);

  /// Not yet answered by the server.
  bool get unsynced => this == pending || this == sent;

  /// Stored on the server (counts in its projection).
  bool get onServer => this == accepted || this == duplicate;
}

/// An event in this device's queue (table `pending_events`).
class PendingEvent {
  const PendingEvent({
    required this.event,
    required this.matchId,
    required this.tenantId,
    required this.personId,
    required this.status,
    this.rejectReason,
    this.serverSeq,
  });

  final MatchEvent event;
  final String matchId;
  final String tenantId;

  /// Who recorded it (only that person's session sends it).
  final String personId;
  final EventStatus status;

  /// Contract `MatchEventRejectionReason` when REJECTED.
  final String? rejectReason;
  final int? serverSeq;
}

/// Per-event answer of `events:batch`.
class EventResult {
  const EventResult._(this.eventId, this.status, this.serverSeq, this.reason);

  const EventResult.accepted(String eventId, int serverSeq)
    : this._(eventId, EventStatus.accepted, serverSeq, null);
  const EventResult.duplicate(String eventId, int serverSeq)
    : this._(eventId, EventStatus.duplicate, serverSeq, null);
  const EventResult.rejected(String eventId, String reason)
    : this._(eventId, EventStatus.rejected, null, reason);

  final String eventId;
  final EventStatus status;
  final int? serverSeq;
  final String? reason;
}

/// An event as the server stored it (feed `StoredMatchEvent`).
class StoredEvent {
  const StoredEvent({
    required this.event,
    required this.serverSeq,
    this.recordedByPersonId,
    this.recordedByName,
    this.voidedByEventId,
  });

  final MatchEvent event;
  final int serverSeq;
  final String? recordedByPersonId;
  final String? recordedByName;
  final String? voidedByEventId;

  StoredEvent copyWith({String? voidedByEventId}) => StoredEvent(
    event: event,
    serverSeq: serverSeq,
    recordedByPersonId: recordedByPersonId,
    recordedByName: recordedByName,
    voidedByEventId: voidedByEventId ?? this.voidedByEventId,
  );
}

/// One cached match-roster line (table `roster_cache`).
class CachedRosterEntry {
  const CachedRosterEntry({
    required this.playerId,
    required this.displayName,
    this.jerseyNumber,
    required this.isStarter,
  });
  final String playerId;
  final String displayName;
  final String? jerseyNumber;
  final bool isStarter;
}
