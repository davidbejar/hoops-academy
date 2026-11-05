// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turnover_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TurnoverEvent extends TurnoverEvent {
  @override
  final String id;
  @override
  final String deviceId;
  @override
  final int clientSeq;
  @override
  final MatchEventType type;
  @override
  final int period;
  @override
  final int clockSecondsRemaining;
  @override
  final DateTime recordedAtClient;
  @override
  final String playerId;

  factory _$TurnoverEvent([void Function(TurnoverEventBuilder)? updates]) =>
      (TurnoverEventBuilder()..update(updates))._build();

  _$TurnoverEvent._(
      {required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient,
      required this.playerId})
      : super._();
  @override
  TurnoverEvent rebuild(void Function(TurnoverEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TurnoverEventBuilder toBuilder() => TurnoverEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TurnoverEvent &&
        id == other.id &&
        deviceId == other.deviceId &&
        clientSeq == other.clientSeq &&
        type == other.type &&
        period == other.period &&
        clockSecondsRemaining == other.clockSecondsRemaining &&
        recordedAtClient == other.recordedAtClient &&
        playerId == other.playerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jc(_$hash, clientSeq.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, clockSecondsRemaining.hashCode);
    _$hash = $jc(_$hash, recordedAtClient.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TurnoverEvent')
          ..add('id', id)
          ..add('deviceId', deviceId)
          ..add('clientSeq', clientSeq)
          ..add('type', type)
          ..add('period', period)
          ..add('clockSecondsRemaining', clockSecondsRemaining)
          ..add('recordedAtClient', recordedAtClient)
          ..add('playerId', playerId))
        .toString();
  }
}

class TurnoverEventBuilder
    implements Builder<TurnoverEvent, TurnoverEventBuilder> {
  _$TurnoverEvent? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _deviceId;
  String? get deviceId => _$this._deviceId;
  set deviceId(String? deviceId) => _$this._deviceId = deviceId;

  int? _clientSeq;
  int? get clientSeq => _$this._clientSeq;
  set clientSeq(int? clientSeq) => _$this._clientSeq = clientSeq;

  MatchEventType? _type;
  MatchEventType? get type => _$this._type;
  set type(MatchEventType? type) => _$this._type = type;

  int? _period;
  int? get period => _$this._period;
  set period(int? period) => _$this._period = period;

  int? _clockSecondsRemaining;
  int? get clockSecondsRemaining => _$this._clockSecondsRemaining;
  set clockSecondsRemaining(int? clockSecondsRemaining) =>
      _$this._clockSecondsRemaining = clockSecondsRemaining;

  DateTime? _recordedAtClient;
  DateTime? get recordedAtClient => _$this._recordedAtClient;
  set recordedAtClient(DateTime? recordedAtClient) =>
      _$this._recordedAtClient = recordedAtClient;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  TurnoverEventBuilder() {
    TurnoverEvent._defaults(this);
  }

  TurnoverEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _deviceId = $v.deviceId;
      _clientSeq = $v.clientSeq;
      _type = $v.type;
      _period = $v.period;
      _clockSecondsRemaining = $v.clockSecondsRemaining;
      _recordedAtClient = $v.recordedAtClient;
      _playerId = $v.playerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TurnoverEvent other) {
    _$v = other as _$TurnoverEvent;
  }

  @override
  void update(void Function(TurnoverEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TurnoverEvent build() => _build();

  _$TurnoverEvent _build() {
    final _$result = _$v ??
        _$TurnoverEvent._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'TurnoverEvent', 'id'),
          deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId, r'TurnoverEvent', 'deviceId'),
          clientSeq: BuiltValueNullFieldError.checkNotNull(
              clientSeq, r'TurnoverEvent', 'clientSeq'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'TurnoverEvent', 'type'),
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'TurnoverEvent', 'period'),
          clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
              clockSecondsRemaining, r'TurnoverEvent', 'clockSecondsRemaining'),
          recordedAtClient: BuiltValueNullFieldError.checkNotNull(
              recordedAtClient, r'TurnoverEvent', 'recordedAtClient'),
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'TurnoverEvent', 'playerId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
