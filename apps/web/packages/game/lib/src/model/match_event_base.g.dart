// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_base.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class MatchEventBaseBuilder {
  void replace(MatchEventBase other);
  void update(void Function(MatchEventBaseBuilder) updates);
  String? get id;
  set id(String? id);

  String? get deviceId;
  set deviceId(String? deviceId);

  int? get clientSeq;
  set clientSeq(int? clientSeq);

  MatchEventType? get type;
  set type(MatchEventType? type);

  int? get period;
  set period(int? period);

  int? get clockSecondsRemaining;
  set clockSecondsRemaining(int? clockSecondsRemaining);

  DateTime? get recordedAtClient;
  set recordedAtClient(DateTime? recordedAtClient);
}

class _$$MatchEventBase extends $MatchEventBase {
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

  factory _$$MatchEventBase([void Function($MatchEventBaseBuilder)? updates]) =>
      ($MatchEventBaseBuilder()..update(updates))._build();

  _$$MatchEventBase._(
      {required this.id,
      required this.deviceId,
      required this.clientSeq,
      required this.type,
      required this.period,
      required this.clockSecondsRemaining,
      required this.recordedAtClient})
      : super._();
  @override
  $MatchEventBase rebuild(void Function($MatchEventBaseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $MatchEventBaseBuilder toBuilder() => $MatchEventBaseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $MatchEventBase &&
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
    return (newBuiltValueToStringHelper(r'$MatchEventBase')
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

class $MatchEventBaseBuilder
    implements
        Builder<$MatchEventBase, $MatchEventBaseBuilder>,
        MatchEventBaseBuilder {
  _$$MatchEventBase? _$v;

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

  $MatchEventBaseBuilder() {
    $MatchEventBase._defaults(this);
  }

  $MatchEventBaseBuilder get _$this {
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
  void replace(covariant $MatchEventBase other) {
    _$v = other as _$$MatchEventBase;
  }

  @override
  void update(void Function($MatchEventBaseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $MatchEventBase build() => _build();

  _$$MatchEventBase _build() {
    final _$result = _$v ??
        _$$MatchEventBase._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'$MatchEventBase', 'id'),
          deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId, r'$MatchEventBase', 'deviceId'),
          clientSeq: BuiltValueNullFieldError.checkNotNull(
              clientSeq, r'$MatchEventBase', 'clientSeq'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'$MatchEventBase', 'type'),
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'$MatchEventBase', 'period'),
          clockSecondsRemaining: BuiltValueNullFieldError.checkNotNull(
              clockSecondsRemaining,
              r'$MatchEventBase',
              'clockSecondsRemaining'),
          recordedAtClient: BuiltValueNullFieldError.checkNotNull(
              recordedAtClient, r'$MatchEventBase', 'recordedAtClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
