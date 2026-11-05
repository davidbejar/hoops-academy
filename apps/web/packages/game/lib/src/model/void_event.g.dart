// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'void_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VoidEvent extends VoidEvent {
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
  final VoidPayload payload;

  factory _$VoidEvent([void Function(VoidEventBuilder)? updates]) =>
      (VoidEventBuilder()..update(updates))._build();

  _$VoidEvent._(
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
  VoidEvent rebuild(void Function(VoidEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VoidEventBuilder toBuilder() => VoidEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VoidEvent &&
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
    return (newBuiltValueToStringHelper(r'VoidEvent')
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

class VoidEventBuilder implements Builder<VoidEvent, VoidEventBuilder> {
  _$VoidEvent? _$v;

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

  VoidPayloadBuilder? _payload;
  VoidPayloadBuilder get payload => _$this._payload ??= VoidPayloadBuilder();
  set payload(VoidPayloadBuilder? payload) => _$this._payload = payload;

  VoidEventBuilder() {
    VoidEvent._defaults(this);
  }

  VoidEventBuilder get _$this {
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
  void replace(VoidEvent other) {
    _$v = other as _$VoidEvent;
  }

  @override
  void update(void Function(VoidEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VoidEvent build() => _build();

  _$VoidEvent _build() {
    _$VoidEvent _$result;
    try {
      _$result = _$v ??
          _$VoidEvent._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'VoidEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'VoidEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'VoidEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'VoidEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'VoidEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining, r'VoidEvent', 'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'VoidEvent', 'recordedAtClient'),
            payload: payload.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'VoidEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
