// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NoteEvent extends NoteEvent {
  @override
  final NotePayload payload;
  @override
  final String? playerId;
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

  factory _$NoteEvent([void Function(NoteEventBuilder)? updates]) =>
      (NoteEventBuilder()..update(updates))._build();

  _$NoteEvent._(
      {required this.payload,
      this.playerId,
      required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient})
      : super._();
  @override
  NoteEvent rebuild(void Function(NoteEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NoteEventBuilder toBuilder() => NoteEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NoteEvent &&
        payload == other.payload &&
        playerId == other.playerId &&
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
    _$hash = $jc(_$hash, playerId.hashCode);
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
    return (newBuiltValueToStringHelper(r'NoteEvent')
          ..add('payload', payload)
          ..add('playerId', playerId)
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

class NoteEventBuilder
    implements Builder<NoteEvent, NoteEventBuilder>, MatchEventBaseBuilder {
  _$NoteEvent? _$v;

  NotePayloadBuilder? _payload;
  NotePayloadBuilder get payload => _$this._payload ??= NotePayloadBuilder();
  set payload(covariant NotePayloadBuilder? payload) =>
      _$this._payload = payload;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

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

  NoteEventBuilder() {
    NoteEvent._defaults(this);
  }

  NoteEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _payload = $v.payload.toBuilder();
      _playerId = $v.playerId;
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
  void replace(covariant NoteEvent other) {
    _$v = other as _$NoteEvent;
  }

  @override
  void update(void Function(NoteEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NoteEvent build() => _build();

  _$NoteEvent _build() {
    _$NoteEvent _$result;
    try {
      _$result = _$v ??
          _$NoteEvent._(
            payload: payload.build(),
            playerId: playerId,
            id: BuiltValueNullFieldError.checkNotNull(id, r'NoteEvent', 'id'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'NoteEvent', 'deviceId'),
            clientSeq: BuiltValueNullFieldError.checkNotNull(
                clientSeq, r'NoteEvent', 'clientSeq'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'NoteEvent', 'type'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'NoteEvent', 'period'),
            clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
                clockSecondsRemaining, r'NoteEvent', 'clockSecondsRemaining'),
            recordedAtClient: BuiltValueNullFieldError.checkNotNull(
                recordedAtClient, r'NoteEvent', 'recordedAtClient'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'NoteEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
