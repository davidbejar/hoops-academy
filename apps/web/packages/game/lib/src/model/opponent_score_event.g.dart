// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opponent_score_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OpponentScoreEvent extends OpponentScoreEvent {
  @override
  final OpponentScorePayload payload;
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

  factory _$OpponentScoreEvent(
          [void Function(OpponentScoreEventBuilder)? updates]) =>
      (OpponentScoreEventBuilder()..update(updates))._build();

  _$OpponentScoreEvent._(
      {required this.payload,
      required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient})
      : super._();
  @override
  OpponentScoreEvent rebuild(
          void Function(OpponentScoreEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OpponentScoreEventBuilder toBuilder() =>
      OpponentScoreEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OpponentScoreEvent &&
        payload == other.payload &&
        id == other.id &&
        deviceId == other.deviceId &&
        clientSeq == other.clientSeq &&
        type == other.type &&
        period == other.period &&
        clockSecondsRemaining == other.clockSecondsRemaining &&
        recordedAtClient == other.recordedAtClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jc(_$hash, clientSeq.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, clockSecondsRemaining.hashCode);
    _$hash = $jc(_$hash, recordedAtClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OpponentScoreEvent')
          ..add('payload', payload)
          ..add('id', id)
          ..add('deviceId', deviceId)
          ..add('clientSeq', clientSeq)
          ..add('type', type)
          ..add('period', period)
          ..add('clockSecondsRemaining', clockSecondsRemaining)
          ..add('recordedAtClient', recordedAtClient))
        .toString();
  }
}

class OpponentScoreEventBuilder
    implements
        Builder<OpponentScoreEvent, OpponentScoreEventBuilder>,
        MatchEventBaseBuilder {
  _$OpponentScoreEvent? _$v;

  OpponentScorePayloadBuilder? _payload;
  OpponentScorePayloadBuilder get payload =>
      _$this._payload ??= OpponentScorePayloadBuilder();
  set payload(covariant OpponentScorePayloadBuilder? payload) =>
      _$this._payload = payload;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  String? _deviceId;
  String? get deviceId => _$this._deviceId;
  set deviceId(covariant String? deviceId) => _$this._deviceId = deviceId;

  int? _clientSeq;
  int? get clientSeq => _$this._clientSeq;
  set clientSeq(covariant int? clientSeq) => _$this._clientSeq = clientSeq;

  MatchEventType? _type;
  MatchEventType? get type => _$this._type;
  set type(covariant MatchEventType? type) => _$this._type = type;

  int? _period;
  int? get period => _$this._period;
  set period(covariant int? period) => _$this._period = period;

  int? _clockSecondsRemaining;
  int? get clockSecondsRemaining => _$this._clockSecondsRemaining;
  set clockSecondsRemaining(covariant int? clockSecondsRemaining) =>
      _$this._clockSecondsRemaining = clockSecondsRemaining;

  DateTime? _recordedAtClient;
  DateTime? get recordedAtClient => _$this._recordedAtClient;
  set recordedAtClient(covariant DateTime? recordedAtClient) =>
      _$this._recordedAtClient = recordedAtClient;

  OpponentScoreEventBuilder() {
    OpponentScoreEvent._defaults(this);
  }

  OpponentScoreEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _payload = $v.payload.toBuilder();
      _id = $v.id;
      _deviceId = $v.deviceId;
      _clientSeq = $v.clientSeq;
      _type = $v.type;
      _period = $v.period;
      _clockSecondsRemaining = $v.clockSecondsRemaining;
      _recordedAtClient = $v.recordedAtClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant OpponentScoreEvent other) {
    _$v = other as _$OpponentScoreEvent;
  }

  @override
  void update(void Function(OpponentScoreEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OpponentScoreEvent build() => _build();

  _$OpponentScoreEvent _build() {
    _$OpponentScoreEvent _$result;
    try {
      _$result = _$v ??
          _$OpponentScoreEvent._(
            payload: payload.build(),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'OpponentScoreEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'OpponentScoreEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'OpponentScoreEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'OpponentScoreEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'OpponentScoreEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining,
                r'OpponentScoreEvent',
                'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'OpponentScoreEvent', 'recordedAtClient'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'OpponentScoreEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
