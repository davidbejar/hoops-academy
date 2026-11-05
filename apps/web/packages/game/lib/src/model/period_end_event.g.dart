// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_end_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PeriodEndEvent extends PeriodEndEvent {
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

  factory _$PeriodEndEvent([void Function(PeriodEndEventBuilder)? updates]) =>
      (PeriodEndEventBuilder()..update(updates))._build();

  _$PeriodEndEvent._(
      {required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient})
      : super._();
  @override
  PeriodEndEvent rebuild(void Function(PeriodEndEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PeriodEndEventBuilder toBuilder() => PeriodEndEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PeriodEndEvent &&
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
    return (newBuiltValueToStringHelper(r'PeriodEndEvent')
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

class PeriodEndEventBuilder
    implements Builder<PeriodEndEvent, PeriodEndEventBuilder> {
  _$PeriodEndEvent? _$v;

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

  PeriodEndEventBuilder() {
    PeriodEndEvent._defaults(this);
  }

  PeriodEndEventBuilder get _$this {
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
  void replace(PeriodEndEvent other) {
    _$v = other as _$PeriodEndEvent;
  }

  @override
  void update(void Function(PeriodEndEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PeriodEndEvent build() => _build();

  _$PeriodEndEvent _build() {
    final _$result = _$v ??
        _$PeriodEndEvent._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PeriodEndEvent', 'id'),
          deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId, r'PeriodEndEvent', 'deviceId'),
          clientSeq: BuiltValueNullFieldError.checkNotNull(
              clientSeq, r'PeriodEndEvent', 'clientSeq'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'PeriodEndEvent', 'type'),
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'PeriodEndEvent', 'period'),
          clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
              clockSecondsRemaining,
              r'PeriodEndEvent',
              'clockSecondsRemaining'),
          recordedAtClient: BuiltValueNullFieldError.checkNotNull(
              recordedAtClient, r'PeriodEndEvent', 'recordedAtClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
