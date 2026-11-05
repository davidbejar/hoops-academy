// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_start_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PeriodStartEvent extends PeriodStartEvent {
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

  factory _$PeriodStartEvent(
          [void Function(PeriodStartEventBuilder)? updates]) =>
      (PeriodStartEventBuilder()..update(updates))._build();

  _$PeriodStartEvent._(
      {required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient})
      : super._();
  @override
  PeriodStartEvent rebuild(void Function(PeriodStartEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PeriodStartEventBuilder toBuilder() =>
      PeriodStartEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PeriodStartEvent &&
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
    return (newBuiltValueToStringHelper(r'PeriodStartEvent')
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

class PeriodStartEventBuilder
    implements Builder<PeriodStartEvent, PeriodStartEventBuilder> {
  _$PeriodStartEvent? _$v;

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

  PeriodStartEventBuilder() {
    PeriodStartEvent._defaults(this);
  }

  PeriodStartEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(PeriodStartEvent other) {
    _$v = other as _$PeriodStartEvent;
  }

  @override
  void update(void Function(PeriodStartEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PeriodStartEvent build() => _build();

  _$PeriodStartEvent _build() {
    final _$result = _$v ??
        _$PeriodStartEvent._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PeriodStartEvent', 'id'),
          deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId, r'PeriodStartEvent', 'deviceId'),
          clientSeq: BuiltValueNullFieldError.checkNotNull(
              clientSeq, r'PeriodStartEvent', 'clientSeq'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'PeriodStartEvent', 'type'),
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'PeriodStartEvent', 'period'),
          clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
              clockSecondsRemaining,
              r'PeriodStartEvent',
              'clockSecondsRemaining'),
          recordedAtClient: BuiltValueNullFieldError.checkNotNull(
              recordedAtClient, r'PeriodStartEvent', 'recordedAtClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
