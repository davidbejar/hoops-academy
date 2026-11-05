// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeout_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TimeoutEvent extends TimeoutEvent {
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
  final TimeoutPayload payload;

  factory _$TimeoutEvent([void Function(TimeoutEventBuilder)? updates]) =>
      (TimeoutEventBuilder()..update(updates))._build();

  _$TimeoutEvent._(
      {required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient,
      required this.payload})
      : super._();
  @override
  TimeoutEvent rebuild(void Function(TimeoutEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TimeoutEventBuilder toBuilder() => TimeoutEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TimeoutEvent &&
        id == other.id &&
        deviceId == other.deviceId &&
        clientSeq == other.clientSeq &&
        type == other.type &&
        period == other.period &&
        clockSecondsRemaining == other.clockSecondsRemaining &&
        recordedAtClient == other.recordedAtClient &&
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
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TimeoutEvent')
          ..add('id', id)
          ..add('deviceId', deviceId)
          ..add('clientSeq', clientSeq)
          ..add('type', type)
          ..add('period', period)
          ..add('clockSecondsRemaining', clockSecondsRemaining)
          ..add('recordedAtClient', recordedAtClient)
          ..add('payload', payload))
        .toString();
  }
}

class TimeoutEventBuilder
    implements Builder<TimeoutEvent, TimeoutEventBuilder> {
  _$TimeoutEvent? _$v;

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

  TimeoutPayloadBuilder? _payload;
  TimeoutPayloadBuilder get payload =>
      _$this._payload ??= TimeoutPayloadBuilder();
  set payload(TimeoutPayloadBuilder? payload) => _$this._payload = payload;

  TimeoutEventBuilder() {
    TimeoutEvent._defaults(this);
  }

  TimeoutEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _deviceId = $v.deviceId;
      _clientSeq = $v.clientSeq;
      _type = $v.type;
      _period = $v.period;
      _clockSecondsRemaining = $v.clockSecondsRemaining;
      _recordedAtClient = $v.recordedAtClient;
      _payload = $v.payload.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TimeoutEvent other) {
    _$v = other as _$TimeoutEvent;
  }

  @override
  void update(void Function(TimeoutEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TimeoutEvent build() => _build();

  _$TimeoutEvent _build() {
    _$TimeoutEvent _$result;
    try {
      _$result = _$v ??
          _$TimeoutEvent._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'TimeoutEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'TimeoutEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'TimeoutEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'TimeoutEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'TimeoutEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining,
                r'TimeoutEvent',
                'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'TimeoutEvent', 'recordedAtClient'),
            payload: payload.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TimeoutEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
