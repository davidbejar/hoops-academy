// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foul_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FoulEvent extends FoulEvent {
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
  @override
  final FoulPayload payload;

  factory _$FoulEvent([void Function(FoulEventBuilder)? updates]) =>
      (FoulEventBuilder()..update(updates))._build();

  _$FoulEvent._(
      {required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient,
      required this.playerId,
      required this.payload})
      : super._();
  @override
  FoulEvent rebuild(void Function(FoulEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FoulEventBuilder toBuilder() => FoulEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FoulEvent &&
        id == other.id &&
        deviceId == other.deviceId &&
        clientSeq == other.clientSeq &&
        type == other.type &&
        period == other.period &&
        clockSecondsRemaining == other.clockSecondsRemaining &&
        recordedAtClient == other.recordedAtClient &&
        playerId == other.playerId &&
        payload == other.payload;
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
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FoulEvent')
          ..add('id', id)
          ..add('deviceId', deviceId)
          ..add('clientSeq', clientSeq)
          ..add('type', type)
          ..add('period', period)
          ..add('clockSecondsRemaining', clockSecondsRemaining)
          ..add('recordedAtClient', recordedAtClient)
          ..add('playerId', playerId)
          ..add('payload', payload))
        .toString();
  }
}

class FoulEventBuilder implements Builder<FoulEvent, FoulEventBuilder> {
  _$FoulEvent? _$v;

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

  FoulPayloadBuilder? _payload;
  FoulPayloadBuilder get payload => _$this._payload ??= FoulPayloadBuilder();
  set payload(FoulPayloadBuilder? payload) => _$this._payload = payload;

  FoulEventBuilder() {
    FoulEvent._defaults(this);
  }

  FoulEventBuilder get _$this {
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
      _payload = $v.payload.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FoulEvent other) {
    _$v = other as _$FoulEvent;
  }

  @override
  void update(void Function(FoulEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FoulEvent build() => _build();

  _$FoulEvent _build() {
    _$FoulEvent _$result;
    try {
      _$result = _$v ??
          _$FoulEvent._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'FoulEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'FoulEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'FoulEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'FoulEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'FoulEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining, r'FoulEvent', 'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'FoulEvent', 'recordedAtClient'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'FoulEvent', 'playerId'),
            payload: payload.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FoulEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
