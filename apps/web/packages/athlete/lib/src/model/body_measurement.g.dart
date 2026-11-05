// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BodyMeasurement extends BodyMeasurement {
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String id;
  @override
  final String playerId;
  @override
  final Date measuredOn;
  @override
  final double? heightCm;
  @override
  final double? weightKg;

  factory _$BodyMeasurement([void Function(BodyMeasurementBuilder)? updates]) =>
      (BodyMeasurementBuilder()..update(updates))._build();

  _$BodyMeasurement._(
      {required this.recordedBy,
      required this.recordedAt,
      required this.id,
      required this.playerId,
      required this.measuredOn,
      this.heightCm,
      this.weightKg})
      : super._();
  @override
  BodyMeasurement rebuild(void Function(BodyMeasurementBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BodyMeasurementBuilder toBuilder() => BodyMeasurementBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BodyMeasurement &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        id == other.id &&
        playerId == other.playerId &&
        measuredOn == other.measuredOn &&
        heightCm == other.heightCm &&
        weightKg == other.weightKg;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, heightCm.hashCode);
    _$hash = $jc(_$hash, weightKg.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BodyMeasurement')
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('id', id)
          ..add('playerId', playerId)
          ..add('measuredOn', measuredOn)
          ..add('heightCm', heightCm)
          ..add('weightKg', weightKg))
        .toString();
  }
}

class BodyMeasurementBuilder
    implements Builder<BodyMeasurement, BodyMeasurementBuilder> {
  _$BodyMeasurement? _$v;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(DateTime? recordedAt) => _$this._recordedAt = recordedAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _heightCm;
  double? get heightCm => _$this._heightCm;
  set heightCm(double? heightCm) => _$this._heightCm = heightCm;

  double? _weightKg;
  double? get weightKg => _$this._weightKg;
  set weightKg(double? weightKg) => _$this._weightKg = weightKg;

  BodyMeasurementBuilder() {
    BodyMeasurement._defaults(this);
  }

  BodyMeasurementBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _id = $v.id;
      _playerId = $v.playerId;
      _measuredOn = $v.measuredOn;
      _heightCm = $v.heightCm;
      _weightKg = $v.weightKg;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BodyMeasurement other) {
    _$v = other as _$BodyMeasurement;
  }

  @override
  void update(void Function(BodyMeasurementBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BodyMeasurement build() => _build();

  _$BodyMeasurement _build() {
    _$BodyMeasurement _$result;
    try {
      _$result = _$v ??
          _$BodyMeasurement._(
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'BodyMeasurement', 'recordedAt'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'BodyMeasurement', 'id'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'BodyMeasurement', 'playerId'),
            measuredOn: BuiltValueNullFieldError.checkNotNull(
                measuredOn, r'BodyMeasurement', 'measuredOn'),
            heightCm: heightCm,
            weightKg: weightKg,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BodyMeasurement', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
