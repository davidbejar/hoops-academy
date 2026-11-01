// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebound_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReboundEvent extends ReboundEvent {
  @override
  final ReboundPayload payload;
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

  factory _$ReboundEvent([void Function(ReboundEventBuilder)? updates]) =>
      (ReboundEventBuilder()..update(updates))._build();

  _$ReboundEvent._(
      {required this.payload,
      required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient,
      required this.playerId})
      : super._();
  @override
  ReboundEvent rebuild(void Function(ReboundEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReboundEventBuilder toBuilder() => ReboundEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReboundEvent &&
        payload == other.payload &&
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
    _$hash = $jc(_$hash, payload.hashCode);
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
    return (newBuiltValueToStringHelper(r'ReboundEvent')
          ..add('payload', payload)
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

class ReboundEventBuilder
    implements
        Builder<ReboundEvent, ReboundEventBuilder>,
        MatchEventBaseBuilder,
        PlayerAttributionBuilder {
  _$ReboundEvent? _$v;

  ReboundPayloadBuilder? _payload;
  ReboundPayloadBuilder get payload =>
      _$this._payload ??= ReboundPayloadBuilder();
  set payload(covariant ReboundPayloadBuilder? payload) =>
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

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  ReboundEventBuilder() {
    ReboundEvent._defaults(this);
  }

  ReboundEventBuilder get _$this {
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
      _playerId = $v.playerId;
      _$v = null;
    }
    return this;
  }

  @override
// ignore: override_on_non_overriding_method
  void replace(covariant ReboundEvent other) {
    _$v = other as _$ReboundEvent;
  }

  @override
  void update(void Function(ReboundEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReboundEvent build() => _build();

  _$ReboundEvent _build() {
    _$ReboundEvent _$result;
    try {
      _$result = _$v ??
          _$ReboundEvent._(
            payload: payload.build(),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ReboundEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'ReboundEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'ReboundEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'ReboundEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'ReboundEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining,
                r'ReboundEvent',
                'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'ReboundEvent', 'recordedAtClient'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'ReboundEvent', 'playerId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ReboundEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
