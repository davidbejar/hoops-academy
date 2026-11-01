// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BodyMeasurement extends BodyMeasurement {
  @override
  final Date measuredOn;
  @override
  final double? heightCm;
  @override
  final String id;
  @override
  final double? weightKg;
  @override
  final String playerId;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;

  factory _$BodyMeasurement([void Function(BodyMeasurementBuilder)? updates]) =>
      (BodyMeasurementBuilder()..update(updates))._build();

  _$BodyMeasurement._(
      {required this.measuredOn,
      this.heightCm,
      required this.id,
      this.weightKg,
      required this.playerId,
      required this.recordedBy,
      required this.recordedAt})
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
        measuredOn == other.measuredOn &&
        heightCm == other.heightCm &&
        id == other.id &&
        weightKg == other.weightKg &&
        playerId == other.playerId &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, heightCm.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, weightKg.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BodyMeasurement')
          ..add('measuredOn', measuredOn)
          ..add('heightCm', heightCm)
          ..add('id', id)
          ..add('weightKg', weightKg)
          ..add('playerId', playerId)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class BodyMeasurementBuilder
    implements
        Builder<BodyMeasurement, BodyMeasurementBuilder>,
        AuditInfoBuilder {
  _$BodyMeasurement? _$v;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(covariant Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _heightCm;
  double? get heightCm => _$this._heightCm;
  set heightCm(covariant double? heightCm) => _$this._heightCm = heightCm;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  double? _weightKg;
  double? get weightKg => _$this._weightKg;
  set weightKg(covariant double? weightKg) => _$this._weightKg = weightKg;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  BodyMeasurementBuilder() {
    BodyMeasurement._defaults(this);
  }

  BodyMeasurementBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _measuredOn = $v.measuredOn;
      _heightCm = $v.heightCm;
      _id = $v.id;
      _weightKg = $v.weightKg;
      _playerId = $v.playerId;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant BodyMeasurement other) {
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
            measuredOn: BuiltValueNullFieldError.checkNotNull(
                measuredOn, r'BodyMeasurement', 'measuredOn'),
            heightCm: heightCm,
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'BodyMeasurement', 'id'),
            weightKg: weightKg,
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'BodyMeasurement', 'playerId'),
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'BodyMeasurement', 'recordedAt'),
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
