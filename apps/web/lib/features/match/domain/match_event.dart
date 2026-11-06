/// Match events as facts (mirror of `libs/contracts/events/match-event.schema.json`).
/// Pure Dart: no Flutter, no generated types. JSON = contract JSON.
library;

enum MatchEventType {
  periodStart('PERIOD_START'),
  periodEnd('PERIOD_END'),
  subIn('SUB_IN'),
  subOut('SUB_OUT'),
  shot('SHOT'),
  assist('ASSIST'),
  rebound('REBOUND'),
  turnover('TURNOVER'),
  steal('STEAL'),
  block('BLOCK'),
  foul('FOUL'),
  opponentScore('OPPONENT_SCORE'),
  timeout('TIMEOUT'),
  voidEvent('VOID'),
  note('NOTE');

  const MatchEventType(this.wire);
  final String wire;

  static MatchEventType fromWire(String wire) => values.firstWhere(
    (t) => t.wire == wire,
    orElse: () => throw FormatException('unknown event type $wire'),
  );
}

enum ReboundKind {
  offensive('OFFENSIVE'),
  defensive('DEFENSIVE');

  const ReboundKind(this.wire);
  final String wire;
  static ReboundKind fromWire(String w) =>
      values.firstWhere((v) => v.wire == w);
}

enum FoulKind {
  personal('PERSONAL'),
  technical('TECHNICAL'),
  unsportsmanlike('UNSPORTSMANLIKE');

  const FoulKind(this.wire);
  final String wire;
  static FoulKind fromWire(String w) => values.firstWhere((v) => v.wire == w);
}

enum TimeoutSide {
  own('OWN'),
  opponent('OPPONENT');

  const TimeoutSide(this.wire);
  final String wire;
  static TimeoutSide fromWire(String w) =>
      values.firstWhere((v) => v.wire == w);
}

/// Fields every event carries.
class EventMeta {
  EventMeta({
    required this.id,
    required this.deviceId,
    required this.clientSeq,
    required this.period,
    required this.clockSecondsRemaining,
    required DateTime recordedAtClient,
  }) : recordedAtClient = recordedAtClient.toUtc();

  /// Client-generated UUIDv7, the idempotency key.
  final String id;
  final String deviceId;

  /// Per-device sequence, unique per (match, deviceId).
  final int clientSeq;

  /// 1-based; above the match's period count = overtime.
  final int period;
  final int clockSecondsRemaining;
  final DateTime recordedAtClient;

  Map<String, Object?> _baseJson(MatchEventType type) => {
    'id': id,
    'deviceId': deviceId,
    'clientSeq': clientSeq,
    'type': type.wire,
    'period': period,
    'clockSecondsRemaining': clockSecondsRemaining,
    'recordedAtClient': recordedAtClient.toIso8601String(),
  };

  static EventMeta fromJson(Map<String, Object?> json) => EventMeta(
    id: json['id']! as String,
    deviceId: json['deviceId']! as String,
    clientSeq: (json['clientSeq']! as num).toInt(),
    period: (json['period']! as num).toInt(),
    clockSecondsRemaining: (json['clockSecondsRemaining']! as num).toInt(),
    recordedAtClient: DateTime.parse(json['recordedAtClient']! as String),
  );
}

/// An append-only match event; one class per contract type.
sealed class MatchEvent {
  const MatchEvent(this.meta);

  final EventMeta meta;

  String get id => meta.id;
  MatchEventType get type;

  /// The player the event is attributed to, if any.
  String? get playerId => null;

  Map<String, Object?>? get _payload => null;

  Map<String, Object?> toJson() => {
    ...meta._baseJson(type),
    if (playerId != null) 'playerId': playerId,
    if (_payload != null) 'payload': _payload,
  };

  /// Parses contract JSON (throws [FormatException] / [TypeError] when invalid).
  static MatchEvent fromJson(Map<String, Object?> json) {
    final meta = EventMeta.fromJson(json);
    final player = json['playerId'] as String?;
    final payload =
        (json['payload'] as Map?)?.cast<String, Object?>() ?? const {};
    String p() => player ?? (throw const FormatException('playerId required'));
    int points() => (payload['points']! as num).toInt();
    return switch (MatchEventType.fromWire(json['type']! as String)) {
      MatchEventType.periodStart => PeriodStart(meta),
      MatchEventType.periodEnd => PeriodEnd(meta),
      MatchEventType.subIn => SubIn(meta, playerId: p()),
      MatchEventType.subOut => SubOut(meta, playerId: p()),
      MatchEventType.shot => Shot(
        meta,
        playerId: p(),
        points: points(),
        made: payload['made']! as bool,
      ),
      MatchEventType.assist => Assist(meta, playerId: p()),
      MatchEventType.rebound => Rebound(
        meta,
        playerId: p(),
        kind: ReboundKind.fromWire(payload['kind']! as String),
      ),
      MatchEventType.turnover => Turnover(meta, playerId: p()),
      MatchEventType.steal => Steal(meta, playerId: p()),
      MatchEventType.block => Block(meta, playerId: p()),
      MatchEventType.foul => Foul(
        meta,
        playerId: p(),
        kind: FoulKind.fromWire(payload['kind']! as String),
      ),
      MatchEventType.opponentScore => OpponentScore(meta, points: points()),
      MatchEventType.timeout => Timeout(
        meta,
        side: TimeoutSide.fromWire(payload['side']! as String),
      ),
      MatchEventType.voidEvent => VoidEvent(
        meta,
        target: payload['targetEventId']! as String,
      ),
      MatchEventType.note => Note(
        meta,
        playerId: player,
        text: payload['text']! as String,
      ),
    };
  }
}

/// Player-attributed counting statistic: the only events a linked PARENT may enter.
sealed class PlayerStat extends MatchEvent {
  const PlayerStat(super.meta, {required this.player});
  final String player;

  @override
  String get playerId => player;
}

final class PeriodStart extends MatchEvent {
  const PeriodStart(super.meta);
  @override
  MatchEventType get type => MatchEventType.periodStart;
}

final class PeriodEnd extends MatchEvent {
  const PeriodEnd(super.meta);
  @override
  MatchEventType get type => MatchEventType.periodEnd;
}

final class SubIn extends MatchEvent {
  const SubIn(super.meta, {required String playerId}) : player = playerId;
  final String player;
  @override
  String get playerId => player;
  @override
  MatchEventType get type => MatchEventType.subIn;
}

final class SubOut extends MatchEvent {
  const SubOut(super.meta, {required String playerId}) : player = playerId;
  final String player;
  @override
  String get playerId => player;
  @override
  MatchEventType get type => MatchEventType.subOut;
}

/// [points] 1 = free throw, 2 = field goal, 3 = three-pointer.
final class Shot extends PlayerStat {
  Shot(
    super.meta, {
    required String playerId,
    required this.points,
    required this.made,
  }) : assert(points >= 1 && points <= 3),
       super(player: playerId);
  final int points;
  final bool made;
  @override
  MatchEventType get type => MatchEventType.shot;
  @override
  Map<String, Object?> get _payload => {'points': points, 'made': made};
}

final class Assist extends PlayerStat {
  const Assist(super.meta, {required String playerId})
    : super(player: playerId);
  @override
  MatchEventType get type => MatchEventType.assist;
}

final class Rebound extends PlayerStat {
  const Rebound(super.meta, {required String playerId, required this.kind})
    : super(player: playerId);
  final ReboundKind kind;
  @override
  MatchEventType get type => MatchEventType.rebound;
  @override
  Map<String, Object?> get _payload => {'kind': kind.wire};
}

final class Turnover extends PlayerStat {
  const Turnover(super.meta, {required String playerId})
    : super(player: playerId);
  @override
  MatchEventType get type => MatchEventType.turnover;
}

final class Steal extends PlayerStat {
  const Steal(super.meta, {required String playerId}) : super(player: playerId);
  @override
  MatchEventType get type => MatchEventType.steal;
}

final class Block extends PlayerStat {
  const Block(super.meta, {required String playerId}) : super(player: playerId);
  @override
  MatchEventType get type => MatchEventType.block;
}

final class Foul extends PlayerStat {
  const Foul(super.meta, {required String playerId, required this.kind})
    : super(player: playerId);
  final FoulKind kind;
  @override
  MatchEventType get type => MatchEventType.foul;
  @override
  Map<String, Object?> get _payload => {'kind': kind.wire};
}

final class OpponentScore extends MatchEvent {
  const OpponentScore(super.meta, {required this.points});
  final int points;
  @override
  MatchEventType get type => MatchEventType.opponentScore;
  @override
  Map<String, Object?> get _payload => {'points': points};
}

final class Timeout extends MatchEvent {
  const Timeout(super.meta, {required this.side});
  final TimeoutSide side;
  @override
  MatchEventType get type => MatchEventType.timeout;
  @override
  Map<String, Object?> get _payload => {'side': side.wire};
}

/// Cancels the effect of [target] in every projection.
final class VoidEvent extends MatchEvent {
  const VoidEvent(super.meta, {required this.target});
  final String target;
  @override
  MatchEventType get type => MatchEventType.voidEvent;
  @override
  Map<String, Object?> get _payload => {'targetEventId': target};
}

/// Free text, optionally about a player; no effect on statistics.
final class Note extends MatchEvent {
  const Note(super.meta, {String? playerId, required this.text})
    : _player = playerId;
  final String? _player;
  final String text;
  @override
  String? get playerId => _player;
  @override
  MatchEventType get type => MatchEventType.note;
  @override
  Map<String, Object?> get _payload => {'text': text};
}

/// An event with its server sequence number; null = recorded on this device
/// and not acknowledged yet (replayed after every synced event of the same
/// game instant).
class RecordedEvent {
  const RecordedEvent(this.event, {this.serverSeq});
  final MatchEvent event;
  final int? serverSeq;

  String get id => event.id;
}
