// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shot_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShotEvent extends ShotEvent {
  @override
  final ShotPayload payload;
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

  factory _$ShotEvent([void Function(ShotEventBuilder)? updates]) =>
      (ShotEventBuilder()..update(updates))._build();

  _$ShotEvent._(
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
  ShotEvent rebuild(void Function(ShotEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShotEventBuilder toBuilder() => ShotEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShotEvent &&
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
    return (newBuiltValueToStringHelper(r'ShotEvent')
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

class ShotEventBuilder
    implements
        Builder<ShotEvent, ShotEventBuilder>,
        MatchEventBaseBuilder,
        PlayerAttributionBuilder {
  _$ShotEvent? _$v;

  ShotPayloadBuilder? _payload;
  ShotPayloadBuilder get payload => _$this._payload ??= ShotPayloadBuilder();
  set payload(covariant ShotPayloadBuilder? payload) =>
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

  ShotEventBuilder() {
    ShotEvent._defaults(this);
  }

  ShotEventBuilder get _$this {
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
  void replace(covariant ShotEvent other) {
    _$v = other as _$ShotEvent;
  }

  @override
  void update(void Function(ShotEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShotEvent build() => _build();

  _$ShotEvent _build() {
    _$ShotEvent _$result;
    try {
      _$result = _$v ??
          _$ShotEvent._(
            payload: payload.build(),
            id: BuiltValueNullFieldError.checkNotNull(id, r'ShotEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'ShotEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'ShotEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'ShotEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'ShotEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining, r'ShotEvent', 'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'ShotEvent', 'recordedAtClient'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'ShotEvent', 'playerId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ShotEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
