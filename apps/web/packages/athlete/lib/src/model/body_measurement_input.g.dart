// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BodyMeasurementInput extends BodyMeasurementInput {
  @override
  final String playerId;
  @override
  final Date measuredOn;
  @override
  final double? heightCm;
  @override
  final double? weightKg;

  factory _$BodyMeasurementInput(
          [void Function(BodyMeasurementInputBuilder)? updates]) =>
      (BodyMeasurementInputBuilder()..update(updates))._build();

  _$BodyMeasurementInput._(
      {required this.playerId,
      required this.measuredOn,
      this.heightCm,
      this.weightKg})
      : super._();
  @override
  BodyMeasurementInput rebuild(
          void Function(BodyMeasurementInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BodyMeasurementInputBuilder toBuilder() =>
      BodyMeasurementInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BodyMeasurementInput &&
        playerId == other.playerId &&
        measuredOn == other.measuredOn &&
        heightCm == other.heightCm &&
        weightKg == other.weightKg;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, heightCm.hashCode);
    _$hash = $jc(_$hash, weightKg.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BodyMeasurementInput')
          ..add('playerId', playerId)
          ..add('measuredOn', measuredOn)
          ..add('heightCm', heightCm)
          ..add('weightKg', weightKg))
        .toString();
  }
}

class BodyMeasurementInputBuilder
    implements Builder<BodyMeasurementInput, BodyMeasurementInputBuilder> {
  _$BodyMeasurementInput? _$v;

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

  BodyMeasurementInputBuilder() {
    BodyMeasurementInput._defaults(this);
  }

  BodyMeasurementInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _measuredOn = $v.measuredOn;
      _heightCm = $v.heightCm;
      _weightKg = $v.weightKg;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BodyMeasurementInput other) {
    _$v = other as _$BodyMeasurementInput;
  }

  @override
  void update(void Function(BodyMeasurementInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BodyMeasurementInput build() => _build();

  _$BodyMeasurementInput _build() {
    final _$result = _$v ??
        _$BodyMeasurementInput._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'BodyMeasurementInput', 'playerId'),
          measuredOn: BuiltValueNullFieldError.checkNotNull(
              measuredOn, r'BodyMeasurementInput', 'measuredOn'),
          heightCm: heightCm,
          weightKg: weightKg,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
